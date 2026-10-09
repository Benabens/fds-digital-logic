`timescale 1ns / 1ps
//=============================================================================
// register — registre N bits paramétré, avec enable et reset synchrone
//
// Un registre n'est rien d'autre que N bascules D partageant la MÊME horloge,
// le même reset et le même enable. C'est l'élément de stockage de base d'un
// chemin de données : accumulateur, registre d'instruction, étage de
// pipeline, banc de registres d'un processeur.
//
// Table de transition (priorités de haut en bas) :
//   rst en | q'   | commentaire
//    1  x  | 0    | remise à zéro synchrone (priorité maximale)
//    0  0  | q    | GEL : l'horloge continue de battre, mais rien ne change
//    0  1  | d    | chargement de la donnée
//
// L'ENABLE — point important du cours. On ne coupe JAMAIS l'horloge pour
// figer un registre (« clock gating » artisanal) : cela crée des parasites
// sur l'arbre d'horloge et casse l'analyse temporelle. On garde l'horloge
// permanente et on rajoute un MULTIPLEXEUR de rebouclage :
//
//        q' = en ? d : q
//
// C'est exactement ce que décrit le `else if (en)` sans branche `else` : la
// valeur est conservée, ce qui se synthétise en mux de maintien, pas en
// verrou (nous sommes dans un bloc cadencé, pas dans un `always @*`).
//
// STYLE : bloc SÉQUENTIEL -> `always @(posedge clk)` et affectations NON
// BLOQUANTES (<=). Les N bits sont affectés en parallèle, ce que « <= »
// modélise correctement.
//=============================================================================
module register #(
    parameter N = 8
)(
    input  wire         clk,
    input  wire         rst,    // reset synchrone, actif haut
    input  wire         en,     // 1 = charger d, 0 = conserver
    input  wire [N-1:0] d,
    output reg  [N-1:0] q
);

    always @(posedge clk) begin
        if (rst)
            q <= {N{1'b0}};
        else if (en)
            q <= d;
    end

endmodule
