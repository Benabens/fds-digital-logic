`timescale 1ns / 1ps
//=============================================================================
// full_adder — additionneur complet 1 bit (description STRUCTURELLE)
//
// Additionne trois bits (x, y et une retenue entrante) et produit une somme et
// une retenue sortante. Construit par assemblage de deux demi-additionneurs,
// exactement comme le schéma du cours :
//
//   x ──┐
//       ├─ HA1 ─┬─ somme_partielle ──┐
//   y ──┘       │                    ├─ HA2 ─┬── s
//               │        c_in ───────┘       │
//               └─ retenue1 ──┐              └── retenue2
//                             ├──── OR ──── c_out
//                retenue2 ────┘
//
// Une retenue sort si l'un OU l'autre des demi-additionneurs en produit une ;
// les deux ne peuvent jamais en produire simultanément, donc un OR suffit
// (un XOR donnerait le même résultat).
//
// Voir full_adder_behavioral.v pour la même fonction décrite au niveau
// comportemental — la comparaison des deux styles est un point du cours.
//=============================================================================
module full_adder (
    input  wire x,
    input  wire y,
    input  wire c_in,
    output wire s,
    output wire c_out
);

    wire somme_partielle;   // x XOR y
    wire retenue1;          // retenue produite par x + y
    wire retenue2;          // retenue produite par (x XOR y) + c_in

    half_adder ha1 (
        .x     (x),
        .y     (y),
        .s     (somme_partielle),
        .c_out (retenue1)
    );

    half_adder ha2 (
        .x     (somme_partielle),
        .y     (c_in),
        .s     (s),
        .c_out (retenue2)
    );

    or or_retenue (c_out, retenue1, retenue2);

endmodule
