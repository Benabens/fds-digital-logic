`timescale 1ns / 1ps
//=============================================================================
// carry_lookahead_adder4 — additionneur 4 bits à ANTICIPATION de retenue
//
// Même fonction que ripple_carry_adder #(.N(4)) — a + b + c_in — mais une
// structure entièrement différente, et c'est tout l'intérêt du module : les
// retenues ne sont plus calculées de proche en proche, elles sont TOUTES
// calculées en parallèle à partir des entrées.
//
// GÉNÉRATION ET PROPAGATION. Pour chaque rang i on définit deux signaux qui ne
// dépendent QUE de a[i] et b[i], donc disponibles immédiatement :
//
//   g[i] = a[i] AND b[i]   « génère » : le rang i crée une retenue à lui seul
//                            (1+1 = 10), quelle que soit la retenue entrante.
//   p[i] = a[i] XOR b[i]   « propage » : le rang i laisse passer la retenue
//                            entrante telle quelle (exactement un des deux
//                            bits vaut 1, donc 1+0+c = 1+c).
//
// La récurrence de la retenue s'écrit alors, sans aucune ambiguïté :
//
//   c[i+1] = g[i] OR (p[i] AND c[i])
//
// « il y a une retenue sortante si le rang la génère, ou s'il la propage ».
// C'est encore une récurrence — et une récurrence, matériellement, c'est une
// chaîne. L'idée de l'anticipation est de la DÉROULER par substitution :
//
//   c[1] = g0 + p0.c0
//   c[2] = g1 + p1.g0 + p1.p0.c0
//   c[3] = g2 + p2.g1 + p2.p1.g0 + p2.p1.p0.c0
//   c[4] = g3 + p3.g2 + p3.p2.g1 + p3.p2.p1.g0 + p3.p2.p1.p0.c0
//
// Chaque ligne est une somme de produits : DEUX niveaux de portes (un étage de
// ET, un étage de OU), identiques pour toutes les retenues. Les quatre retenues
// apparaissent donc EN MÊME TEMPS. La somme s'obtient ensuite en un XOR :
//
//   s[i] = p[i] XOR c[i]
//
// POURQUOI O(N) DEVIENT O(log N). Dans ripple_carry_adder, c[4] attend c[3],
// qui attend c[2]... : le chemin critique traverse les N additionneurs complets
// en série, d'où un délai LINÉAIRE en N. Ici, sur un bloc de 4 bits, le délai
// est CONSTANT (3 niveaux : p/g, puis ET, puis OU) — au prix de portes plus
// larges (le dernier OU a 5 entrées, et cela empirerait vite au-delà de 4 bits :
// c'est pourquoi on s'arrête à des blocs de 4).
//
// Le passage à O(log N) se fait en EMPILANT ces blocs. Le bloc entier possède
// lui aussi une paire (génération, propagation), exposée ici en sortie :
//
//   p_groupe = p3.p2.p1.p0                       le bloc propage la retenue
//   g_groupe = g3 + p3.g2 + p3.p2.g1 + p3.p2.p1.g0   le bloc génère une retenue
//
// Ces deux signaux obéissent EXACTEMENT à la même récurrence que g[i] et p[i] :
// un second étage d'anticipation peut donc traiter quatre blocs de 4 bits comme
// s'il s'agissait de quatre rangs, un troisième étage traiter quatre groupes de
// 16 bits, etc. Avec un niveau de hiérarchie tous les facteurs 4, la profondeur
// de l'arbre — donc le délai — croît comme log(N), au lieu de N. C'est la même
// idée d'arbre que dans mux_param : on échange de la surface contre du délai.
//
//   N bits |  ripple (N étages en série) | anticipation hiérarchique
//     4    |            4                |   1 bloc
//    16    |           16                |   2 niveaux
//    64    |           64                |   3 niveaux
//=============================================================================
module carry_lookahead_adder4 (
    input  wire [3:0] a,
    input  wire [3:0] b,
    input  wire       c_in,
    output wire [3:0] somme,
    output wire       c_out,
    output wire       p_groupe,   // le bloc propage-t-il une retenue entrante ?
    output wire       g_groupe    // le bloc génère-t-il une retenue ?
);

    // --- Étage 1 : signaux locaux, calculés en parallèle sur les entrées ----
    wire [3:0] g = a & b;       // génération
    wire [3:0] p = a ^ b;       // propagation

    // --- Étage 2 : les quatre retenues, en sommes de produits --------------
    // c[i] est la retenue ENTRANTE du rang i (même convention que
    // ripple_carry_adder) ; aucune ne dépend d'une autre.
    wire [4:0] c;

    assign c[0] = c_in;
    assign c[1] = g[0]
                | (p[0] & c_in);
    assign c[2] = g[1]
                | (p[1] & g[0])
                | (p[1] & p[0] & c_in);
    assign c[3] = g[2]
                | (p[2] & g[1])
                | (p[2] & p[1] & g[0])
                | (p[2] & p[1] & p[0] & c_in);
    assign c[4] = g[3]
                | (p[3] & g[2])
                | (p[3] & p[2] & g[1])
                | (p[3] & p[2] & p[1] & g[0])
                | (p[3] & p[2] & p[1] & p[0] & c_in);

    // --- Étage 3 : la somme, un simple XOR une fois les retenues connues ---
    assign somme = p ^ c[3:0];
    assign c_out = c[4];

    // --- Signaux de groupe : la brique d'un second niveau d'anticipation ---
    assign p_groupe = &p;
    assign g_groupe = g[3]
                    | (p[3] & g[2])
                    | (p[3] & p[2] & g[1])
                    | (p[3] & p[2] & p[1] & g[0]);

endmodule
