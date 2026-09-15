`timescale 1ns / 1ps
//=============================================================================
// magnitude_comparator — comparateur de grandeur N bits, NON signé
//
// Compare deux nombres binaires non signés a et b et rend les trois mêmes
// indicateurs que la cellule 1 bit : A_eq_B, A_gt_B, A_lt_B. La largeur est un
// paramètre, la structure est décrite une seule fois par generate.
//
// PRINCIPE — LA COMPARAISON LEXICOGRAPHIQUE. Comparer deux nombres écrits en
// base 2, c'est exactement comparer deux mots dans un dictionnaire : on part du
// chiffre de POIDS FORT et on descend tant que les chiffres coïncident ; le
// premier rang où ils diffèrent décide, et tout ce qui se trouve en dessous est
// sans importance. Un seul bit de poids fort pèse plus que tous les bits
// inférieurs réunis (2^k > 2^(k-1) + ... + 2^0), ce qui justifie la règle.
//
// TRADUCTION MATÉRIELLE. On introduit le signal « tous les rangs strictement
// au-dessus de i sont égaux » :
//
//   eq_dessus[N]  = 1                                (rien au-dessus du sommet)
//   eq_dessus[i]  = eq_dessus[i+1] AND eq_bit[i]
//
// C'est un ET préfixe, calculé par une chaîne de N portes. Le rang i n'a le
// droit de trancher que si eq_dessus[i+1] vaut 1 :
//
//   A_gt_B = OU sur i de ( eq_dessus[i+1] AND gt_bit[i] )
//   A_lt_B = OU sur i de ( eq_dessus[i+1] AND lt_bit[i] )
//   A_eq_B = eq_dessus[0]      (aucun rang n'a tranché : les mots sont égaux)
//
// Les termes de ces deux OU sont deux à deux exclusifs : au plus un rang est
// « le premier à différer ». Les trois sorties restent donc mutuellement
// exclusives, comme pour la cellule 1 bit.
//
// COÛT. La chaîne de ET préfixe est linéaire en N, exactement comme la chaîne
// de retenues d'un ripple_carry_adder — et pour la même raison : eq_dessus est
// une récurrence. On peut l'accélérer par le même procédé d'anticipation en
// arbre (voir carry_lookahead_adder4), le ET préfixe étant associatif.
//
// NON SIGNÉ. Ce module compare des ENTIERS NATURELS. Sur des nombres en
// complément à 2, il donnerait un résultat faux (1111 = -1 serait déclaré
// supérieur à 0111 = +7) ; il faudrait d'abord inverser le bit de signe.
//=============================================================================
module magnitude_comparator #(
    parameter N = 8
)(
    input  wire [N-1:0] a,
    input  wire [N-1:0] b,
    output wire         A_eq_B,
    output wire         A_gt_B,
    output wire         A_lt_B
);

    wire [N-1:0] eq_bit;        // comparaison rang par rang
    wire [N-1:0] gt_bit;
    wire [N-1:0] lt_bit;

    wire [N:0]   eq_dessus;     // ET préfixe descendant depuis le poids fort
    wire [N-1:0] gt_terme;      // le rang i est le premier à différer, a[i] > b[i]
    wire [N-1:0] lt_terme;      // idem, a[i] < b[i]

    assign eq_dessus[N] = 1'b1;

    genvar i;
    generate
        for (i = N-1; i >= 0; i = i - 1) begin : rang
            comparator cellule (
                .a      (a[i]),
                .b      (b[i]),
                .A_eq_B (eq_bit[i]),
                .A_gt_B (gt_bit[i]),
                .A_lt_B (lt_bit[i])
            );

            assign eq_dessus[i] = eq_dessus[i+1] & eq_bit[i];
            assign gt_terme[i]  = eq_dessus[i+1] & gt_bit[i];
            assign lt_terme[i]  = eq_dessus[i+1] & lt_bit[i];
        end
    endgenerate

    assign A_eq_B = eq_dessus[0];
    assign A_gt_B = |gt_terme;
    assign A_lt_B = |lt_terme;

endmodule
