`timescale 1ns / 1ps
//=============================================================================
// rom — mémoire morte combinatoire paramétrée
//
// Une ROM est, du point de vue logique, une simple FONCTION COMBINATOIRE : à
// chaque adresse correspond une valeur figée, sans horloge ni état. C'est le
// pont entre le chapitre « Combinational Logic » et le chapitre « Memory » :
//
//   - vue « mémoire »  : un tableau de PROFONDEUR mots de LARGEUR bits ;
//   - vue « logique »  : LARGEUR fonctions booléennes de LARGEUR_ADR variables,
//                        données par leur table de vérité complète.
//
// Ces deux vues sont interchangeables, et c'est un résultat important : TOUTE
// fonction combinatoire de n entrées et m sorties peut se réaliser par une ROM
// de 2^n mots de m bits. Une ROM est donc un décodeur d'adresse (le décodeur
// n vers 2^n du répertoire combinational/) suivi d'une matrice de OU câblés.
// Le coût est exponentiel en n, d'où l'intérêt de la minimisation logique quand
// la fonction est régulière — mais l'approche par table reste imbattable pour
// les fonctions irrégulières : tables de codage 7 segments, sinus tabulé,
// microcode d'une unité de contrôle, vecteur de démarrage d'un processeur.
//
// SORTIE COMBINATOIRE : `donnee` suit `adresse` sans horloge (temps de
// propagation seulement). Un FPGA réel imposerait souvent un registre de
// sortie, comme dans ram_sync.v.
//
// CONTENU DE DÉMONSTRATION : la table des carrés, contenu[i] = i*i, tronquée à
// LARGEUR bits. Avec les valeurs par défaut (16 mots de 8 bits) elle va de 0 à
// 225 et tient donc exactement dans un octet. En pratique, on ne code pas le
// contenu à la main : on le charge depuis un fichier avec
//     $readmemh("contenu.hex", contenu);
// ce qui permet de changer le programme d'une ROM sans retoucher le RTL.
//=============================================================================
module rom #(
    parameter LARGEUR     = 8,   // largeur d'un mot en bits
    parameter PROFONDEUR  = 16,  // nombre de mots (puissance de 2)
    parameter LARGEUR_ADR = $clog2(PROFONDEUR)   // dérivé : ne pas surcharger
)(
    input  wire [LARGEUR_ADR-1:0] adresse,
    output wire [LARGEUR-1:0]     donnee
);

    reg [LARGEUR-1:0] contenu [0:PROFONDEUR-1];
    integer           i;

    // --- gravure du contenu (l'équivalent du masque d'un vrai circuit) ---
    initial begin
        for (i = 0; i < PROFONDEUR; i = i + 1)
            contenu[i] = i * i;   // table des carrés, tronquée à LARGEUR bits
    end

    // --- décodage purement combinatoire ----------------------------------
    assign donnee = contenu[adresse];

endmodule
