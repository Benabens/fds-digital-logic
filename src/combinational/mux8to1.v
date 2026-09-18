`timescale 1ns / 1ps
//=============================================================================
// mux8to1 — multiplexeur 8 vers 1, paramétré, entrées groupées en un seul bus
//
// Choisit un mot parmi huit selon un sélecteur de 3 bits (sel = 0..7).
//
// ENTRÉES APLATIES. Verilog-2001 ne connaît pas les tableaux de ports : on ne
// peut pas écrire `input wire [W-1:0] d [0:7]`. La convention idiomatique est
// donc de CONCATÉNER les huit mots dans un seul bus de 8*W bits, le mot i
// occupant les bits [(i+1)*W-1 : i*W] :
//
//   d = { d7 , d6 , d5 , d4 , d3 , d2 , d1 , d0 }
//        MSB                                 LSB
//
// L'appelant écrit simplement `.d({m7, m6, m5, m4, m3, m2, m1, m0})`. On lit
// chaque tranche avec la sélection de partie indexée `d[base +: W]`, qui donne
// W bits à partir de `base` — indispensable dès que la largeur est un paramètre.
//
// STRUCTURE : trois étages, réutilisant mux4to1 (donc mux2to1). sel[1:0]
// sélectionne à l'intérieur de chaque groupe de quatre, sel[2] choisit le
// groupe. Profondeur log2(8) = 3.
//
//   d[3..0] --> mux4to1 --> quartet_bas  --\
//                                           mux2to1 --> y     (commandé par sel[2])
//   d[7..4] --> mux4to1 --> quartet_haut --/
//
// À QUOI ÇA SERT. Un mux 8→1 de largeur 32 est exactement le port de lecture
// d'un banc de 8 registres : sel est le numéro de registre lu. C'est aussi la
// façon dont on implante une fonction booléenne quelconque de 3 variables en
// câblant les constantes voulues sur les huit entrées de données.
//=============================================================================
module mux8to1 #(
    parameter W = 1
)(
    input  wire [8*W-1:0] d,      // {d7,...,d0} concaténés, d0 en poids faible
    input  wire [2:0]     sel,
    output wire [W-1:0]   y
);

    wire [W-1:0] quartet_bas;     // gagnant de d0..d3
    wire [W-1:0] quartet_haut;    // gagnant de d4..d7

    // Étages 1 et 2 : sel[1:0] à l'intérieur de chaque quartet.
    mux4to1 #(.W(W)) mux_quartet_bas (
        .d0  (d[0*W +: W]),
        .d1  (d[1*W +: W]),
        .d2  (d[2*W +: W]),
        .d3  (d[3*W +: W]),
        .sel (sel[1:0]),
        .y   (quartet_bas)
    );

    mux4to1 #(.W(W)) mux_quartet_haut (
        .d0  (d[4*W +: W]),
        .d1  (d[5*W +: W]),
        .d2  (d[6*W +: W]),
        .d3  (d[7*W +: W]),
        .sel (sel[1:0]),
        .y   (quartet_haut)
    );

    // Étage 3 : sel[2] choisit le quartet.
    mux2to1 #(.W(W)) mux_sortie (
        .d0  (quartet_bas),
        .d1  (quartet_haut),
        .sel (sel[2]),
        .y   (y)
    );

endmodule
