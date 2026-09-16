`timescale 1ns / 1ps
//=============================================================================
// tb_mux2to1 — banc d'essai exhaustif du multiplexeur 2 vers 1.
//
// Deux instances sont éprouvées en parallèle, pour vérifier que le paramètre de
// largeur fait bien son travail :
//   - W = 1 : balayage exhaustif des 2^3 = 8 combinaisons (d0, d1, sel) ;
//   - W = 4 : balayage exhaustif des 2^8 mots de données x 2 sélecteurs,
//             soit 512 vecteurs.
//
// RÉFÉRENCE INDÉPENDANTE. On ne réécrit pas (~sel & d0) | (sel & d1) — ce
// serait comparer la logique à elle-même. On concatène les deux entrées en un
// bus {d1, d0} et on en extrait la tranche d'indice sel par un DÉCALAGE :
//
//        attendu = ({d1, d0} >> (sel * W))   tronqué à W bits
//
// Le multiplexeur est ainsi confronté à sa définition (« prendre le mot numéro
// sel ») et non à son implémentation.
//=============================================================================
module tb_mux2to1;

    localparam W = 4;

    reg          d0_1, d1_1, sel_1;
    wire         y_1;

    reg  [W-1:0] d0_n, d1_n;
    reg          sel_n;
    wire [W-1:0] y_n;

    integer i, c, s;
    integer erreurs  = 0;
    integer vecteurs = 0;

    reg           attendu_1;
    reg [2*W-1:0] concat;
    reg [W-1:0]   attendu_n;

    mux2to1 #(.W(1)) dut_1bit (.d0(d0_1), .d1(d1_1), .sel(sel_1), .y(y_1));
    mux2to1 #(.W(W)) dut_bus  (.d0(d0_n), .d1(d1_n), .sel(sel_n), .y(y_n));

    initial begin
        // ---- 1) largeur 1 : les 8 combinaisons -----------------------------
        for (i = 0; i < 8; i = i + 1) begin
            {d1_1, d0_1, sel_1} = i[2:0];
            #1;
            attendu_1 = ({d1_1, d0_1} >> sel_1) & 1'b1;
            vecteurs  = vecteurs + 1;
            if (y_1 !== attendu_1) begin
                erreurs = erreurs + 1;
                if (erreurs < 6)
                    $display("ECHEC W=1 : d0=%b d1=%b sel=%b -> y=%b (attendu %b)",
                             d0_1, d1_1, sel_1, y_1, attendu_1);
            end
        end

        // ---- 2) largeur W : tous les mots, les deux sélecteurs -------------
        for (c = 0; c < (1 << (2*W)); c = c + 1)
        for (s = 0; s < 2; s = s + 1) begin
            {d1_n, d0_n} = c[2*W-1:0];
            sel_n        = s[0];
            #1;
            concat    = {d1_n, d0_n};
            attendu_n = concat >> (sel_n * W);
            vecteurs  = vecteurs + 1;
            if (y_n !== attendu_n) begin
                erreurs = erreurs + 1;
                if (erreurs < 6)
                    $display("ECHEC W=%0d : d0=%b d1=%b sel=%b -> y=%b (attendu %b)",
                             W, d0_n, d1_n, sel_n, y_n, attendu_n);
            end
        end

        if (erreurs == 0) $display("PASS tb_mux2to1 (%0d/%0d vecteurs, largeurs 1 et %0d)",
                                   vecteurs, vecteurs, W);
        else              $display("ECHEC tb_mux2to1 : %0d erreur(s)", erreurs);
        $finish;
    end

endmodule
