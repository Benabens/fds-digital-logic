`timescale 1ns / 1ps
//=============================================================================
// ripple_carry_adder — additionneur à propagation de retenue, N bits
//
// Chaîne de N additionneurs complets où la retenue « ondule » (ripple) du bit
// de poids faible vers le bit de poids fort. C'est l'additionneur le plus
// simple à décrire, et le plus lent : le résultat du bit de poids fort dépend
// de TOUTES les retenues précédentes.
//
//   Délai ≈ N × (délai d'un additionneur complet)  → croissance LINÉAIRE en N.
//
// C'est précisément ce coût qui motive l'additionneur à anticipation de
// retenue (voir carry_lookahead_adder.v), dont le délai croît en O(log N).
//
// La largeur est un paramètre : on instancie le même module en 4, 8, 16 ou 32
// bits sans le réécrire.
//=============================================================================
module ripple_carry_adder #(
    parameter N = 4
)(
    input  wire [N-1:0] a,
    input  wire [N-1:0] b,
    input  wire         c_in,
    output wire [N-1:0] somme,
    output wire         c_out
);

    // carry[i] est la retenue ENTRANTE de l'étage i ; carry[N] est la sortante.
    wire [N:0] carry;
    assign carry[0] = c_in;
    assign c_out    = carry[N];

    genvar i;
    generate
        for (i = 0; i < N; i = i + 1) begin : etage
            full_adder fa (
                .x     (a[i]),
                .y     (b[i]),
                .c_in  (carry[i]),
                .s     (somme[i]),
                .c_out (carry[i+1])
            );
        end
    endgenerate

endmodule
