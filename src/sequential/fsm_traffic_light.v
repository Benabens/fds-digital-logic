`timescale 1ns / 1ps
//=============================================================================
// fsm_traffic_light — contrôleur de feux de circulation à capteur de véhicule
//
// Machine de MOORE à trois états qui pilote un feu tricolore (vert, orange,
// rouge) sur l'axe principal. Chaque phase dure un nombre PARAMÉTRABLE de coups
// d'horloge, compté par un compteur interne. C'est l'exemple canonique du
// chapitre « Finite State Machines » : une FSM utile n'est presque jamais une
// FSM seule, c'est une FSM + un chemin de données (ici un compteur), et la FSM
// ne regarde du compteur qu'un unique bit de condition (`fin_phase`).
//
//   Rôle du capteur : `capteur` vaut 1 lorsqu'un véhicule attend sur la voie
//   secondaire. Sans véhicule, il est inutile d'interrompre l'axe principal :
//   le feu RESTE au vert indéfiniment, le compteur saturant à DUREE_VERT-1.
//   Dès qu'un véhicule se présente ET que la durée minimale de vert est
//   écoulée, le cycle orange -> rouge -> vert s'enclenche. La durée minimale de
//   vert évite qu'un flot de véhicules sur la voie secondaire ne fasse
//   clignoter le feu en permanence.
//
//   Diagramme d'états :
//
//                 fin_phase & capteur
//        +-------------------------------------+
//        |                                     v
//   +----------+                          +----------+
//   |  S_VERT  |                          | S_ORANGE |
//   |  vert=1  |                          | orange=1 |
//   +----------+                          +----------+
//        ^                                     |
//        |  fin_phase                          |  fin_phase
//        |                                     v
//   +----------+                          +----------+
//   |          |<-------------------------|  S_ROUGE |
//   |                                     | rouge=1  |
//                                         +----------+
//
//   Arcs de maintien (boucles sur soi-même), non dessinés :
//       S_VERT   : tant que !(fin_phase & capteur)
//       S_ORANGE : tant que !fin_phase
//       S_ROUGE  : tant que !fin_phase
//
//   Table de transition :
//       état     | condition               | état suivant | sorties
//       ---------+-------------------------+--------------+------------------
//       S_ROUGE  | fin_phase               | S_VERT       | rouge=1
//       S_VERT   | fin_phase && capteur    | S_ORANGE     | vert=1
//       S_ORANGE | fin_phase               | S_ROUGE      | orange=1
//
// RESET : le reset ramène au ROUGE, et non au vert. C'est le principe de
// l'« état sûr » : si le contrôleur redémarre, on préfère tout arrêter plutôt
// que de laisser passer.
//
// SORTIES DE MOORE : vert/orange/rouge sont des fonctions du seul état, donc
// mutuellement exclusives par construction — un décodeur « one-hot » de l'état.
// C'est la propriété de sûreté que l'on veut absolument (jamais deux feux
// verts en même temps) et le banc d'essai la vérifie à chaque cycle.
//=============================================================================
module fsm_traffic_light #(
    parameter DUREE_VERT   = 8,   // durée minimale de la phase verte (cycles)
    parameter DUREE_ORANGE = 2,   // durée de la phase orange
    parameter DUREE_ROUGE  = 6    // durée de la phase rouge
)(
    input  wire clk,
    input  wire reset,      // synchrone, actif haut
    input  wire capteur,    // 1 = véhicule en attente sur la voie secondaire
    output wire vert,
    output wire orange,
    output wire rouge
);

    // --- dimensionnement du compteur -------------------------------------
    localparam DUREE_MAX_1 = (DUREE_VERT  > DUREE_ORANGE) ? DUREE_VERT  : DUREE_ORANGE;
    localparam DUREE_MAX   = (DUREE_MAX_1 > DUREE_ROUGE)  ? DUREE_MAX_1 : DUREE_ROUGE;
    localparam LARGEUR_CPT = (DUREE_MAX < 2) ? 1 : $clog2(DUREE_MAX);

    // --- encodage des états ----------------------------------------------
    localparam S_ROUGE  = 2'd0;
    localparam S_VERT   = 2'd1;
    localparam S_ORANGE = 2'd2;

    reg [1:0]             etat;
    reg [1:0]             etat_suivant;
    reg [LARGEUR_CPT-1:0] compteur;
    reg [LARGEUR_CPT-1:0] duree_phase;   // durée de la phase en cours
    reg                   fin_phase;     // durée écoulée ?

    // --- registre d'état + compteur (séquentiel, non bloquantes) ---------
    always @(posedge clk) begin
        if (reset) begin
            etat     <= S_ROUGE;                   // état sûr
            compteur <= {LARGEUR_CPT{1'b0}};
        end else begin
            etat <= etat_suivant;
            if (etat_suivant != etat)
                compteur <= {LARGEUR_CPT{1'b0}};   // nouvelle phase : on repart de 0
            else if (!fin_phase)
                compteur <= compteur + 1'b1;
            // sinon : saturation (cas du vert qui attend un véhicule)
        end
    end

    // --- durée de la phase courante et condition de fin (combinatoire) ---
    always @* begin
        case (etat)
            S_VERT:   duree_phase = DUREE_VERT[LARGEUR_CPT-1:0];
            S_ORANGE: duree_phase = DUREE_ORANGE[LARGEUR_CPT-1:0];
            S_ROUGE:  duree_phase = DUREE_ROUGE[LARGEUR_CPT-1:0];
            default:  duree_phase = DUREE_ROUGE[LARGEUR_CPT-1:0];
        endcase
        fin_phase = (compteur >= duree_phase - 1'b1);
    end

    // --- logique de transition (combinatoire, bloquantes) ----------------
    always @* begin
        case (etat)
            S_ROUGE:  etat_suivant = fin_phase ? S_VERT : S_ROUGE;
            S_VERT:   etat_suivant = (fin_phase && capteur) ? S_ORANGE : S_VERT;
            S_ORANGE: etat_suivant = fin_phase ? S_ROUGE : S_ORANGE;
            default:  etat_suivant = S_ROUGE;   // code d'état 3 inutilisé
        endcase
    end

    // --- sorties de Moore : décodage one-hot de l'état -------------------
    assign vert   = (etat == S_VERT);
    assign orange = (etat == S_ORANGE);
    assign rouge  = (etat == S_ROUGE);

endmodule
