`timescale 1ns / 1ps
//=============================================================================
// d_latch — verrou D transparent, commandé par le NIVEAU de l'enable
//
// Corrige le défaut du sr_latch : une seule entrée de donnée `d`, d'où
// s = d et r = NOT d en interne. s et r ne peuvent donc jamais valoir 1
// ensemble : l'ÉTAT INTERDIT disparaît par construction.
//
// Table de transition (q' = état suivant) :
//   en d | q'   | commentaire
//   0 x  | q    | OPAQUE      : la donnée est mémorisée, d est ignorée
//   1 0  | 0    | TRANSPARENT : q suit d
//   1 1  | 1    | TRANSPARENT : q suit d
//
// NIVEAU vs FRONT — la distinction centrale du chapitre séquentiel.
//
//   VERROU (latch, ce module) : sensible au NIVEAU. Tant que en = 1, le
//   verrou est TRANSPARENT : toute variation de d traverse immédiatement vers
//   q. Il y a un « trou » temporel large — toute la durée où en vaut 1 —
//   pendant lequel la sortie bouge. La valeur finalement mémorisée est celle
//   présente au moment où en RETOMBE à 0.
//
//   BASCULE (flip-flop, cf. d_flip_flop.v) : sensible au FRONT. La donnée
//   n'est échantillonnée qu'à l'instant précis du front montant de
//   l'horloge ; entre deux fronts la sortie est figée, quoi que fasse d.
//
// Conséquence pratique : avec des verrous, un signal peut « traverser » deux
// étages pendant le même coup d'horloge (course, race-through), ce qui casse
// les pipelines. Toute la conception synchrone standard s'appuie donc sur des
// bascules sur front, pas sur des verrous. On construit d'ailleurs une
// bascule maître-esclave en mettant deux verrous D en série sur des niveaux
// d'enable opposés.
//
// STYLE : ce bloc est de la logique de NIVEAU, donc `always @*` avec des
// affectations BLOQUANTES (=). L'absence de branche `else` est ici VOULUE :
// c'est exactement ce qui demande au synthétiseur d'inférer un verrou.
// (Dans un circuit synchrone, un verrou inféré par mégarde est au contraire
// un bug classique.)
//=============================================================================
module d_latch (
    input  wire d,      // donnée
    input  wire en,     // enable : 1 = transparent, 0 = mémorisation
    output reg  q,
    output wire q_b
);

    always @* begin
        if (en)
            q = d;      // pas de `else` : q conserve sa valeur -> verrou
    end

    assign q_b = ~q;

endmodule
