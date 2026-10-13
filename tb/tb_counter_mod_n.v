`timescale 1ns / 1ps
//=============================================================================
// tb_counter_mod_n — banc d'essai du compteur modulo N paramétré.
//
// Trois instances sont testées EN PARALLÈLE sur la même horloge, car le point
// délicat du module est justement le paramétrage :
//
//   - MOD_A = 5  : N n'est PAS une puissance de deux -> 3 bits, et les états
//                  5, 6, 7 sont codés mais illégaux. C'est le cas intéressant.
//   - MOD_B = 3  : le plus petit modulo non trivial -> 2 bits, un seul état
//                  illégal (3).
//   - MOD_C = 8  : puissance de deux -> 3 bits, aucun état perdu ; on doit
//                  retrouver le comportement du compteur binaire ordinaire.
//
// Vérifié à chaque front, pour chaque instance :
//   - la valeur du compteur, comparée à un modèle de référence entier
//     (compteur logiciel + « % N » explicite) ;
//   - la sortie `fin_cycle`, qui doit valoir 1 exactement pendant l'état N-1
//     et 0 partout ailleurs ;
//   - le nombre d'impulsions de fin_cycle : sur K fronts comptés, il doit y en
//     avoir exactement floor(K / N) — c'est la vérification quantitative que
//     le compteur divise bien la fréquence par N.
//
// Enfin, on force l'instance modulo 5 dans un ÉTAT ILLÉGAL (7) par une
// affectation hiérarchique, pour vérifier la propriété d'AUTO-CORRECTION
// annoncée dans l'en-tête du module : le test `>= N-1` doit la ramener à 0 au
// front suivant, au lieu de la laisser tourner dans les états interdits.
//=============================================================================
module tb_counter_mod_n;

    localparam MOD_A = 5;
    localparam MOD_B = 3;
    localparam MOD_C = 8;

    reg  clk = 1'b0;
    reg  rst, en;

    wire [2:0] q_a;    wire fin_a;
    wire [1:0] q_b;    wire fin_b;
    wire [2:0] q_c;    wire fin_c;

    integer erreurs = 0;
    integer cycles  = 0;
    integer i;
    integer ref_a, ref_b, ref_c;
    integer impulsions_a, comptes_a;

    counter_mod_n #(.N(MOD_A)) dut_a (.clk(clk), .rst(rst), .en(en), .q(q_a), .fin_cycle(fin_a));
    counter_mod_n #(.N(MOD_B)) dut_b (.clk(clk), .rst(rst), .en(en), .q(q_b), .fin_cycle(fin_b));
    counter_mod_n #(.N(MOD_C)) dut_c (.clk(clk), .rst(rst), .en(en), .q(q_c), .fin_cycle(fin_c));

    always #5 clk = ~clk;

    task verifier_instance;
        input [8*4:1] nom;
        input [2:0]   valeur;
        input         fin;
        input integer reference;
        input integer modulo;
        begin
            if (valeur !== reference[2:0]) begin
                erreurs = erreurs + 1;
                $display("ECHEC %0s cycle %0d (t=%0t) : q=%0d (attendu %0d)",
                         nom, cycles, $time, valeur, reference);
            end
            if (fin !== (reference == modulo - 1)) begin
                erreurs = erreurs + 1;
                $display("ECHEC %0s cycle %0d : fin_cycle=%b avec q=%0d (modulo %0d)",
                         nom, cycles, fin, reference, modulo);
            end
        end
    endtask

    task pas;
        input in_rst, in_en;
        begin
            rst = in_rst;
            en  = in_en;
            @(posedge clk);
            #1;
            cycles = cycles + 1;

            // --- references : compteurs logiciels avec modulo EXPLICITE ------
            if (in_rst) begin
                ref_a = 0; ref_b = 0; ref_c = 0;
            end
            else if (in_en) begin
                ref_a = (ref_a + 1) % MOD_A;
                ref_b = (ref_b + 1) % MOD_B;
                ref_c = (ref_c + 1) % MOD_C;
                comptes_a = comptes_a + 1;
            end

            verifier_instance("mod5", q_a,        fin_a, ref_a, MOD_A);
            verifier_instance("mod3", {1'b0,q_b}, fin_b, ref_b, MOD_B);
            verifier_instance("mod8", q_c,        fin_c, ref_c, MOD_C);

            if (fin_a) impulsions_a = impulsions_a + 1;
        end
    endtask

    initial begin
        rst = 1'b1;
        en  = 1'b0;
        ref_a = 0; ref_b = 0; ref_c = 0;
        impulsions_a = 0; comptes_a = 0;

        // --- reset prioritaire sur le comptage ---------------------------------
        pas(1'b1, 1'b1);
        pas(1'b1, 1'b1);

        // --- GEL : 4 fronts sans comptage --------------------------------------
        for (i = 0; i < 4; i = i + 1)
            pas(1'b0, 1'b0);
        if (q_a !== 3'd0 || q_b !== 2'd0 || q_c !== 3'd0) begin
            erreurs = erreurs + 1;
            $display("ECHEC : un compteur a avance avec en=0");
        end

        // --- 60 fronts comptes : 12 cycles complets de mod5, 20 de mod3, ------
        // --- 7 cycles et demi de mod8. Rebouclages traverses de nombreuses ----
        // --- fois, sur les trois modulos a la fois. ---------------------------
        impulsions_a = 0; comptes_a = 0;
        for (i = 0; i < 60; i = i + 1)
            pas(1'b0, 1'b1);

        // Verification QUANTITATIVE de la division de frequence par 5.
        if (impulsions_a != (comptes_a / MOD_A)) begin
            erreurs = erreurs + 1;
            $display("ECHEC : %0d impulsions de fin_cycle sur %0d fronts comptes (attendu %0d)",
                     impulsions_a, comptes_a, comptes_a / MOD_A);
        end

        // --- comptage entrecoupe de gels : le gel ne doit RIEN changer d'autre -
        for (i = 0; i < 40; i = i + 1)
            pas(1'b0, ((i % 3) != 0));

        // --- AUTO-CORRECTION depuis un etat ILLEGAL ---------------------------
        // On injecte de force la valeur 7 dans le compteur modulo 5 (etat
        // codable mais hors cycle), comme le ferait un parasite.
        pas(1'b1, 1'b0);            // on repart d'un etat propre
        dut_a.q = 3'd7;
        #1;
        if (dut_a.fin_cycle !== 1'b0) begin
            erreurs = erreurs + 1;
            $display("ECHEC : fin_cycle actif dans l'etat illegal 7");
        end
        en  = 1'b1;
        rst = 1'b0;
        @(posedge clk);
        #1;
        cycles = cycles + 1;
        if (q_a !== 3'd0) begin
            erreurs = erreurs + 1;
            $display("ECHEC auto-correction : depuis l'etat illegal 7, q=%0d (attendu 0)", q_a);
        end
        // Les references sont resynchronisees avant de reprendre les tests.
        ref_a = 0;
        ref_b = (ref_b + 1) % MOD_B;
        ref_c = (ref_c + 1) % MOD_C;

        // --- reprise normale apres auto-correction -----------------------------
        for (i = 0; i < 12; i = i + 1)
            pas(1'b0, 1'b1);

        // --- reset final --------------------------------------------------------
        pas(1'b1, 1'b1);
        if (q_a !== 3'd0 || q_b !== 2'd0 || q_c !== 3'd0) begin
            erreurs = erreurs + 1;
            $display("ECHEC : reset final inoperant");
        end

        if (erreurs == 0)
            $display("PASS tb_counter_mod_n (%0d cycles, modulos 5/3/8 : comptage, rebouclage, fin_cycle, gel, auto-correction)", cycles);
        else
            $display("ECHEC tb_counter_mod_n : %0d erreur(s)", erreurs);
        $finish;
    end

endmodule
