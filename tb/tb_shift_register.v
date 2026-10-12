`timescale 1ns / 1ps
//=============================================================================
// tb_shift_register — banc d'essai du registre à décalage universel (N = 8).
//
// Les valeurs attendues des scénarios principaux sont CALCULÉES À LA MAIN et
// écrites en dur dans le banc, plutôt que recopiées de la formule du module :
// vérifier {q[N-2:0], s_in} contre {q[N-2:0], s_in} ne prouverait rien.
//
// Exemple, décalage à GAUCHE de 1011_0010 avec s_in = 1 :
//        1011_0010  ->  0110_0101      (le MSB 1 est perdu, le 1 entre en LSB)
// Décalage à DROITE de 1001_0101 avec s_in = 0 :
//        1001_0101  ->  0100_1010      (le LSB 1 est perdu, le 0 entre en MSB)
//
// Sont couverts : reset, chargement parallèle, priorité du chargement sur le
// décalage, gel (en = 0), décalage gauche et droite, entrée série, sortie
// parallèle, sortie série, et la conversion SÉRIE -> PARALLÈLE complète
// (8 bits entrés un par un doivent reconstituer l'octet de départ).
//=============================================================================
module tb_shift_register;

    localparam N = 8;

    reg          clk = 1'b0;
    reg          rst, en, load, dir, s_in;
    reg  [N-1:0] d;
    wire [N-1:0] q;
    wire         s_out;

    integer      erreurs = 0;
    integer      cycles  = 0;
    integer      i;
    reg  [N-1:0] motif;

    localparam GAUCHE = 1'b1;
    localparam DROITE = 1'b0;

    shift_register #(.N(N)) dut (
        .clk(clk), .rst(rst), .en(en), .load(load), .dir(dir),
        .s_in(s_in), .d(d), .q(q), .s_out(s_out)
    );

    always #5 clk = ~clk;

    // Applique les commandes, franchit un front, compare q a une valeur
    // attendue CALCULEE A LA MAIN.
    task pas;
        input         in_rst, in_en, in_load, in_dir, in_s_in;
        input [N-1:0] in_d;
        input [N-1:0] attendu;
        begin
            rst = in_rst; en = in_en; load = in_load;
            dir = in_dir; s_in = in_s_in; d = in_d;
            @(posedge clk);
            #1;
            cycles = cycles + 1;
            if (q !== attendu) begin
                erreurs = erreurs + 1;
                $display("ECHEC cycle %0d (t=%0t) : rst=%b en=%b load=%b dir=%b s_in=%b -> q=%b (attendu %b)",
                         cycles, $time, in_rst, in_en, in_load, in_dir, in_s_in, q, attendu);
            end
        end
    endtask

    task verifier_s_out;
        input attendu;
        begin
            if (s_out !== attendu) begin
                erreurs = erreurs + 1;
                $display("ECHEC s_out (t=%0t) : q=%b dir=%b -> s_out=%b (attendu %b)",
                         $time, q, dir, s_out, attendu);
            end
        end
    endtask

    initial begin
        rst = 1'b1; en = 1'b0; load = 1'b0; dir = GAUCHE; s_in = 1'b0;
        d   = {N{1'b0}};

        // --- reset ------------------------------------------------------------
        pas(1'b1, 1'b1, 1'b1, GAUCHE, 1'b1, 8'hFF, 8'b0000_0000);  // reset prioritaire sur tout

        // --- chargement parallele --------------------------------------------
        pas(1'b0, 1'b0, 1'b1, GAUCHE, 1'b0, 8'b1011_0010, 8'b1011_0010);
        verifier_s_out(1'b1);       // dir=gauche -> s_out = q[7] = 1

        // --- decalages a GAUCHE (valeurs calculees a la main) -----------------
        pas(1'b0, 1'b1, 1'b0, GAUCHE, 1'b1, 8'h00, 8'b0110_0101);
        verifier_s_out(1'b0);       // q[7] vaut maintenant 0
        pas(1'b0, 1'b1, 1'b0, GAUCHE, 1'b0, 8'h00, 8'b1100_1010);
        verifier_s_out(1'b1);
        pas(1'b0, 1'b1, 1'b0, GAUCHE, 1'b1, 8'h00, 8'b1001_0101);

        // --- GEL : en = 0, le contenu ne bouge pas malgre dir et s_in ---------
        pas(1'b0, 1'b0, 1'b0, GAUCHE, 1'b1, 8'h00, 8'b1001_0101);
        pas(1'b0, 1'b0, 1'b0, DROITE, 1'b1, 8'h00, 8'b1001_0101);

        // --- decalages a DROITE (valeurs calculees a la main) -----------------
        dir = DROITE; #1 verifier_s_out(1'b1);   // dir=droite -> s_out = q[0] = 1
        pas(1'b0, 1'b1, 1'b0, DROITE, 1'b0, 8'h00, 8'b0100_1010);
        verifier_s_out(1'b0);                    // q[0] vaut maintenant 0
        pas(1'b0, 1'b1, 1'b0, DROITE, 1'b1, 8'h00, 8'b1010_0101);
        pas(1'b0, 1'b1, 1'b0, DROITE, 1'b0, 8'h00, 8'b0101_0010);

        // --- le chargement est PRIORITAIRE sur le decalage ---------------------
        pas(1'b0, 1'b1, 1'b1, DROITE, 1'b1, 8'b1111_0000, 8'b1111_0000);

        // --- conversion SERIE -> PARALLELE, decalage a GAUCHE -----------------
        // On vide le registre, puis on entre 1,0,1,1,0,0,1,0 (MSB d'abord).
        // Apres 8 fronts, le registre doit contenir exactement 1011_0010.
        motif = 8'b1011_0010;
        pas(1'b1, 1'b0, 1'b0, GAUCHE, 1'b0, 8'h00, 8'b0000_0000);
        for (i = 0; i < N; i = i + 1) begin
            rst = 1'b0; en = 1'b1; load = 1'b0; dir = GAUCHE;
            s_in = motif[N-1-i];
            @(posedge clk);
            #1;
            cycles = cycles + 1;
        end
        if (q !== motif) begin
            erreurs = erreurs + 1;
            $display("ECHEC serie->parallele (gauche) : q=%b (attendu %b)", q, motif);
        end

        // --- meme motif entre a DROITE : l'octet arrive a l'envers ------------
        // 1,0,1,1,0,0,1,0 entres par le MSB donnent 0100_1101.
        pas(1'b1, 1'b0, 1'b0, DROITE, 1'b0, 8'h00, 8'b0000_0000);
        for (i = 0; i < N; i = i + 1) begin
            rst = 1'b0; en = 1'b1; load = 1'b0; dir = DROITE;
            s_in = motif[N-1-i];
            @(posedge clk);
            #1;
            cycles = cycles + 1;
        end
        if (q !== 8'b0100_1101) begin
            erreurs = erreurs + 1;
            $display("ECHEC serie->parallele (droite) : q=%b (attendu 01001101)", q);
        end

        // --- rotation : on reboucle s_out sur s_in pendant 8 fronts ----------
        // Un decalage a gauche avec s_in = q[7] fait tourner l'octet sur
        // lui-meme : apres N fronts on doit retrouver la valeur de depart.
        pas(1'b0, 1'b0, 1'b1, GAUCHE, 1'b0, 8'b1100_0011, 8'b1100_0011);
        for (i = 0; i < N; i = i + 1) begin
            rst = 1'b0; en = 1'b1; load = 1'b0; dir = GAUCHE;
            #1;                         // laisse le mux combinatoire se stabiliser
            s_in = s_out;               // rebouclage : rotation
            @(posedge clk);
            #1;
            cycles = cycles + 1;
        end
        if (q !== 8'b1100_0011) begin
            erreurs = erreurs + 1;
            $display("ECHEC rotation sur 8 fronts : q=%b (attendu 11000011)", q);
        end

        // --- reset final -------------------------------------------------------
        pas(1'b1, 1'b1, 1'b0, GAUCHE, 1'b1, 8'h00, 8'b0000_0000);

        if (erreurs == 0)
            $display("PASS tb_shift_register (%0d cycles, N=%0d : chargement, gauche, droite, gel, serie->parallele, rotation)", cycles, N);
        else
            $display("ECHEC tb_shift_register : %0d erreur(s)", erreurs);
        $finish;
    end

endmodule
