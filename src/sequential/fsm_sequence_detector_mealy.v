`timescale 1ns / 1ps
//=============================================================================
// fsm_sequence_detector_mealy — détecteur de la séquence 1011 (machine de MEALY)
//
// Même spécification fonctionnelle que fsm_sequence_detector_moore : on cherche
// le motif 1011 dans un flot série, recouvrement autorisé. Seul le STYLE de
// machine change, et c'est tout l'intérêt de comparer les deux fichiers.
//
// MEALY : la sortie est fonction de l'état ET de l'entrée. Il n'y a donc pas
// besoin d'un état accepteur : dès que l'on est dans S3 (= "101" déjà reçu) et
// que l'entrée vaut 1, la séquence est complète et la sortie monte
// immédiatement, dans le même cycle.
//
//   DIFFÉRENCE OBSERVABLE avec la version de Moore — deux points :
//
//   1) MOINS D'ÉTATS. Mealy : 4 états (S0..S3, 2 bascules). Moore : 5 états
//      (S0..S4, 3 bascules). L'état accepteur S4 de Moore ne sert qu'à porter
//      la sortie ; Mealy le remplace par une étiquette sur un arc.
//
//   2) RÉACTION UN CYCLE PLUS TÔT. Mealy lève `detecte` PENDANT le cycle où le
//      dernier « 1 » est présenté ; Moore ne le lève qu'au cycle SUIVANT, après
//      le front d'horloge qui fait entrer dans S4.
//
//         cycle :        ...  n-3  n-2  n-1   n   n+1
//         serie :              1    0    1    1    x
//         Mealy detecte :      0    0    0    1    0     <-- pendant le bit
//         Moore detecte :      0    0    0    0    1     <-- un cycle après
//
//      Contrepartie : la sortie de Mealy est combinatoire, donc elle recopie
//      les aléas et le bruit de `serie` (glitches possibles en cours de cycle)
//      et n'est valide qu'au moment de l'échantillonnage. La sortie de Moore
//      sort d'une bascule et est propre pendant tout le cycle. C'est le
//      compromis classique du chapitre « Finite State Machines ».
//
//   Diagramme d'états (étiquettes « entrée / sortie » sur les arcs) :
//
//              1/0          0/0          1/0          1/1
//    -->[S0] --------> [S1] -----> [S2] -----> [S3] ---------> (retour S1)
//        rien          "1"         "10"        "101"
//
//   Arcs de retour :
//       S0 --0/0--> S0
//       S1 --1/0--> S1
//       S2 --0/0--> S0
//       S3 --0/0--> S2
//       S3 --1/1--> S1     détection ET recouvrement : le "1" consommé
//                          redevient le premier "1" du motif suivant
//
//   Table de transition / sortie :
//       état | serie=0        | serie=1
//       -----+----------------+-----------------
//       S0   | S0, detecte=0  | S1, detecte=0
//       S1   | S2, detecte=0  | S1, detecte=0
//       S2   | S0, detecte=0  | S3, detecte=0
//       S3   | S2, detecte=0  | S1, detecte=1   <-- la seule sortie à 1
//=============================================================================
module fsm_sequence_detector_mealy (
    input  wire clk,
    input  wire reset,      // synchrone, actif haut
    input  wire serie,      // un bit par coup d'horloge
    output reg  detecte     // 1 pendant le cycle du dernier bit de 1011
);

    // --- encodage des états ---------------------------------------------
    localparam S0 = 2'd0;   // rien de reconnu
    localparam S1 = 2'd1;   // "1"
    localparam S2 = 2'd2;   // "10"
    localparam S3 = 2'd3;   // "101"

    reg [1:0] etat;
    reg [1:0] etat_suivant;

    // --- registre d'état (séquentiel, affectations non bloquantes) -------
    always @(posedge clk) begin
        if (reset)
            etat <= S0;
        else
            etat <= etat_suivant;
    end

    // --- transition ET sortie de Mealy (combinatoire, bloquantes) --------
    // Les valeurs par défaut placées en tête garantissent qu'aucun chemin ne
    // laisse `etat_suivant` ou `detecte` sans affectation : pas de verrou
    // (latch) inféré.
    always @* begin
        etat_suivant = S0;
        detecte      = 1'b0;
        case (etat)
            S0: etat_suivant = serie ? S1 : S0;
            S1: etat_suivant = serie ? S1 : S2;
            S2: etat_suivant = serie ? S3 : S0;
            S3: begin
                if (serie) begin
                    etat_suivant = S1;      // recouvrement
                    detecte      = 1'b1;    // sortie fonction de l'ÉTAT et de l'ENTRÉE
                end else begin
                    etat_suivant = S2;
                end
            end
            default: begin
                etat_suivant = S0;
                detecte      = 1'b0;
            end
        endcase
    end

endmodule
