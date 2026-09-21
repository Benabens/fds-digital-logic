`timescale 1ns / 1ps
//=============================================================================
// decoder2to4 — décodeur 2 vers 4, sortie one-hot, avec validation (enable)
//
// Convertit un nombre binaire de 2 bits en une représentation ONE-HOT : une
// seule des quatre sorties vaut 1, celle dont l'indice est la valeur de a.
// Quand la validation en vaut 0, TOUTES les sorties sont à 0 — ce qui n'est
// pas un code one-hot valide, et c'est justement le but : « aucune ligne
// sélectionnée ».
//
//   en a1 a0 | y3 y2 y1 y0
//    0  x  x |  0  0  0  0
//    1  0  0 |  0  0  0  1
//    1  0  1 |  0  0  1  0
//    1  1  0 |  0  1  0  0
//    1  1  1 |  1  0  0  0
//
// Chaque sortie est un MINTERME des variables d'entrée, validé par en :
//
//   y[0] = en AND (NOT a1) AND (NOT a0)
//   y[1] = en AND (NOT a1) AND      a0
//   y[2] = en AND      a1  AND (NOT a0)
//   y[3] = en AND      a1  AND      a0
//
// C'est le point essentiel du chapitre : un décodeur n→2^n produit TOUS les
// mintermes de n variables. Comme toute fonction booléenne est une somme de
// mintermes, un décodeur suivi d'une porte OU réalise N'IMPORTE QUELLE fonction
// de ses entrées — on choisit simplement quelles sorties on relie au OU. C'est
// la version combinatoire de ce qu'est une table de vérité, et l'ancêtre direct
// des ROM et des PLA.
//
// L'entrée en n'est pas un ornement : c'est elle qui permet de CASCADER les
// décodeurs (voir decoder4to16.v, bâti sur deux decoder3to8 dont les enable
// sont pilotés par le bit de poids fort).
//
// Écriture en portes explicites, pour rendre les mintermes visibles ; les
// modules plus larges de ce dépôt passent ensuite à des formes plus compactes.
//=============================================================================
module decoder2to4 (
    input  wire [1:0] a,        // valeur à décoder
    input  wire       en,       // validation active à l'état haut
    output wire [3:0] y         // one-hot : y[a] = en
);

    assign y[0] = en & ~a[1] & ~a[0];
    assign y[1] = en & ~a[1] &  a[0];
    assign y[2] = en &  a[1] & ~a[0];
    assign y[3] = en &  a[1] &  a[0];

endmodule
