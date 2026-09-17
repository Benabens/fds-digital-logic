`timescale 1ns / 1ps
//=============================================================================
// tb_mux4to1 — banc d'essai exhaustif du multiplexeur 4 vers 1.
//
// Largeur W = 2 : les quatre entrées totalisent 8 bits de données, soit 256
// configurations, multipliées par les 4 valeurs du sélecteur = 1024 vecteurs.
// Le balayage est donc COMPLET : aucune combinaison n'échappe au test, ce qui
// couvre en particulier les cas où plusieurs entrées portent la même valeur
// (un mux fautif qui recopierait la mauvaise entrée pourrait s'y cacher).
//
// RÉFÉRENCE INDÉPENDANTE : le mot attendu est extrait de la concaténation
// {d3, d2, d1, d0} par décalage de sel*W bits. Rien de la structure en arbre
// (deux étages de mux2to1) n'est reproduit ici — on teste la SPÉCIFICATION.
//
// Un second passage éprouve la largeur W = 1 sur toutes ses combinaisons
// (16 mots de données x 4 sélecteurs), pour vérifier le cas dégénéré où la
// tranche ne fait qu'un bit.
//=============================================================================
module tb_mux4to1;

    localparam W = 2;

    reg  [W-1:0] d0, d1, d2, d3;
    reg  [1:0]   sel;
    wire [W-1:0] y;

    reg          e0, e1, e2, e3;
    reg  [1:0]   sel_1;
    wire         y_1;

    integer c, s;
    integer erreurs  = 0;
    integer vecteurs = 0;

    reg [4*W-1:0] concat;
    reg [W-1:0]   attendu;
    reg           attendu_1;

    mux4to1 #(.W(W)) dut_bus (
        .d0(d0), .d1(d1), .d2(d2), .d3(d3), .sel(sel), .y(y)
    );

    mux4to1 #(.W(1)) dut_1bit (
        .d0(e0), .d1(e1), .d2(e2), .d3(e3), .sel(sel_1), .y(y_1)
    );

    initial begin
        // ---- 1) largeur W : 2^(4W) mots x 4 sélecteurs --------------------
        for (c = 0; c < (1 << (4*W)); c = c + 1)
        for (s = 0; s < 4; s = s + 1) begin
            {d3, d2, d1, d0} = c[4*W-1:0];
            sel              = s[1:0];
            #1;
            concat   = {d3, d2, d1, d0};
            attendu  = concat >> (sel * W);
            vecteurs = vecteurs + 1;
            if (y !== attendu) begin
                erreurs = erreurs + 1;
                if (erreurs < 6)
                    $display("ECHEC W=%0d : d={%b,%b,%b,%b} sel=%b -> y=%b (attendu %b)",
                             W, d3, d2, d1, d0, sel, y, attendu);
            end
        end

        // ---- 2) largeur 1 : 16 mots x 4 sélecteurs ------------------------
        for (c = 0; c < 16; c = c + 1)
        for (s = 0; s < 4; s = s + 1) begin
            {e3, e2, e1, e0} = c[3:0];
            sel_1            = s[1:0];
            #1;
            attendu_1 = ({e3, e2, e1, e0} >> sel_1) & 1'b1;
            vecteurs  = vecteurs + 1;
            if (y_1 !== attendu_1) begin
                erreurs = erreurs + 1;
                if (erreurs < 6)
                    $display("ECHEC W=1 : d={%b,%b,%b,%b} sel=%b -> y=%b (attendu %b)",
                             e3, e2, e1, e0, sel_1, y_1, attendu_1);
            end
        end

        if (erreurs == 0) $display("PASS tb_mux4to1 (%0d/%0d vecteurs, largeurs %0d et 1)",
                                   vecteurs, vecteurs, W);
        else              $display("ECHEC tb_mux4to1 : %0d erreur(s)", erreurs);
        $finish;
    end

endmodule
