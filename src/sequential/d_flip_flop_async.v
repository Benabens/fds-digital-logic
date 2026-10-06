`timescale 1ns / 1ps
//=============================================================================
// d_flip_flop_async — bascule D sur front montant, avec reset ASYNCHRONE
//
// Même fonction que d_flip_flop.v, mais le reset agit IMMÉDIATEMENT, sans
// attendre l'horloge. Il apparaît donc dans la liste de sensibilité :
//
//     always @(posedge clk or posedge rst)
//
// La liste de sensibilité doit lister le front qui ACTIVE le reset (ici
// posedge, reset actif haut). Le `if (rst)` en tête du bloc lui donne la
// priorité absolue sur l'horloge : c'est le motif exact que les outils de
// synthèse reconnaissent pour câbler l'entrée CLR/PRE de la bascule physique.
//
// Table de transition :
//   rst | clk        | q'
//    1  | quelconque | 0    <- immédiat, aucune horloge requise
//    0  | front ^    | d
//    0  | pas de ^   | q
//
// QUAND PRÉFÉRER L'UN OU L'AUTRE ?
//
//   Reset ASYNCHRONE — à utiliser pour l'initialisation GLOBALE du système :
//     + fonctionne même si l'horloge n'est pas encore là (PLL non verrouillée,
//       horloge arrêtée pour économiser l'énergie, tout début d'alimentation).
//       C'est l'argument décisif : sans lui, un circuit dont l'horloge démarre
//       après le reset peut démarrer dans un état aléatoire.
//     + ne coûte rien en logique combinatoire sur le chemin de données : il
//       utilise une broche dédiée de la bascule.
//     - le RELÂCHEMENT du reset est, lui, dangereux : s'il se produit trop
//       près d'un front d'horloge, on viole le temps de recouvrement
//       (recovery/removal) et la bascule peut devenir MÉTASTABLE. On corrige
//       cela avec un « reset synchronizer » : assertion asynchrone, mais
//       désassertion resynchronisée sur l'horloge.
//     - un parasite (glitch) sur la ligne de reset remet le circuit à zéro
//       sans qu'aucun front d'horloge ne l'ait autorisé.
//
//   Reset SYNCHRONE — à utiliser pour les remises à zéro FONCTIONNELLES
//   (vider un compteur, recommencer une trame) :
//     + purement synchrone : une seule règle temporelle à vérifier, aucune
//       métastabilité liée au reset, analyse de timing (STA) plus simple.
//     + filtre naturellement les parasites plus courts qu'une période.
//     - inefficace si l'horloge est absente ou arrêtée.
//     - ajoute un multiplexeur sur le chemin de données, donc un peu de
//       surface et de délai.
//
//   Règle courante en pratique : reset asynchrone pour l'initialisation à la
//   mise sous tension (relâché de façon synchronisée), reset synchrone pour
//   tout le reste.
//=============================================================================
module d_flip_flop_async (
    input  wire clk,
    input  wire rst,    // reset ASYNCHRONE, actif à l'état haut
    input  wire d,
    output reg  q,
    output wire q_b
);

    // Le reset est dans la liste de sensibilité ET testé en premier :
    // c'est ce qui le rend prioritaire et indépendant de l'horloge.
    always @(posedge clk or posedge rst) begin
        if (rst)
            q <= 1'b0;
        else
            q <= d;
    end

    assign q_b = ~q;

endmodule
