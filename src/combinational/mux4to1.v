`timescale 1ns / 1ps
//=============================================================================
// mux4to1 — multiplexeur 4 vers 1, paramétré, construit à partir de mux2to1
//
// Choisit une entrée parmi quatre selon un sélecteur de 2 bits :
//
//   sel | y
//   00  | d0
//   01  | d1
//   10  | d2
//   11  | d3
//
// CONSTRUCTION EN ARBRE. Plutôt que d'écrire les quatre produits
// (~s1~s0 d0 | ~s1 s0 d1 | s1~s0 d2 | s1 s0 d3), on empile deux ÉTAGES de
// multiplexeurs 2→1 :
//
//        d0 --|\
//             | |--- bas ---|\
//        d1 --|/            | |
//              sel[0]       | |--- y
//        d2 --|\            | |
//             | |-- haut ---|/
//        d3 --|/             sel[1]
//              sel[0]
//
// Le bit de POIDS FAIBLE sel[0] tranche à l'intérieur de chaque paire ; le bit
// de POIDS FORT sel[1] choisit ensuite la paire gagnante. C'est exactement la
// lecture positionnelle du nombre binaire sel.
//
// L'intérêt dépasse l'économie de frappe : l'arbre a une PROFONDEUR
// logarithmique (log2(4) = 2 étages), donc un délai en O(log n) au lieu de la
// chaîne linéaire qu'on obtiendrait en cascadant naïvement des mux 2→1. C'est
// la même idée que l'anticipation de retenue face au ripple-carry.
//=============================================================================
module mux4to1 #(
    parameter W = 1
)(
    input  wire [W-1:0] d0,
    input  wire [W-1:0] d1,
    input  wire [W-1:0] d2,
    input  wire [W-1:0] d3,
    input  wire [1:0]   sel,
    output wire [W-1:0] y
);

    wire [W-1:0] paire_basse;   // gagnante de {d0, d1}
    wire [W-1:0] paire_haute;   // gagnante de {d2, d3}

    // Étage 1 : sel[0] arbitre à l'intérieur de chaque paire.
    mux2to1 #(.W(W)) mux_paire_basse (
        .d0  (d0),
        .d1  (d1),
        .sel (sel[0]),
        .y   (paire_basse)
    );

    mux2to1 #(.W(W)) mux_paire_haute (
        .d0  (d2),
        .d1  (d3),
        .sel (sel[0]),
        .y   (paire_haute)
    );

    // Étage 2 : sel[1] choisit la paire.
    mux2to1 #(.W(W)) mux_sortie (
        .d0  (paire_basse),
        .d1  (paire_haute),
        .sel (sel[1]),
        .y   (y)
    );

endmodule
