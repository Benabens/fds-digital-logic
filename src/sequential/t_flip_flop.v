`timescale 1ns / 1ps
//=============================================================================
// t_flip_flop — bascule T (Toggle), CONSTRUITE à partir d'une bascule D
//
// La bascule T bascule (change d'état) à chaque front montant lorsque t = 1,
// et conserve son état lorsque t = 0. C'est la brique élémentaire des
// compteurs binaires : un étage T dont l'entrée t est toujours à 1 divise la
// fréquence de son horloge par deux.
//
// Table de transition :
//   rst t | q'      | commentaire
//    1  x | 0       | reset synchrone
//    0  0 | q       | mémorisation
//    0  1 | NOT q   | BASCULEMENT
//
// CONSTRUCTION À PARTIR D'UNE BASCULE D — la démarche classique du cours :
// on écrit l'état suivant voulu comme une fonction combinatoire de l'état
// courant et des entrées, puis on branche cette fonction sur l'entrée D.
//
//        q' = t . NOT(q)  +  NOT(t) . q  =  t XOR q
//
// D'où un simple XOR devant une bascule D. On voit ici concrètement la
// structure de toute machine séquentielle synchrone :
//
//        [ logique COMBINATOIRE d'état suivant ]  ->  [ REGISTRE ]  -> etat
//                          ^                                           |
//                          +-------------------------------------------+
//
// STYLE : la fonction d'état suivant est purement combinatoire, donc décrite
// par un `assign` (équivalent d'un `always @*` avec affectation bloquante).
// Toute la mémorisation, et donc le `<=`, est confinée dans d_flip_flop.
//=============================================================================
module t_flip_flop (
    input  wire clk,
    input  wire rst,    // reset synchrone
    input  wire t,      // 1 = basculer, 0 = conserver
    output wire q,
    output wire q_b
);

    wire d_interne;

    // Logique d'état suivant : combinatoire, rebouclée sur la sortie q.
    assign d_interne = t ^ q;

    d_flip_flop bascule (
        .clk (clk),
        .rst (rst),
        .d   (d_interne),
        .q   (q),
        .q_b (q_b)
    );

endmodule
