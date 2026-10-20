`timescale 1ns / 1ps
//=============================================================================
// debouncer — anti-rebond pour bouton-poussoir mécanique
//
// LE PHÉNOMÈNE DE REBOND (« bounce »). Un bouton, un interrupteur ou un relais
// est un contact MÉCANIQUE : deux lames métalliques qui se touchent. À la
// fermeture, les lames rebondissent élastiquement l'une sur l'autre avant de
// s'immobiliser. Électriquement, le signal n'effectue donc pas une transition
// unique 0 -> 1, mais une rafale de transitions parasites qui dure typiquement
// de 1 à 10 ms :
//
//        appui de l'utilisateur
//                |
//                v
//   brut  ______| |_| || |_|||_______________________
//                <-- rebonds -->|<-- signal stable -->
//
// Pour un œil humain, un seul appui. Pour un circuit cadencé à 50 MHz, plusieurs
// CENTAINES DE MILLIERS de fronts. Un compteur branché directement sur le
// bouton avancerait de dizaines de pas par appui. Il faut donc filtrer.
//
// PRINCIPE RETENU — filtre par stabilité temporelle : on ne valide un nouveau
// niveau qu'après l'avoir observé identique pendant STABLE_CYCLES coups
// d'horloge CONSÉCUTIFS. Toute impulsion plus courte que STABLE_CYCLES est
// ignorée. Le compteur est remis à zéro dès que l'entrée redevient égale à la
// sortie validée : c'est ce qui rend le filtre insensible aux rafales.
//
// SYNCHRONISATION. Le bouton est un signal ASYNCHRONE vis-à-vis de `clk` : il
// peut changer pile pendant la fenêtre de setup/hold d'une bascule et la rendre
// métastable. On le fait donc traverser deux bascules en série avant toute
// utilisation (« synchroniseur à deux étages »), ce qui rend la probabilité de
// métastabilité résiduelle négligeable. C'est le complément indispensable du
// chapitre « Sequential Logic » : les contraintes temporelles ne se respectent
// que pour des signaux synchrones.
//
// DIMENSIONNEMENT. STABLE_CYCLES doit couvrir la durée maximale des rebonds :
// STABLE_CYCLES ~= f_horloge * t_rebond. À 50 MHz avec 10 ms de rebonds, il
// faut environ 500 000 cycles. La valeur par défaut est petite pour rester
// simulable en un temps raisonnable.
//
// LATENCE. Un changement stable de `brut` est visible sur `propre` après
// 2 cycles (synchroniseur) + STABLE_CYCLES cycles (filtre).
//=============================================================================
module debouncer #(
    parameter STABLE_CYCLES = 4     // cycles identiques requis pour valider
)(
    input  wire clk,
    input  wire reset,              // synchrone, actif haut
    input  wire brut,               // entrée brute du bouton (avec rebonds)
    output reg  propre,             // niveau validé, sans rebond
    output reg  front_montant,      // impulsion d'un cycle sur 0 -> 1 validé
    output reg  front_descendant    // impulsion d'un cycle sur 1 -> 0 validé
);

    localparam LARGEUR_CPT = (STABLE_CYCLES < 2) ? 1 : $clog2(STABLE_CYCLES);

    reg                   sync0;    // 1er étage du synchroniseur
    reg                   sync1;    // 2e  étage : image synchrone de `brut`
    reg [LARGEUR_CPT-1:0] compteur; // cycles consécutifs où sync1 != propre

    always @(posedge clk) begin
        if (reset) begin
            sync0            <= 1'b0;
            sync1            <= 1'b0;
            propre           <= 1'b0;
            compteur         <= {LARGEUR_CPT{1'b0}};
            front_montant    <= 1'b0;
            front_descendant <= 1'b0;
        end else begin
            // --- synchroniseur à deux étages ---------------------------
            sync0 <= brut;
            sync1 <= sync0;

            // --- les impulsions ne durent qu'un cycle -------------------
            front_montant    <= 1'b0;
            front_descendant <= 1'b0;

            // --- filtre de stabilité -----------------------------------
            if (sync1 == propre) begin
                // l'entrée confirme la sortie : rien à valider
                compteur <= {LARGEUR_CPT{1'b0}};
            end else if (compteur == STABLE_CYCLES - 1) begin
                // le niveau opposé tient depuis assez longtemps : on valide
                propre           <= sync1;
                front_montant    <=  sync1;   // sync1 != propre, donc sync1=1 => montée
                front_descendant <= ~sync1;   //                    sync1=0 => descente
                compteur         <= {LARGEUR_CPT{1'b0}};
            end else begin
                compteur <= compteur + 1'b1;
            end
        end
    end

endmodule
