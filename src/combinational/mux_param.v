`timescale 1ns / 1ps
//=============================================================================
// mux_param — multiplexeur générique 2^SEL vers 1, largeur W, par generate
//
// Généralisation de mux2to1 / mux4to1 / mux8to1 : au lieu d'écrire un module
// par taille, on décrit UNE FOIS la loi de construction et on laisse
// l'élaborateur dérouler l'arbre. Deux paramètres :
//
//   SEL : nombre de bits de sélection  -> N = 2^SEL entrées   (SEL >= 1)
//   W   : largeur de chaque entrée en bits
//
// Les N entrées sont aplaties dans un bus de N*W bits, le mot i occupant
// d[(i+1)*W-1 : i*W] (même convention que mux8to1).
//
// ARBRE BINAIRE PAR GENERATE. On numérote les étages de 0 à SEL. L'étage 0
// contient les N entrées ; l'étage k+1 est obtenu en appariant les mots de
// l'étage k deux par deux, chaque paire étant arbitrée par UN mux2to1 commandé
// par sel[k]. Le nombre de mots est divisé par deux à chaque étage :
//
//   étage 0 : N mots      (les entrées)
//   étage 1 : N/2 mots    commandé par sel[0]
//   étage 2 : N/4 mots    commandé par sel[1]
//   ...
//   étage SEL : 1 mot     commandé par sel[SEL-1]  -> la sortie y
//
// COÛT. Le nombre total de mux2to1 est N/2 + N/4 + ... + 1 = N-1 : la surface
// croît LINÉAIREMENT avec le nombre d'entrées. La profondeur, elle, ne vaut que
// SEL = log2(N) étages : le délai croît LOGARITHMIQUEMENT. C'est le compromis
// classique surface/délai des structures en arbre, le même que pour un
// additionneur à anticipation de retenue ou un arbre de réduction OR.
//
// La boucle generate n'est PAS une boucle d'exécution : elle est déroulée à
// l'élaboration et produit N-1 instances de portes bien réelles. C'est le
// mécanisme qui rend le Verilog synthétisable réutilisable.
//=============================================================================
module mux_param #(
    parameter SEL = 3,                  // bits de sélection (SEL >= 1)
    parameter W   = 8                   // largeur d'un mot
)(
    input  wire [(1<<SEL)*W-1:0] d,     // les 2^SEL mots concaténés
    input  wire [SEL-1:0]        sel,
    output wire [W-1:0]          y
);

    localparam N = 1 << SEL;            // nombre d'entrées

    // Tableau plat des noeuds de l'arbre : le mot j de l'étage k est rangé à
    // l'indice k*N + j. Les cases au-delà de N>>k d'un étage restent inutilisées
    // (on paie quelques fils fictifs à la description, aucun au silicium : la
    // synthèse élimine ce qui ne pilote rien).
    wire [W-1:0] noeud [0:(SEL+1)*N-1];

    genvar k, j;
    generate
        // Étage 0 : découpage du bus d'entrée en N mots de W bits.
        for (j = 0; j < N; j = j + 1) begin : feuille
            assign noeud[j] = d[j*W +: W];
        end

        // Étages 1..SEL : appariement deux par deux, arbitré par sel[k].
        for (k = 0; k < SEL; k = k + 1) begin : etage
            for (j = 0; j < (N >> (k+1)); j = j + 1) begin : paire
                mux2to1 #(.W(W)) m (
                    .d0  (noeud[ k   *N + 2*j    ]),
                    .d1  (noeud[ k   *N + 2*j + 1]),
                    .sel (sel[k]),
                    .y   (noeud[(k+1)*N + j      ])
                );
            end
        end
    endgenerate

    assign y = noeud[SEL*N];            // racine de l'arbre

endmodule
