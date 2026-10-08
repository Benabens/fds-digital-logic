`timescale 1ns / 1ps
//=============================================================================
// jk_flip_flop — bascule JK, construite à partir d'une bascule D
//
// La bascule JK est le verrou SR « réparé » : elle offre les mêmes commandes
// SET (j = 1) et RESET (k = 1), mais la combinaison j = k = 1, qui était
// INTERDITE sur le verrou SR (cf. sr_latch.v), reçoit ici une définition
// parfaitement légale et utile : le BASCULEMENT. Aucune entrée n'est donc
// interdite — c'est la bascule la plus « complète » du cours.
//
// TABLE DE TRANSITION :
//   rst j k | q'      | nom du mode
//    1  x x | 0       | reset synchrone
//    0  0 0 | q       | MÉMORISATION
//    0  0 1 | 0       | RESET
//    0  1 0 | 1       | SET
//    0  1 1 | NOT q   | BASCULEMENT (toggle)
//
// Table de Karnaugh de l'état suivant, en fonction de (j, k, q) :
//
//        q\jk | 00 | 01 | 11 | 10
//        -----+----+----+----+----
//          0  |  0 |  0 |  1 |  1     -> q' = 1 des que j = 1
//          1  |  1 |  0 |  0 |  1     -> q' = 1 tant que k = 0
//
// D'où l'équation caractéristique, à mémoriser :
//
//        q' = j . NOT(q)  +  NOT(k) . q
//
// Cas particuliers utiles à vérifier mentalement :
//   - j = k = 0 : q' = NOT(k).q = q            (mémorisation)
//   - j = k = 1 : q' = NOT(q)                  (basculement -> bascule T)
// Une bascule T n'est donc qu'une JK dont on a relié j et k ensemble.
//
// STYLE : équation d'état suivant = logique COMBINATOIRE (`always @*`,
// affectations bloquantes « = ») ; la mémorisation, et donc le « <= », est
// entièrement déléguée à d_flip_flop.
//=============================================================================
module jk_flip_flop (
    input  wire clk,
    input  wire rst,    // reset synchrone
    input  wire j,      // set
    input  wire k,      // reset
    output wire q,
    output wire q_b
);

    reg d_interne;

    // Logique COMBINATOIRE d'état suivant -> always @* et « = ».
    always @* begin
        d_interne = (j & ~q) | (~k & q);
    end

    d_flip_flop bascule (
        .clk (clk),
        .rst (rst),
        .d   (d_interne),
        .q   (q),
        .q_b (q_b)
    );

endmodule
