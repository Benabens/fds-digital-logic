`timescale 1ns / 1ps
//=============================================================================
// absolute_difference — écart absolu |a - b| sur N bits NON signés
//
// Rend la distance entre deux entiers naturels. Le résultat tient toujours sur
// N bits : si a et b sont dans [0, 2^N-1], leur écart l'est aussi. Il n'y a donc
// JAMAIS de débordement — c'est la propriété qui rend ce bloc agréable, et qui
// explique sa présence partout où l'on mesure un écart (comparaison d'images
// SAD, seuillage de capteur, distance de Manhattan).
//
// LA DIFFICULTÉ. Une soustraction non signée a - b déborde quand a < b : on
// obtiendrait le complément à 2 du bon résultat (par exemple 3 - 5 = 11110 sur
// 5 bits, soit 30, et non 2). Calculer la valeur absolue impose donc de
// SAVOIR AVANT de soustraire lequel des deux opérandes est le plus grand.
//
// CONSTRUCTION EN TROIS TEMPS, chacun réutilisant un bloc déjà écrit :
//
//   1. magnitude_comparator décide qui est le plus grand ;
//   2. deux multiplexeurs remettent les opérandes dans l'ordre — grand reçoit
//      max(a,b), petit reçoit min(a,b) ;
//   3. ripple_carry_adder calcule grand - petit en complément à 2, selon
//      l'identité déjà utilisée dans adder_subtractor :
//
//          grand - petit = grand + (NOT petit) + 1
//
// La soustraction porte sur des opérandes réordonnés, donc grand >= petit : le
// résultat est positif par construction et la retenue sortante de l'additionneur
// vaut toujours 1 (pas d'emprunt). Le banc d'essai vérifie cette invariante.
//
// À NOTER : le chemin critique traverse le comparateur PUIS l'additionneur,
// les deux étant des structures à chaîne. C'est le prix de la réutilisation ;
// une version optimisée calculerait a-b et b-a en parallèle et choisirait
// ensuite, échangeant de la surface contre du délai.
//=============================================================================
module absolute_difference #(
    parameter N = 8
)(
    input  wire [N-1:0] a,
    input  wire [N-1:0] b,
    output wire [N-1:0] difference     // |a - b|
);

    wire a_egal_b;
    wire a_sup_b;
    wire a_inf_b;

    magnitude_comparator #(.N(N)) cmp (
        .a      (a),
        .b      (b),
        .A_eq_B (a_egal_b),
        .A_gt_B (a_sup_b),
        .A_lt_B (a_inf_b)
    );

    // Réordonnancement : si a < b on échange, sinon on garde l'ordre.
    wire [N-1:0] grand = a_inf_b ? b : a;
    wire [N-1:0] petit = a_inf_b ? a : b;

    // grand - petit = grand + NOT(petit) + 1
    wire retenue_sortante;      // vaut 1 (aucun emprunt) puisque grand >= petit

    ripple_carry_adder #(.N(N)) soustracteur (
        .a     (grand),
        .b     (~petit),
        .c_in  (1'b1),
        .somme (difference),
        .c_out (retenue_sortante)
    );

endmodule
