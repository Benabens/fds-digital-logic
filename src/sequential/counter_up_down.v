`timescale 1ns / 1ps
//=============================================================================
// counter_up_down — compteur binaire N bits haut/bas
//
// Un compteur est la machine séquentielle la plus simple qui ne se contente
// pas de mémoriser : elle CALCULE son état suivant. La structure est celle de
// toute machine synchrone —
//
//        [ incrémenteur/décrémenteur + mux ]  ->  [ registre N bits ]
//                      ^                                    |
//                      +------------------------------------+
//
// Table de transition (priorités décroissantes, comme dans le if/else) :
//   rst load en up | q'
//    1    x   x  x | 0            reset synchrone
//    0    1   x  x | d            chargement parallèle
//    0    0   0  x | q            gel (l'horloge tourne toujours)
//    0    0   1  1 | q + 1        comptage AVANT
//    0    0   1  0 | q - 1        comptage ARRIÈRE
//
// REBOUCLAGE (wrap-around) : l'arithmétique est modulo 2^N, exactement comme
// pour l'additionneur du chapitre précédent. En avant, 2^N-1 -> 0 (par ex.
// 1111 -> 0000) ; en arrière, 0 -> 2^N-1 (0000 -> 1111). Ce n'est pas une
// anomalie mais la conséquence directe de la troncature à N bits ; la sortie
// `boucle` signale d'avance le front sur lequel ce passage aura lieu, ce qui
// permet de CHAÎNER les compteurs (on branche `boucle` sur le `en` de
// l'étage suivant pour obtenir un compteur de 2N bits).
//
// STYLE :
//   - mise à jour de l'état : `always @(posedge clk)` + « <= » (séquentiel) ;
//   - drapeau `boucle` : `always @*` + « = » (combinatoire pur, il ne dépend
//     que de l'état COURANT et des commandes, jamais d'un front).
//=============================================================================
module counter_up_down #(
    parameter N = 4
)(
    input  wire         clk,
    input  wire         rst,    // reset synchrone
    input  wire         en,     // autorise le comptage
    input  wire         load,   // chargement parallèle (prioritaire sur en)
    input  wire         up,     // 1 = incrémenter, 0 = décrémenter
    input  wire [N-1:0] d,      // valeur de chargement
    output reg  [N-1:0] q,
    output reg          boucle  // 1 si le PROCHAIN front fait reboucler
);

    // --- partie SÉQUENTIELLE ------------------------------------------------
    always @(posedge clk) begin
        if (rst)
            q <= {N{1'b0}};
        else if (load)
            q <= d;
        else if (en)
            q <= up ? (q + 1'b1) : (q - 1'b1);
    end

    // --- partie COMBINATOIRE ------------------------------------------------
    always @* begin
        if (rst || load || !en)
            boucle = 1'b0;                 // aucun comptage n'aura lieu
        else if (up)
            boucle = (q == {N{1'b1}});     // 111...1 -> 000...0
        else
            boucle = (q == {N{1'b0}});     // 000...0 -> 111...1
    end

endmodule
