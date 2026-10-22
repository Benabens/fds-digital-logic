`timescale 1ns / 1ps
//=============================================================================
// ram_sync — mémoire vive synchrone paramétrée (1 port lecture/écriture)
//
// Modèle de la mémoire telle qu'elle existe réellement dans un FPGA ou un ASIC :
// un BLOC RAM. Contrairement au banc de registres du même répertoire, la
// lecture N'EST PAS combinatoire — et cette différence est fondamentale.
//
//   POURQUOI LA LECTURE EST-ELLE SYNCHRONE ?
//   Une RAM dense n'est pas faite de bascules : c'est une matrice de cellules
//   (6 transistors en SRAM) partageant des lignes de bit. Lire consiste à
//   pré-charger ces lignes puis à laisser un amplificateur de lecture (« sense
//   amplifier ») détecter un déséquilibre de tension minuscule. Cette opération
//   analogique demande un temps garanti, que l'on borne en enregistrant
//   l'adresse et la donnée lue dans des bascules cadencées par l'horloge. D'où
//   le registre de sortie, et d'où la LATENCE D'UN CYCLE :
//
//     cycle n   : on présente `adresse`
//     cycle n+1 : `donnee_lecture` contient memoire[adresse]
//
//   C'est la raison pour laquelle un processeur pipeliné consacre un étage
//   entier (« MEM ») à l'accès mémoire, alors que la lecture du banc de
//   registres se fait « gratuitement » à l'intérieur de l'étage de décodage.
//
//   POLITIQUE READ-FIRST (lecture avant écriture).
//   Si l'on lit et écrit la MÊME adresse dans le même cycle, ce module renvoie
//   l'ANCIEN contenu. C'est une conséquence directe des affectations non
//   bloquantes : les deux <= lisent la mémoire dans son état d'avant le front,
//   puis écrivent. Les blocs RAM réels offrent en général trois modes
//   (read-first, write-first, no-change) ; le choix n'est pas anodin, il change
//   le résultat du programme. Le banc d'essai vérifie explicitement ce point.
//
//   Écrire les deux opérations dans UN SEUL bloc always est ce qui permet à
//   l'outil de synthèse de reconnaître le motif et d'instancier un vrai bloc
//   RAM plutôt que PROFONDEUR x LARGEUR bascules.
//=============================================================================
module ram_sync #(
    parameter LARGEUR     = 8,   // largeur d'un mot en bits
    parameter PROFONDEUR  = 16,  // nombre de mots (puissance de 2)
    parameter LARGEUR_ADR = $clog2(PROFONDEUR)   // dérivé : ne pas surcharger
)(
    input  wire                   clk,
    input  wire                   ecriture_en,
    input  wire [LARGEUR_ADR-1:0] adresse,
    input  wire [LARGEUR-1:0]     donnee_ecriture,
    output reg  [LARGEUR-1:0]     donnee_lecture   // valide au cycle SUIVANT
);

    reg [LARGEUR-1:0] memoire [0:PROFONDEUR-1];

    always @(posedge clk) begin
        if (ecriture_en)
            memoire[adresse] <= donnee_ecriture;

        // registre de sortie : lecture « read-first » grâce au <=
        donnee_lecture <= memoire[adresse];
    end

endmodule
