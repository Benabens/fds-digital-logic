`timescale 1ns / 1ps
//=============================================================================
// binary_to_gray — conversion binaire naturel vers code de Gray, N bits
//
// Le code de Gray (ou code binaire RÉFLÉCHI) est une numérotation dans laquelle
// deux valeurs CONSÉCUTIVES ne diffèrent que par UN SEUL bit. Sur 3 bits :
//
//   décimal | binaire | Gray        (le bit qui change est souligné par le
//      0    |   000   |  000         passage d'une ligne à la suivante)
//      1    |   001   |  001
//      2    |   010   |  011
//      3    |   011   |  010
//      4    |   100   |  110
//      5    |   101   |  111
//      6    |   110   |  101
//      7    |   111   |  100
//
// La conversion tient en une ligne :
//
//   gray = binaire XOR (binaire >> 1)
//
// soit, rang par rang, ce que ce module câble littéralement :
//
//   gray[N-1] = binaire[N-1]                    (le poids fort est recopié)
//   gray[i]   = binaire[i+1] XOR binaire[i]     pour i de N-2 à 0
//
// POURQUOI ÇA MARCHE. Passer de k à k+1 en binaire fait basculer une suite de
// 1 de poids faible en 0 et le premier 0 rencontré en 1 — plusieurs bits
// changent d'un coup (011 -> 100 : trois bits). En prenant le XOR de bits
// VOISINS, on ne retient que les FRONTIÈRES entre zones de bits identiques ; or
// l'incrémentation ne déplace qu'une seule de ces frontières. Un seul bit du
// code de Gray change donc.
//
// COÛT ET DÉLAI. N-1 portes XOR, toutes indépendantes : profondeur 1, délai
// CONSTANT quel que soit N. Le circuit inverse (gray_to_binary.v) n'a pas cette
// chance — il repose sur une récurrence.
//=============================================================================
module binary_to_gray #(
    parameter N = 4
)(
    input  wire [N-1:0] binaire,
    output wire [N-1:0] gray
);

    // Le bit de poids fort est commun aux deux codes.
    assign gray[N-1] = binaire[N-1];

    genvar i;
    generate
        for (i = 0; i < N-1; i = i + 1) begin : rang
            xor xor_voisins (gray[i], binaire[i+1], binaire[i]);
        end
    endgenerate

endmodule
