`timescale 1ns / 1ps
//=============================================================================
// tb_mux8to1 — banc d'essai du multiplexeur 8 vers 1 à entrées aplaties.
//
// Deux campagnes :
//
//   1) W = 1 : balayage EXHAUSTIF. Le bus de données ne fait que 8 bits, donc
//      256 configurations x 8 sélecteurs = 2048 vecteurs. Aucune combinaison
//      n'est omise.
//
//   2) W = 3 : le bus fait 24 bits, l'exhaustif (2^24 x 8) est hors de portée.
//      On construit alors 256 motifs DÉTERMINISTES dont les octets ne sont pas
//      alignés sur les tranches de 3 bits — c'est exactement ce qui piège une
//      erreur de découpage `d[i*W +: W]` (décalage d'un bit, tranches
//      inversées, mot i lu à la place du mot 7-i). Chaque motif est balayé sur
//      les 8 sélecteurs, soit 2048 vecteurs supplémentaires. Les motifs
//      extrêmes tout-à-zéro et tout-à-un sont inclus explicitement.
//
// RÉFÉRENCE INDÉPENDANTE : extraction par décalage du bus concaténé,
// attendu = (d >> (sel * W)) tronqué à W bits. La structure interne (deux
// mux4to1 + un mux2to1) n'est jamais reproduite.
//=============================================================================
module tb_mux8to1;

    localparam W = 3;

    reg  [7:0]     d_1;
    reg  [2:0]     sel_1;
    wire           y_1;

    reg  [8*W-1:0] d_n;
    reg  [2:0]     sel_n;
    wire [W-1:0]   y_n;

    integer c, s;
    integer erreurs  = 0;
    integer vecteurs = 0;

    reg           attendu_1;
    reg [W-1:0]   attendu_n;

    mux8to1 #(.W(1)) dut_1bit (.d(d_1), .sel(sel_1), .y(y_1));
    mux8to1 #(.W(W)) dut_bus  (.d(d_n), .sel(sel_n), .y(y_n));

    initial begin
        // ---- 1) W = 1 : exhaustif (256 x 8) --------------------------------
        for (c = 0; c < 256; c = c + 1)
        for (s = 0; s < 8; s = s + 1) begin
            d_1      = c[7:0];
            sel_1    = s[2:0];
            #1;
            attendu_1 = (d_1 >> sel_1) & 1'b1;
            vecteurs  = vecteurs + 1;
            if (y_1 !== attendu_1) begin
                erreurs = erreurs + 1;
                if (erreurs < 6)
                    $display("ECHEC W=1 : d=%b sel=%0d -> y=%b (attendu %b)",
                             d_1, sel_1, y_1, attendu_1);
            end
        end

        // ---- 2) W = 3 : 256 motifs deterministes x 8 -----------------------
        for (c = 0; c < 256; c = c + 1)
        for (s = 0; s < 8; s = s + 1) begin
            // Trois octets decorreles : les frontieres de mots (3 bits) ne
            // coincident pas avec celles des octets, ce qui rend toute erreur
            // de tranche visible.
            d_n   = {c[7:0], c[7:0] ^ 8'hA5, (c[7:0] + 8'd37)};
            sel_n = s[2:0];
            #1;
            attendu_n = d_n >> (sel_n * W);
            vecteurs  = vecteurs + 1;
            if (y_n !== attendu_n) begin
                erreurs = erreurs + 1;
                if (erreurs < 6)
                    $display("ECHEC W=%0d : d=%b sel=%0d -> y=%b (attendu %b)",
                             W, d_n, sel_n, y_n, attendu_n);
            end
        end

        // ---- 3) cas limites : bus tout a zero puis tout a un ---------------
        for (c = 0; c < 2; c = c + 1)
        for (s = 0; s < 8; s = s + 1) begin
            d_n   = c[0] ? {(8*W){1'b1}} : {(8*W){1'b0}};
            sel_n = s[2:0];
            #1;
            attendu_n = d_n >> (sel_n * W);
            vecteurs  = vecteurs + 1;
            if (y_n !== attendu_n) begin
                erreurs = erreurs + 1;
                if (erreurs < 6)
                    $display("ECHEC limite : d=%b sel=%0d -> y=%b (attendu %b)",
                             d_n, sel_n, y_n, attendu_n);
            end
        end

        if (erreurs == 0) $display("PASS tb_mux8to1 (%0d/%0d vecteurs, largeurs 1 et %0d)",
                                   vecteurs, vecteurs, W);
        else              $display("ECHEC tb_mux8to1 : %0d erreur(s)", erreurs);
        $finish;
    end

endmodule
