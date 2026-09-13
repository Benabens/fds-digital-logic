`timescale 1ns / 1ps
//=============================================================================
// adder_subtractor — additionneur-soustracteur en complément à 2, N bits
//
// Un seul circuit fait l'addition ET la soustraction, grâce à une propriété du
// complément à 2 :
//
//        a - b  =  a + (-b)  =  a + (NOT b) + 1
//
// Il suffit donc d'inverser b et d'injecter une retenue entrante de 1. Le
// signal de commande `sub` fait les deux à la fois :
//   - sub = 0 : b XOR 0 = b,      c_in = 0  → a + b
//   - sub = 1 : b XOR 1 = NOT b,  c_in = 1  → a - b
//
// DÉBORDEMENT (overflow) — le point le plus subtil du chapitre. En complément
// à 2, la retenue sortante n'indique PAS le débordement. Le débordement signé
// se produit lorsque les deux opérandes ont le même signe et que le résultat a
// le signe opposé, ce qui équivaut à :
//
//        overflow = carry[N] XOR carry[N-1]
//
// (les deux dernières retenues diffèrent). On expose aussi c_out, qui est le
// débordement pertinent pour l'interprétation NON signée.
//=============================================================================
module adder_subtractor #(
    parameter N = 8
)(
    input  wire [N-1:0] a,
    input  wire [N-1:0] b,
    input  wire         sub,        // 0 = addition, 1 = soustraction
    output wire [N-1:0] resultat,
    output wire         c_out,      // retenue/emprunt : débordement non signé
    output wire         overflow,   // débordement signé (complément à 2)
    output wire         zero,
    output wire         negatif
);

    wire [N-1:0] b_effectif = b ^ {N{sub}};   // inversion conditionnelle
    wire [N:0]   carry;

    assign carry[0] = sub;                    // le « +1 » du complément à 2
    assign c_out    = carry[N];

    genvar i;
    generate
        for (i = 0; i < N; i = i + 1) begin : etage
            full_adder fa (
                .x     (a[i]),
                .y     (b_effectif[i]),
                .c_in  (carry[i]),
                .s     (resultat[i]),
                .c_out (carry[i+1])
            );
        end
    endgenerate

    assign overflow = carry[N] ^ carry[N-1];
    assign zero     = (resultat == {N{1'b0}});
    assign negatif  = resultat[N-1];          // bit de signe

endmodule
