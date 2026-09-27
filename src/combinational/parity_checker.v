`timescale 1ns / 1ps
//=============================================================================
// parity_checker — détecteur de parité N bits
//
// Compte modulo 2 le nombre de bits à 1 du mot d'entrée :
//
//   parite_impaire = d[N-1] XOR ... XOR d[1] XOR d[0]     (« XOR réduction »)
//   parite_paire   = NOT parite_impaire
//
// Autrement dit parite_impaire vaut 1 quand le mot contient un nombre IMPAIR
// de 1, et parite_paire vaut 1 quand il en contient un nombre PAIR (zéro 1
// compris : le mot nul est de parité paire). Les deux sorties sont toujours
// complémentaires — c'est un choix d'interface, pas une redondance logique :
// selon la convention adoptée, l'émetteur transmet l'une ou l'autre comme bit
// de contrôle.
//
// POURQUOI LE XOR. Le XOR est l'addition modulo 2 : il ignore les retenues.
// Enchaîner des XOR revient donc à compter les 1 en ne gardant que le bit de
// poids faible du compte. C'est le calcul le moins cher qui soit — N-1 portes.
//
// À QUOI ÇA SERT — LA DÉTECTION D'ERREUR. L'émetteur ajoute au mot un bit de
// parité choisi pour que le mot ÉTENDU soit toujours de parité paire. Le
// récepteur recalcule la parité du mot étendu : si elle n'est plus paire, au
// moins un bit a été altéré. Ce code détecte tout nombre IMPAIR d'erreurs, mais
// aucun nombre pair (deux bits inversés se compensent), et il ne CORRIGE rien —
// il signale seulement. C'est le code détecteur le plus simple, ancêtre des
// codes de Hamming vus plus tard dans le cours.
//
// ARBRE OU CHAÎNE. L'opérateur de réduction ^ laisse la synthèse libre de la
// forme : elle produira un ARBRE de XOR de profondeur log2(N), et non une
// chaîne de profondeur N — le XOR étant associatif, exactement comme le ET
// préfixe du comparateur ou les retenues d'un additionneur à anticipation.
//=============================================================================
module parity_checker #(
    parameter N = 8
)(
    input  wire [N-1:0] d,
    output wire         parite_paire,     // 1 si le nombre de 1 est pair
    output wire         parite_impaire    // 1 si le nombre de 1 est impair
);

    assign parite_impaire =  ^d;
    assign parite_paire   = ~^d;

endmodule
