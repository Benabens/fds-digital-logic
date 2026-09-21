`timescale 1ns / 1ps
//=============================================================================
// demux1to4 — démultiplexeur 1 vers 4 avec validation (enable)
//
// Opération INVERSE du multiplexeur : une seule donnée d entre, et le sélecteur
// décide sur LAQUELLE des quatre sorties elle est aiguillée. Les trois autres
// sorties sont forcées à 0. L'entrée de validation `en` coupe l'aiguillage :
// quand en = 0, les quatre sorties sont à 0 quoi qu'il arrive.
//
//   en sel | y3 y2 y1 y0
//    0  xx |  0  0  0  0        (démultiplexeur inhibé)
//    1  00 |  0  0  0  d
//    1  01 |  0  0  d  0
//    1  10 |  0  d  0  0
//    1  11 |  d  0  0  0
//
// Équations (un minterme du sélecteur par sortie, mis en ET avec la donnée) :
//
//   y[0] = en AND d AND (NOT sel[1]) AND (NOT sel[0])
//   y[1] = en AND d AND (NOT sel[1]) AND      sel[0]
//   y[2] = en AND d AND      sel[1]  AND (NOT sel[0])
//   y[3] = en AND d AND      sel[1]  AND      sel[0]
//
// LIEN AVEC LE DÉCODEUR. En posant d = 1 on retrouve EXACTEMENT un décodeur
// 2→4 one-hot : un démultiplexeur n'est rien d'autre qu'un décodeur dont la
// donnée sert de second signal de validation. C'est pourquoi les deux circuits
// sont présentés ensemble dans le cours — et pourquoi le même bloc physique
// est souvent réutilisé pour les deux rôles.
//
// À QUOI ÇA SERT. Distribuer un signal unique vers une destination choisie :
// le signal d'écriture d'un banc de registres (« quel registre charge-t-on ? »),
// la sélection de boîtier (chip select) d'un banc de mémoires, ou la
// désérialisation d'un flux vers quatre voies parallèles.
//=============================================================================
module demux1to4 (
    input  wire       d,        // donnée à aiguiller
    input  wire [1:0] sel,      // destination
    input  wire       en,       // validation active à l'état haut
    output wire [3:0] y
);

    wire donnee_validee = en & d;

    assign y[0] = donnee_validee & ~sel[1] & ~sel[0];
    assign y[1] = donnee_validee & ~sel[1] &  sel[0];
    assign y[2] = donnee_validee &  sel[1] & ~sel[0];
    assign y[3] = donnee_validee &  sel[1] &  sel[0];

endmodule
