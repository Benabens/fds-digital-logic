`timescale 1ns / 1ps
//=============================================================================
// d_flip_flop — bascule D sur FRONT MONTANT, avec reset SYNCHRONE
//
// L'élément de mémoire fondamental de toute la conception synchrone : le
// registre 1 bit. Contrairement au verrou (d_latch), la donnée n'est
// échantillonnée qu'à l'INSTANT du front montant de clk. Entre deux fronts,
// q est figée quoi que fasse d.
//
// Table de transition :
//   rst d | q'          | commentaire
//    1  x | 0           | remise à zéro, mais SEULEMENT au front montant
//    0  0 | 0           | échantillonnage de d
//    0  1 | 1           | échantillonnage de d
//   (aucune ligne sans front : hors front montant, q' = q)
//
// RESET SYNCHRONE : la condition `if (rst)` est À L'INTÉRIEUR du bloc
// `always @(posedge clk)`. Le reset n'a donc AUCUN effet tant qu'il n'y a pas
// de front d'horloge — une impulsion de reset plus courte qu'une période
// entre deux fronts peut être totalement ignorée. Voir d_flip_flop_async.v
// pour la variante asynchrone et la discussion du choix entre les deux.
//
// STYLE — règle centrale du cours, à ne jamais enfreindre :
//   logique SÉQUENTIELLE  -> always @(posedge clk) + affectations NON
//                            BLOQUANTES (<=)
//   logique COMBINATOIRE  -> always @*             + affectations
//                            BLOQUANTES (=)
// Le « <= » modélise le fait que TOUS les registres échantillonnent leurs
// entrées simultanément, à partir des valeurs d'AVANT le front. Utiliser « = »
// ici créerait une dépendance à l'ordre d'écriture des lignes, et la
// simulation ne correspondrait plus au matériel synthétisé.
//=============================================================================
module d_flip_flop (
    input  wire clk,
    input  wire rst,    // reset synchrone, actif à l'état haut
    input  wire d,
    output reg  q,
    output wire q_b
);

    always @(posedge clk) begin
        if (rst)
            q <= 1'b0;
        else
            q <= d;
    end

    assign q_b = ~q;

endmodule
