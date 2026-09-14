`timescale 1ns / 1ps
//=============================================================================
// comparator — comparateur 1 bit
//
// Compare deux bits et rend le résultat sous forme de trois indicateurs
// MUTUELLEMENT EXCLUSIFS : exactement une des trois sorties vaut 1, toujours.
//
//   A_eq_B = NOT (a XOR b)   égalité : les deux bits coïncident
//   A_gt_B = a AND (NOT b)   a > b : le seul cas 1 > 0
//   A_lt_B = (NOT a) AND b   a < b : le seul cas 0 < 1
//
// Table de vérité :
//   a b | eq gt lt
//   0 0 | 1  0  0
//   0 1 | 0  0  1
//   1 0 | 0  1  0
//   1 1 | 1  0  0
//
// On reconnaît dans A_eq_B la porte XNOR, souvent appelée « comparateur
// d'égalité » pour cette raison. La somme des trois sorties vaut 1 dans les
// quatre cas : c'est une propriété que le banc d'essai vérifie explicitement,
// car elle caractérise un comparateur correct.
//
// Ce module est la CELLULE de base du comparateur N bits
// (voir magnitude_comparator.v), au même titre que half_adder l'est pour les
// additionneurs : on décrit la cellule une fois, la structure la réplique.
//=============================================================================
module comparator (
    input  wire a,
    input  wire b,
    output wire A_eq_B,
    output wire A_gt_B,
    output wire A_lt_B
);

    assign A_eq_B = ~(a ^ b);
    assign A_gt_B =  a & ~b;
    assign A_lt_B = ~a &  b;

endmodule
