`timescale 1ns / 1ps
//=============================================================================
// half_adder — demi-additionneur 1 bit
//
// Additionne deux bits et produit une somme et une retenue sortante. C'est la
// brique de base de tout le chapitre « Adders » du cours : le plein
// additionneur est bâti à partir de deux demi-additionneurs.
//
//   s     = x XOR y   (somme modulo 2)
//   c_out = x AND y   (retenue : le seul cas 1+1 = 10 en binaire)
//
// Table de vérité :
//   x y | c_out s
//   0 0 |   0   0
//   0 1 |   0   1
//   1 0 |   0   1
//   1 1 |   1   0
//
// Description structurelle (instanciation de portes) plutôt que
// comportementale, pour rester au plus près du schéma logique.
//=============================================================================
module half_adder (
    input  wire x,
    input  wire y,
    output wire s,
    output wire c_out
);

    xor xor_somme   (s,     x, y);
    and and_retenue (c_out, x, y);

endmodule
