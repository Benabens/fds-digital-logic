`timescale 1ns / 1ps
//=============================================================================
// ring_counter — compteur en anneau N bits, avec variante de Johnson
//
// Un compteur en anneau n'est pas un compteur binaire : c'est un REGISTRE À
// DÉCALAGE dont la sortie est rebouclée sur l'entrée. Il n'y a donc aucune
// logique combinatoire de comptage, juste N bascules et un fil de retour. C'est
// le circuit séquentiel le plus simple qui existe après le registre lui-même.
//
//   MODE ANNEAU (JOHNSON = 0) — rebouclage direct q[N-1] -> q[0].
//   L'état initial contient un seul « 1 » qui tourne indéfiniment :
//
//       0001 -> 0010 -> 0100 -> 1000 -> 0001 -> ...        (N états, ici 4)
//
//   Propriété clé : la sortie est en permanence « one-hot ». Chaque bit q[i]
//   est directement un signal de séquencement (« c'est le tour de l'étage i »)
//   sans aucun décodeur : on économise le décodeur binaire -> one-hot au prix
//   de bascules supplémentaires. C'est exactement le compromis surface/vitesse
//   discuté au chapitre « Sequential Logic ».
//
//   MODE JOHNSON (JOHNSON = 1) — « anneau tordu » (twisted ring) : on reboucle
//   le COMPLÉMENT du bit de poids fort. Partant de zéro :
//
//       0000 -> 0001 -> 0011 -> 0111 -> 1111 -> 1110 -> 1100 -> 1000 -> 0000
//
//   On obtient 2N états au lieu de N avec le même nombre de bascules, et deux
//   états successifs ne diffèrent que d'UN SEUL bit (code de Gray) : aucun aléa
//   de décodage, ce qui est précieux pour piloter des signaux asynchrones.
//   Cette propriété fait du compteur de Johnson la base des FIFO asynchrones.
//
//   Comparaison, à N bascules :
//       compteur binaire : 2^N états, logique combinatoire de report, plusieurs
//                          bits changent à la fois (aléas de décodage)
//       anneau           :   N états, aucune logique, sortie one-hot
//       Johnson          :  2N états, un inverseur, un seul bit change
//
// ÉTATS PARASITES. Si le registre démarre dans un état illégal (deux « 1 » en
// mode anneau), il y reste : l'anneau n'est pas auto-correcteur. D'où
// l'importance du reset, qui charge explicitement l'état initial légal.
//
// Remarque : ce module suppose N >= 2.
//=============================================================================
module ring_counter #(
    parameter N       = 8,   // nombre de bascules (N >= 2)
    parameter JOHNSON = 0    // 0 = anneau simple, 1 = anneau tordu (Johnson)
)(
    input  wire         clk,
    input  wire         reset,   // synchrone, actif haut : charge l'état initial
    input  wire         enable,  // 0 = gel du compteur
    output wire [N-1:0] q
);

    reg [N-1:0] registre;

    always @(posedge clk) begin
        if (reset)
            // anneau  : un unique « 1 » en position 0
            // Johnson : tout à zéro (l'anneau tordu se remplit tout seul)
            registre <= (JOHNSON != 0) ? {N{1'b0}}
                                       : {{(N-1){1'b0}}, 1'b1};
        else if (enable)
            // décalage vers les poids forts ; seul le bit réinjecté diffère
            registre <= (JOHNSON != 0) ? {registre[N-2:0], ~registre[N-1]}
                                       : {registre[N-2:0],  registre[N-1]};
    end

    assign q = registre;

endmodule
