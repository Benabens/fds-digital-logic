`timescale 1ns / 1ps
//=============================================================================
// gray_to_binary — conversion code de Gray vers binaire naturel, N bits
//
// Circuit inverse de binary_to_gray. La conversion s'écrit par une RÉCURRENCE
// descendante, du poids fort vers le poids faible :
//
//   binaire[N-1] = gray[N-1]
//   binaire[i]   = binaire[i+1] XOR gray[i]        pour i de N-2 à 0
//
// ce qui revient à un XOR PRÉFIXE : binaire[i] est le XOR de tous les bits de
// Gray d'indice supérieur ou égal à i. On le vérifie sur 3 bits : Gray 110
// donne binaire[2]=1, binaire[1]=1^1=0, binaire[0]=0^0=0, soit 100 = 4 — c'est
// bien la valeur 4 de la table de binary_to_gray.
//
// ASYMÉTRIE DES DEUX SENS. Le sens binaire -> Gray est un XOR de voisins :
// profondeur 1, délai constant. Le sens Gray -> binaire est une chaîne de N-1
// XOR en série : délai LINÉAIRE en N, comme la chaîne de retenues d'un
// ripple_carry_adder. Le XOR étant associatif, on peut là aussi le calculer en
// arbre préfixe (profondeur log2(N)) au prix de plus de portes — même
// compromis que l'anticipation de retenue.
//
// POURQUOI LE CODE DE GRAY ÉVITE LES ALÉAS EN ÉCHANTILLONNAGE ASYNCHRONE
// — c'est la raison d'être de tout ce chapitre.
//
// Les bits d'un bus ne changent jamais rigoureusement en même temps : longueurs
// de pistes, charges et seuils de commutation diffèrent de quelques dizaines de
// picosecondes. Un compteur binaire qui passe de 3 = 011 à 4 = 100 doit faire
// basculer TROIS bits ; pendant la transition, le bus prend des valeurs
// intermédiaires parasites (011 -> 111 -> 101 -> 100, par exemple). Ces états
// fugitifs sont sans conséquence tant qu'on lit le bus une fois stabilisé,
// c'est-à-dire au rythme de la MÊME horloge.
//
// Mais si un second domaine d'horloge échantillonne ce bus ASYNCHRONE, l'instant
// de lecture n'a aucune relation avec l'instant de transition : il peut tomber
// en plein milieu. Le lecteur capture alors 7 ou 5 — des valeurs que le
// compteur n'a JAMAIS eues. Sur un pointeur de FIFO, cela vide ou remplit une
// mémoire à tort : l'erreur est grossière et intermittente, donc redoutable.
//
// Avec le code de Gray, un incrément ne fait basculer QU'UN SEUL bit. Un
// échantillonnage malencontreux attrape ce bit avant ou après sa bascule : on
// lit soit l'ancienne valeur, soit la nouvelle, jamais autre chose. L'erreur se
// réduit à un retard d'un rang, ce qui est toujours acceptable. C'est pourquoi
// les pointeurs des FIFO asynchrones sont codés en Gray, puis reconvertis en
// binaire par ce module une fois passés dans le domaine d'horloge destinataire.
//
// (Même raisonnement pour un codeur de position angulaire : les pistes d'un
// disque optique gravées en Gray ne peuvent pas produire de position aberrante
// quand la tête se trouve à cheval sur deux secteurs.)
//=============================================================================
module gray_to_binary #(
    parameter N = 4
)(
    input  wire [N-1:0] gray,
    output wire [N-1:0] binaire
);

    // Le bit de poids fort est commun aux deux codes ; les autres s'en
    // déduisent de proche en proche.
    assign binaire[N-1] = gray[N-1];

    genvar i;
    generate
        for (i = N-2; i >= 0; i = i - 1) begin : rang
            xor xor_prefixe (binaire[i], binaire[i+1], gray[i]);
        end
    endgenerate

endmodule
