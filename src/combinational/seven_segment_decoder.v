`timescale 1ns / 1ps
//=============================================================================
// seven_segment_decoder — décodeur 4 bits vers afficheur 7 segments, ACTIF HAUT
//
// Traduit une valeur hexadécimale 0..F en la combinaison de segments à allumer
// sur un afficheur. C'est l'exemple canonique de FONCTION COMBINATOIRE DÉFINIE
// PAR UNE TABLE : sept fonctions booléennes de quatre variables, sans formule
// naturelle — on les décrit par leur table de vérité et on laisse la synthèse
// en extraire les équations minimales (tableaux de Karnaugh, chapitre
// « minimisation »).
//
// NOMMAGE DES SEGMENTS (convention universelle, dans le sens horaire depuis le
// haut, le segment central en dernier) :
//
//        aaaa          segments = { a, b, c, d, e, f, g }
//       f    b         soit segments[6] = a  ...  segments[0] = g
//       f    b
//        gggg
//       e    c
//       e    c
//        dddd
//
// ACTIF HAUT : un segment est ALLUMÉ quand son bit vaut 1. C'est la convention
// d'un afficheur à cathode commune (la broche commune est reliée à la masse, un
// niveau haut sur le segment le fait conduire). Un afficheur à ANODE commune
// demande la convention inverse : il suffirait d'inverser les sept sorties —
// l'erreur classique est d'oublier ce détail et d'obtenir un « 8 » troué.
//
// TABLE COMPLÈTE — les 16 valeurs sont couvertes, chiffres ET lettres
// hexadécimales. Les lettres b et d sont dessinées en MINUSCULE : en majuscule,
// « B » serait indiscernable de 8 et « D » de 0.
//
//   d   glyphe    abcdefg      d   glyphe    abcdefg
//   0     0       1111110      8     8       1111111
//   1     1       0110000      9     9       1111011
//   2     2       1101101      A     A       1110111
//   3     3       1111001      B     b       0011111
//   4     4       0110011      C     C       1001110
//   5     5       1011011      D     d       0111101
//   6     6       1011111      E     E       1001111
//   7     7       1110000      F     F       1000111
//
// La table est ici TOTALE : aucune combinaison d'entrée n'est indifférente, donc
// aucun état « don't care » à exploiter pour la minimisation. Une variante ne
// traitant que 0..9 laisserait six cas libres, ce qui simplifierait nettement
// les équations — c'est l'exercice classique du cours sur les tableaux de
// Karnaugh avec conditions indifférentes.
//
// Le bloc always @(*) affecte `segments` dans TOUTES les branches (le case est
// complet et muni d'un default), donc aucun verrou n'est inféré : la discipline
// habituelle de la logique combinatoire décrite en always.
//=============================================================================
module seven_segment_decoder (
    input  wire [3:0] d,            // valeur à afficher, 0 à F
    output reg  [6:0] segments      // { a, b, c, d, e, f, g }, 1 = allumé
);

    always @(*) begin
        case (d)
            4'h0:    segments = 7'b1111110;     // 0
            4'h1:    segments = 7'b0110000;     // 1
            4'h2:    segments = 7'b1101101;     // 2
            4'h3:    segments = 7'b1111001;     // 3
            4'h4:    segments = 7'b0110011;     // 4
            4'h5:    segments = 7'b1011011;     // 5
            4'h6:    segments = 7'b1011111;     // 6
            4'h7:    segments = 7'b1110000;     // 7
            4'h8:    segments = 7'b1111111;     // 8
            4'h9:    segments = 7'b1111011;     // 9
            4'hA:    segments = 7'b1110111;     // A
            4'hB:    segments = 7'b0011111;     // b minuscule
            4'hC:    segments = 7'b1001110;     // C
            4'hD:    segments = 7'b0111101;     // d minuscule
            4'hE:    segments = 7'b1001111;     // E
            4'hF:    segments = 7'b1000111;     // F
            default: segments = 7'b0000000;     // inatteignable : d est sur 4 bits
        endcase
    end

endmodule
