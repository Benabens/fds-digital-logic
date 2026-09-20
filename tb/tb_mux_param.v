`timescale 1ns / 1ps
//=============================================================================
// tb_mux_param — banc d'essai du multiplexeur générique 2^SEL vers 1.
//
// L'enjeu n'est pas seulement « le mux choisit-il la bonne entrée » mais « la
// boucle generate construit-elle le bon arbre POUR TOUTE valeur de SEL ». On
// instancie donc quatre configurations distinctes, du cas dégénéré SEL = 1
// (l'arbre se réduit à un seul mux2to1) au cas SEL = 4 (15 mux sur 4 étages) :
//
//   A : SEL = 1, W = 4  ->  2 entrees   : exhaustif   (256 mots x 2 sel)
//   B : SEL = 2, W = 3  ->  4 entrees   : exhaustif   (4096 mots x 4 sel)
//   C : SEL = 3, W = 1  ->  8 entrees   : exhaustif   (256 mots x 8 sel)
//   D : SEL = 4, W = 8  -> 16 entrees   : 64 motifs deterministes x 16 sel
//
// Les trois premières campagnes sont EXHAUSTIVES. La quatrième ne peut pas
// l'être (2^128 mots) : on remplit le bus mot par mot avec une formule
// arithmétique connue, ce qui donne une référence encore plus forte — on
// n'extrait même pas la tranche du bus, on RECALCULE la valeur que le mot
// sélectionné doit contenir.
//
// RÉFÉRENCE INDÉPENDANTE : décalage du bus concaténé (campagnes A, B, C) ou
// formule génératrice (campagne D). L'arbre de mux2to1 n'est jamais rejoué.
//=============================================================================
module tb_mux_param;

    // --- A : SEL = 1, W = 4 -------------------------------------------------
    reg  [7:0]   d_a;
    reg  [0:0]   sel_a;
    wire [3:0]   y_a;

    // --- B : SEL = 2, W = 3 -------------------------------------------------
    reg  [11:0]  d_b;
    reg  [1:0]   sel_b;
    wire [2:0]   y_b;

    // --- C : SEL = 3, W = 1 -------------------------------------------------
    reg  [7:0]   d_c;
    reg  [2:0]   sel_c;
    wire [0:0]   y_c;

    // --- D : SEL = 4, W = 8 -------------------------------------------------
    reg  [127:0] d_d;
    reg  [3:0]   sel_d;
    wire [7:0]   y_d;

    integer c, s, p, w;
    integer erreurs  = 0;
    integer vecteurs = 0;

    reg [3:0] attendu_a;
    reg [2:0] attendu_b;
    reg [0:0] attendu_c;
    reg [7:0] attendu_d;

    mux_param #(.SEL(1), .W(4)) dut_a (.d(d_a), .sel(sel_a), .y(y_a));
    mux_param #(.SEL(2), .W(3)) dut_b (.d(d_b), .sel(sel_b), .y(y_b));
    mux_param #(.SEL(3), .W(1)) dut_c (.d(d_c), .sel(sel_c), .y(y_c));
    mux_param #(.SEL(4), .W(8)) dut_d (.d(d_d), .sel(sel_d), .y(y_d));

    initial begin
        // ---- A : exhaustif -------------------------------------------------
        for (c = 0; c < 256; c = c + 1)
        for (s = 0; s < 2; s = s + 1) begin
            d_a   = c[7:0];
            sel_a = s[0];
            #1;
            attendu_a = d_a >> (sel_a * 4);
            vecteurs  = vecteurs + 1;
            if (y_a !== attendu_a) begin
                erreurs = erreurs + 1;
                if (erreurs < 6)
                    $display("ECHEC SEL=1 W=4 : d=%b sel=%0d -> y=%b (attendu %b)",
                             d_a, sel_a, y_a, attendu_a);
            end
        end

        // ---- B : exhaustif -------------------------------------------------
        for (c = 0; c < 4096; c = c + 1)
        for (s = 0; s < 4; s = s + 1) begin
            d_b   = c[11:0];
            sel_b = s[1:0];
            #1;
            attendu_b = d_b >> (sel_b * 3);
            vecteurs  = vecteurs + 1;
            if (y_b !== attendu_b) begin
                erreurs = erreurs + 1;
                if (erreurs < 6)
                    $display("ECHEC SEL=2 W=3 : d=%b sel=%0d -> y=%b (attendu %b)",
                             d_b, sel_b, y_b, attendu_b);
            end
        end

        // ---- C : exhaustif -------------------------------------------------
        for (c = 0; c < 256; c = c + 1)
        for (s = 0; s < 8; s = s + 1) begin
            d_c   = c[7:0];
            sel_c = s[2:0];
            #1;
            attendu_c = (d_c >> sel_c) & 1'b1;
            vecteurs  = vecteurs + 1;
            if (y_c !== attendu_c) begin
                erreurs = erreurs + 1;
                if (erreurs < 6)
                    $display("ECHEC SEL=3 W=1 : d=%b sel=%0d -> y=%b (attendu %b)",
                             d_c, sel_c, y_c, attendu_c);
            end
        end

        // ---- D : 64 motifs deterministes x 16 selecteurs -------------------
        for (p = 0; p < 64; p = p + 1) begin
            // Le mot w recoit la valeur (17*p + 29*w + 5) mod 256 : deux mots
            // d'un meme motif sont toujours differents (29 est premier avec
            // 256), donc lire le mauvais mot est immediatement detecte.
            for (w = 0; w < 16; w = w + 1)
                d_d[w*8 +: 8] = (17*p + 29*w + 5) % 256;

            for (s = 0; s < 16; s = s + 1) begin
                sel_d = s[3:0];
                #1;
                attendu_d = (17*p + 29*s + 5) % 256;   // formule generatrice
                vecteurs  = vecteurs + 1;
                if (y_d !== attendu_d) begin
                    erreurs = erreurs + 1;
                    if (erreurs < 6)
                        $display("ECHEC SEL=4 W=8 : motif=%0d sel=%0d -> y=%0d (attendu %0d)",
                                 p, sel_d, y_d, attendu_d);
                end
            end
        end

        if (erreurs == 0) $display("PASS tb_mux_param (%0d/%0d vecteurs, SEL = 1, 2, 3 et 4)",
                                   vecteurs, vecteurs);
        else              $display("ECHEC tb_mux_param : %0d erreur(s)", erreurs);
        $finish;
    end

endmodule
