`timescale 1ns / 1ps
//=============================================================================
// decoder4to16 — décodeur 4 vers 16 one-hot, construit HIÉRARCHIQUEMENT
//
// Aucune porte n'est écrite ici : le module est assemblé à partir de DEUX
// decoder3to8. C'est la démonstration de l'intérêt de l'entrée `enable`.
//
// IDÉE. Les 16 sorties se répartissent en deux moitiés de 8. Le bit de POIDS
// FORT a[3] dit dans quelle moitié tombe la ligne cherchée ; les trois bits de
// POIDS FAIBLE a[2:0] disent où elle tombe DANS cette moitié. Il suffit donc
// d'aiguiller la validation :
//
//   décodeur bas  : entrée a[2:0], validé par en AND (NOT a[3])  -> y[7:0]
//   décodeur haut : entrée a[2:0], validé par en AND      a[3]   -> y[15:8]
//
// Le décodeur non validé sort huit zéros, l'autre sort son one-hot : la
// concaténation des deux est bien un one-hot sur 16 lignes. Et si en = 0, les
// deux sont inhibés et les 16 sorties sont nulles.
//
//   en a3 a2..a0 | y
//    0  x   x    | 0000000000000000
//    1  0   k    | un 1 en position k        (0 <= k <= 7)
//    1  1   k    | un 1 en position 8+k
//
// CE QU'IL FAUT RETENIR. Le signal de validation n'est pas un confort : c'est
// le mécanisme de COMPOSITION des décodeurs. On étend de la même façon à 5→32
// avec deux decoder4to16, etc. — chaque bit d'adresse supplémentaire double le
// matériel, ce qui rappelle le coût exponentiel du décodage.
//
// Un vrai décodeur d'adresse mémoire est construit ainsi, étage par étage :
// quelques bits de poids fort choisissent le boîtier, les suivants la banque,
// les derniers la ligne. La hiérarchie du circuit épouse celle de l'adresse.
//=============================================================================
module decoder4to16 (
    input  wire [3:0]  a,       // valeur à décoder
    input  wire        en,      // validation active à l'état haut
    output wire [15:0] y        // one-hot : y[a] = en
);

    // Le bit de poids fort choisit quelle moitié est autorisée à répondre :
    // les deux validations sont mutuellement exclusives quand en = 1.
    wire en_bas  = en & ~a[3];
    wire en_haut = en &  a[3];

    decoder3to8 decodeur_bas (
        .a  (a[2:0]),
        .en (en_bas),
        .y  (y[7:0])
    );

    decoder3to8 decodeur_haut (
        .a  (a[2:0]),
        .en (en_haut),
        .y  (y[15:8])
    );

endmodule
