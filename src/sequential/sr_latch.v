`timescale 1ns / 1ps
//=============================================================================
// sr_latch — verrou SR (Set/Reset) à portes NOR croisées
//
// Premier circuit du cours qui MÉMORISE : contrairement à tout le chapitre
// combinatoire, sa sortie ne dépend pas que des entrées actuelles, mais aussi
// de l'état précédent. Le mécanisme est le rebouclage (feedback) : la sortie
// de chaque porte NOR est réinjectée dans l'autre.
//
//   q   = NOR(r, q_b)
//   q_b = NOR(s, q)
//
// Table de transition (q' = état suivant) :
//   s r | q'      | commentaire
//   0 0 | q       | MÉMORISATION : le verrou conserve son état
//   0 1 | 0       | RESET (mise à zéro)
//   1 0 | 1       | SET   (mise à un)
//   1 1 | 0 (!)   | ÉTAT INTERDIT — voir ci-dessous
//
// L'ÉTAT INTERDIT s = r = 1 — le point clé de ce module.
// Deux problèmes distincts, souvent confondus :
//
//  1) Violation de la complémentarité. Les deux NOR ont une entrée à 1, donc
//     q = 0 ET q_b = 0 simultanément. Or q_b est censé valoir NOT q : le nom
//     de la sortie ment, et tout circuit en aval qui suppose q_b = ~q est
//     faux. Ce n'est pas une panne : c'est un contrat d'interface rompu.
//
//  2) La transition 1,1 -> 0,0 est INDÉTERMINÉE. En quittant l'état interdit,
//     les deux portes voient leurs entrées passer à 0 « en même temps » et
//     entrent en compétition (course critique). Le résultat dépend des délais
//     réels de propagation, donc de la fabrication, de la température, de la
//     tension. Le circuit peut aussi osciller ou rester un temps arbitraire
//     dans un état intermédiaire : c'est la MÉTASTABILITÉ.
//
// C'est précisément pour éliminer cette combinaison que l'on construit
// ensuite le verrou D (d_latch) : une seule entrée de donnée, donc s et r
// mutuellement exclusifs par construction, donc l'état interdit devient
// inatteignable.
//
// Description structurelle (primitives `nor`) pour rester au plus près du
// schéma logique du cours.
//=============================================================================
module sr_latch (
    input  wire s,      // set   : met q à 1
    input  wire r,      // reset : met q à 0
    output wire q,
    output wire q_b     // complément de q, SAUF dans l'état interdit s=r=1
);

    // Les deux portes sont croisées : la sortie de l'une alimente l'autre.
    // C'est ce rebouclage — impossible en logique purement combinatoire —
    // qui crée la mémoire.
    nor nor_haut (q,   r, q_b);
    nor nor_bas  (q_b, s, q);

endmodule
