`timescale 1ns / 1ps
//=============================================================================
// mux2to1 — multiplexeur 2 vers 1, paramétré en largeur de bus
//
// Un multiplexeur est un AIGUILLAGE : il choisit laquelle de ses entrées de
// données est recopiée sur sa sortie, en fonction d'une entrée de commande
// (le sélecteur). C'est le dual du démultiplexeur, et la brique universelle du
// chapitre « Combinational building blocks » du cours.
//
//   y = (NOT sel AND d0) OR (sel AND d1)
//
// Table de vérité (W = 1) :
//   sel | y
//    0  | d0
//    1  | d1
//
// POURQUOI ÇA EXISTE. Dans un circuit réel, deux sources ne peuvent pas piloter
// le même fil : il faut un organe qui en élise une. Le mux 2→1 est cet organe.
// On le retrouve partout : l'entrée d'une bascule à chargement conditionnel
// (« load enable »), le choix registre/immédiat à l'entrée d'une UAL, le
// contournement (« forwarding ») dans un pipeline. Le mux 2→1 est aussi
// FONCTIONNELLEMENT COMPLET : avec sel comme variable et des constantes 0/1 sur
// d0/d1 on réalise NOT, AND, OR — c'est le principe des LUT d'un FPGA.
//
// La largeur W est un paramètre : le même module aiguille 1 bit (un signal de
// contrôle) ou 32 bits (un bus de données). Le sélecteur, lui, reste unique et
// commande les W tranches EN PARALLÈLE — d'où la réplication {W{sel}}.
//=============================================================================
module mux2to1 #(
    parameter W = 1
)(
    input  wire [W-1:0] d0,     // recopiée quand sel = 0
    input  wire [W-1:0] d1,     // recopiée quand sel = 1
    input  wire         sel,
    output wire [W-1:0] y
);

    // Forme « somme de produits » explicite : chaque bit de sortie est bien
    // (~sel & d0[i]) | (sel & d1[i]). La réplication diffuse le sélecteur sur
    // les W tranches, ce qui rend visible que le coût matériel croît en O(W).
    assign y = ({W{~sel}} & d0) | ({W{sel}} & d1);

endmodule
