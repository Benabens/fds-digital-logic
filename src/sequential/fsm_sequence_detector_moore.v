`timescale 1ns / 1ps
//=============================================================================
// fsm_sequence_detector_moore — détecteur de la séquence 1011 (machine de MOORE)
//
// L'entrée `serie` reçoit un bit par coup d'horloge. Le circuit lève `detecte`
// dès que les quatre derniers bits reçus valent 1011. Le RECOUVREMENT est
// autorisé : le « 1 » final d'une occurrence peut servir de « 1 » initial à
// l'occurrence suivante. Sur la trame 1011011, deux occurrences sont donc
// reconnues (bits 0..3 puis bits 3..6).
//
// MOORE : la sortie ne dépend QUE de l'état courant. Elle est donc « inscrite »
// dans l'état S4, ce qui coûte un état de plus qu'une machine de Mealy mais
// donne une sortie entièrement synchrone (elle sort d'une bascule, sans
// aucun aléa combinatoire et sans dépendre du moment où `serie` change).
//
// Chaque état mémorise le plus long préfixe de « 1011 » qui est suffixe de ce
// qui a été reçu — c'est exactement la construction d'un automate de recherche
// de motif (cf. chapitre « Finite State Machines » du cours).
//
//   Diagramme d'états (la sortie est notée après le slash) :
//
//              1            0            1            1
//    -->[S0/0] ---> [S1/0] ---> [S2/0] ---> [S3/0] ---> [[S4/1]]
//         rien       "1"        "10"        "101"        "1011"
//
//   Arcs de retour (non dessinés sur la ligne ci-dessus) :
//       S0 --0--> S0     (rien de commencé)
//       S1 --1--> S1     ("11" : on garde le dernier 1)
//       S2 --0--> S0     ("100" : aucun préfixe utile)
//       S3 --0--> S2     ("1010" : le suffixe "10" reste utile)
//       S4 --0--> S2     recouvrement : S4 se comporte comme S1
//       S4 --1--> S1     recouvrement : S4 se comporte comme S1
//
//   Table de transition complète :
//       état | serie=0 | serie=1 | detecte
//       -----+---------+---------+--------
//       S0   |   S0    |   S1    |    0
//       S1   |   S2    |   S1    |    0
//       S2   |   S0    |   S3    |    0
//       S3   |   S2    |   S4    |    0
//       S4   |   S2    |   S1    |    1
//
// CHRONOLOGIE — point à retenir : `detecte` monte pendant le cycle qui SUIT
// l'arrivée du dernier « 1 » de la séquence, puisqu'il faut d'abord franchir
// un front d'horloge pour entrer dans S4.
//=============================================================================
module fsm_sequence_detector_moore (
    input  wire clk,
    input  wire reset,      // synchrone, actif haut
    input  wire serie,      // un bit par coup d'horloge
    output wire detecte     // 1 pendant le cycle qui suit la séquence 1011
);

    // --- encodage des états ---------------------------------------------
    localparam S0 = 3'd0;   // rien de reconnu
    localparam S1 = 3'd1;   // "1"
    localparam S2 = 3'd2;   // "10"
    localparam S3 = 3'd3;   // "101"
    localparam S4 = 3'd4;   // "1011" — état accepteur

    reg [2:0] etat;
    reg [2:0] etat_suivant;

    // --- registre d'état (séquentiel, affectations non bloquantes) -------
    always @(posedge clk) begin
        if (reset)
            etat <= S0;
        else
            etat <= etat_suivant;
    end

    // --- logique de transition (combinatoire, affectations bloquantes) ---
    always @* begin
        case (etat)
            S0:      etat_suivant = serie ? S1 : S0;
            S1:      etat_suivant = serie ? S1 : S2;
            S2:      etat_suivant = serie ? S3 : S0;
            S3:      etat_suivant = serie ? S4 : S2;
            S4:      etat_suivant = serie ? S1 : S2;
            default: etat_suivant = S0;   // états 5..7 inutilisés : repli sûr
        endcase
    end

    // --- sortie de Moore : fonction du SEUL état -------------------------
    assign detecte = (etat == S4);

endmodule
