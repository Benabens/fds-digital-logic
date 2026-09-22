`timescale 1ns / 1ps
//=============================================================================
// decoder3to8 — décodeur 3 vers 8, sortie one-hot, avec validation (enable)
//
// Même principe que decoder2to4, d'un cran plus large : les 3 bits de a sont
// convertis en 8 lignes dont une seule est active, celle d'indice a.
//
//   y[i] = en AND (a == i)        pour i = 0..7
//
//   en  a  | y (binaire, y7 à gauche)
//    0  x  | 00000000
//    1  0  | 00000001
//    1  1  | 00000010
//    1  2  | 00000100
//    1  3  | 00001000
//    1  4  | 00010000
//    1  5  | 00100000
//    1  6  | 01000000
//    1  7  | 10000000
//
// ÉCRITURE. decoder2to4 énumérait ses quatre mintermes à la main ; à huit
// lignes cela devient pénible et fragile. On décrit donc la LOI (« la sortie i
// s'active quand a vaut i ») et une boucle generate produit les huit portes.
// Le circuit obtenu est identique — huit ET à quatre entrées — mais la
// description ne peut plus contenir de faute de recopie.
//
// COÛT. Un décodeur n→2^n a un nombre de sorties EXPONENTIEL en n : 3 bits
// donnent 8 lignes, 10 bits en donneraient 1024. C'est pour cela que les
// décodeurs d'adresse des mémoires réelles sont découpés en deux dimensions
// (décodage ligne × colonne) au lieu d'être plats.
//
// À QUOI ÇA SERT. Traduire un numéro en un signal de sélection : quel registre
// écrire, quel boîtier mémoire activer, quelle micro-opération déclencher à
// partir d'un code opération. La sortie one-hot est précisément le format
// qu'attendent les entrées de validation des blocs en aval.
//=============================================================================
module decoder3to8 (
    input  wire [2:0] a,        // valeur à décoder
    input  wire       en,       // validation active à l'état haut
    output wire [7:0] y         // one-hot : y[a] = en
);

    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : ligne
            // Comparateur d'égalité à une constante = un ET sur les 3 bits,
            // chacun pris droit ou complémenté selon le bit correspondant de i.
            localparam [2:0] valeur = i;
            assign y[i] = en & (a == valeur);
        end
    endgenerate

endmodule
