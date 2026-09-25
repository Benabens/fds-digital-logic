`timescale 1ns / 1ps
//=============================================================================
// encoder8to3 — encodeur 8 vers 3, entrée one-hot, avec sortie « valide »
//
// Opération INVERSE du décodeur 3→8 : on présente huit lignes dont UNE SEULE
// est censée être active, et le circuit rend le NUMÉRO de cette ligne, codé
// en binaire sur 3 bits. On repasse ainsi d'une représentation one-hot
// (8 fils, une information) à une représentation binaire compacte (3 fils).
//
//   d           | q   valide
//   00000000    | 000    0      <- aucune ligne active
//   00000001    | 000    1
//   00000010    | 001    1
//   00000100    | 010    1
//   00001000    | 011    1
//   00010000    | 100    1
//   00100000    | 101    1
//   01000000    | 110    1
//   10000000    | 111    1
//
// ÉQUATIONS. Le bit k de la sortie vaut 1 pour les indices dont l'écriture
// binaire a un 1 en position k. Il suffit donc d'un OU sur les entrées
// correspondantes :
//
//   q[0] = d1 OR d3 OR d5 OR d7        (indices impairs)
//   q[1] = d2 OR d3 OR d6 OR d7        (indices dont le bit 1 est à 1)
//   q[2] = d4 OR d5 OR d6 OR d7        (indices >= 4)
//
// POURQUOI UNE SORTIE « VALIDE ». L'entrée nulle et l'entrée d = 00000001
// donnent toutes deux q = 000 : l'encodeur seul ne sait pas les distinguer.
// Le drapeau valide = OR de toutes les entrées lève l'ambiguïté ; sans lui,
// « rien de sélectionné » serait confondu avec « ligne 0 sélectionnée ». C'est
// l'exemple canonique du cours sur les sorties d'état accompagnant un résultat.
//
// LIMITE ASSUMÉE. Si plusieurs lignes sont actives à la fois, le circuit rend
// le OU BIT À BIT de leurs indices, qui n'a en général aucun sens (d3 et d4
// actives donnent q = 011 | 100 = 111, c'est-à-dire 7). L'encodeur simple
// suppose donc l'entrée one-hot, ce qui n'est pas toujours garanti dans un
// système réel — d'où l'encodeur PRIORITAIRE (voir priority_encoder8.v), qui
// définit proprement le comportement dans tous les cas.
//
// À QUOI ÇA SERT. Compresser un jeu de lignes de sélection en un numéro :
// identifier laquelle des 8 touches d'un clavier est enfoncée, quel canal a
// gagné un arbitrage, ou quelle position occupe le premier 1 d'un mot.
//=============================================================================
module encoder8to3 (
    input  wire [7:0] d,        // supposée one-hot
    output wire [2:0] q,        // numéro de la ligne active
    output wire       valide    // 0 si aucune ligne n'est active
);

    assign q[0] = d[1] | d[3] | d[5] | d[7];
    assign q[1] = d[2] | d[3] | d[6] | d[7];
    assign q[2] = d[4] | d[5] | d[6] | d[7];

    assign valide = |d;         // OU de réduction sur les 8 entrées

endmodule
