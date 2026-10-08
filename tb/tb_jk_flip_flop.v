`timescale 1ns / 1ps
//=============================================================================
// tb_jk_flip_flop — banc d'essai de la bascule JK.
//
// La table de transition de la JK a 4 modes (mémorisation, reset, set,
// basculement) et l'état suivant dépend AUSSI de l'état courant : il y a donc
// 4 x 2 = 8 situations distinctes (j, k, q). Le banc les couvre TOUTES et le
// vérifie explicitement à la fin — un test qui ne couvrirait, par exemple,
// j=k=1 que depuis q=0 ne prouverait rien sur le basculement.
//
// La référence n'est PAS l'équation q' = j.NOT(q) + NOT(k).q utilisée par le
// module (ce serait vérifier une formule contre elle-même) : on applique la
// TABLE de transition, cas par cas, telle qu'elle est énoncée dans le cours.
//=============================================================================
module tb_jk_flip_flop;

    reg  clk = 1'b0;
    reg  rst, j, k;
    wire q, q_b;

    integer erreurs = 0;
    integer cycles  = 0;
    integer i, ij, ik, iq;
    reg     attendu;
    reg [7:0] couverture = 8'b0;   // index {j, k, q_courant}

    jk_flip_flop dut (.clk(clk), .rst(rst), .j(j), .k(k), .q(q), .q_b(q_b));

    always #5 clk = ~clk;

    task pas;
        input in_rst, in_j, in_k;
        reg   avant;
        begin
            rst   = in_rst;
            j     = in_j;
            k     = in_k;
            avant = attendu;
            @(posedge clk);
            #1;
            cycles = cycles + 1;

            // --- reference : la TABLE du cours, cas par cas ------------------
            if (in_rst)
                attendu = 1'b0;
            else begin
                couverture[{in_j, in_k, avant}] = 1'b1;
                case ({in_j, in_k})
                    2'b00: attendu = avant;      // memorisation
                    2'b01: attendu = 1'b0;       // reset
                    2'b10: attendu = 1'b1;       // set
                    2'b11: attendu = ~avant;     // basculement
                endcase
            end

            if (q !== attendu) begin
                erreurs = erreurs + 1;
                $display("ECHEC cycle %0d (t=%0t) : rst=%b j=%b k=%b q_avant=%b -> q=%b (attendu %b)",
                         cycles, $time, in_rst, in_j, in_k, avant, q, attendu);
            end
            if (q_b !== ~q) begin
                erreurs = erreurs + 1;
                $display("ECHEC cycle %0d : q_b=%b n'est pas le complement de q=%b",
                         cycles, q_b, q);
            end
        end
    endtask

    // Force l'etat courant a `etat` en une commande set ou reset.
    task forcer_etat;
        input etat;
        begin
            if (etat) pas(1'b0, 1'b1, 1'b0);    // set
            else      pas(1'b0, 1'b0, 1'b1);    // reset
        end
    endtask

    initial begin
        rst = 1'b1;
        j   = 1'b0;
        k   = 1'b0;

        pas(1'b1, 1'b1, 1'b1);      // reset prioritaire sur j et k
        pas(1'b1, 1'b0, 1'b0);

        // --- balayage EXHAUSTIF des 8 situations (j, k, q) -------------------
        for (iq = 0; iq < 2; iq = iq + 1)
        for (ij = 0; ij < 2; ij = ij + 1)
        for (ik = 0; ik < 2; ik = ik + 1) begin
            forcer_etat(iq[0]);                 // on place l'etat de depart
            pas(1'b0, ij[0], ik[0]);            // puis on applique la commande
        end

        // --- basculement repete : j = k = 1 se comporte comme une bascule T --
        forcer_etat(1'b0);
        for (i = 0; i < 10; i = i + 1)
            pas(1'b0, 1'b1, 1'b1);

        // --- memorisation prolongee : j = k = 0 ------------------------------
        forcer_etat(1'b1);
        for (i = 0; i < 6; i = i + 1)
            pas(1'b0, 1'b0, 1'b0);
        if (q !== 1'b1) begin
            erreurs = erreurs + 1;
            $display("ECHEC : j=k=0 n'a pas memorise");
        end

        // --- sequence melangee ------------------------------------------------
        for (i = 0; i < 24; i = i + 1)
            pas(1'b0, ((i / 2) % 2) == 0, ((i / 3) % 2) == 0);

        // --- reset au vol -----------------------------------------------------
        pas(1'b1, 1'b1, 1'b1);
        pas(1'b0, 1'b0, 1'b0);

        // --- controle de COUVERTURE ------------------------------------------
        if (couverture !== 8'hFF) begin
            erreurs = erreurs + 1;
            $display("ECHEC : couverture incomplete des 8 situations (j,k,q) : %b", couverture);
        end

        if (erreurs == 0)
            $display("PASS tb_jk_flip_flop (%0d cycles, 8/8 situations (j,k,q) couvertes)", cycles);
        else
            $display("ECHEC tb_jk_flip_flop : %0d erreur(s)", erreurs);
        $finish;
    end

endmodule
