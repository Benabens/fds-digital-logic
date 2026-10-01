`timescale 1ns / 1ps
//=============================================================================
// bcd_adder — additionneur BCD un chiffre (décimal codé binaire)
//
// En BCD, chaque CHIFFRE décimal 0..9 est codé sur 4 bits ; les six
// combinaisons 1010..1111 (10 à 15) sont INTERDITES. Ce codage est celui des
// afficheurs, des caisses enregistreuses et des calculs monétaires, où l'on
// veut que 0,10 s'écrive exactement et que l'arrondi soit décimal.
//
// LE PROBLÈME. Un additionneur binaire ordinaire raisonne modulo 16, alors que
// le chiffre décimal raisonne modulo 10. Dès que la somme dépasse 9, les deux
// interprétations divergent :
//
//   7 + 5 = 12   binaire : 1100        BCD attendu : retenue 1, chiffre 2
//   9 + 9 = 18   binaire : 1 0010      BCD attendu : retenue 1, chiffre 8
//
// LA CORRECTION « +6 ». L'écart entre les deux bases est exactement 16 - 10 = 6.
// Quand la somme brute dépasse 9, lui ajouter 6 fait déborder le mot de 4 bits
// au bon moment : les 16 « consommés » par le débordement plus les 6 ajoutés
// laissent le reste modulo 10, et la retenue sortante devient la retenue
// DÉCIMALE. Sur l'exemple 7 + 5 :
//
//   0111 + 0101 = 1100 (12 > 9)  ->  1100 + 0110 = 1 0010  ->  retenue 1, 2 ✓
//
// DÉTECTION DU DÉPASSEMENT. Il faut corriger dans deux cas :
//   - la somme brute a déjà débordé sur 4 bits (retenue_brute = 1, donc >= 16) ;
//   - la somme brute vaut 10 à 15, ce qui se lit directement sur les bits :
//         1010..1111  <=>  s3 AND (s2 OR s1)
//     (les valeurs >= 8 dont le rang 4 ou le rang 2 est armé).
//
//   correction = retenue_brute OR ( s[3] AND ( s[2] OR s[1] ) )
//
// et cette correction EST la retenue décimale sortante — inutile de la
// recalculer. Ajouter 6 = 0110 se fait avec un second additionneur dont la
// retenue sortante est ignorée : elle ne peut rien apporter de plus (la somme
// corrigée est toujours < 10 après réduction).
//
// MISE EN CASCADE. Chaîner ces blocs par c_in/c_out donne un additionneur
// décimal de plusieurs chiffres, exactement comme on chaîne des full_adder pour
// former un ripple_carry_adder. Le coût est d'environ deux additionneurs 4 bits
// par chiffre décimal : c'est le prix à payer pour rester en base 10.
//
// Les entrées sont supposées être des chiffres BCD VALIDES (0..9) : le circuit
// n'a aucun comportement garanti sur les codes interdits, et le banc d'essai ne
// balaie donc que les 10 x 10 x 2 = 200 cas légitimes.
//=============================================================================
module bcd_adder (
    input  wire [3:0] a,        // chiffre BCD 0..9
    input  wire [3:0] b,        // chiffre BCD 0..9
    input  wire       c_in,     // retenue décimale entrante
    output wire [3:0] somme,    // chiffre BCD 0..9
    output wire       c_out     // retenue décimale sortante (0 ou 1 dizaine)
);

    // --- Addition binaire ordinaire ---------------------------------------
    wire [3:0] somme_brute;
    wire       retenue_brute;

    ripple_carry_adder #(.N(4)) addition (
        .a     (a),
        .b     (b),
        .c_in  (c_in),
        .somme (somme_brute),
        .c_out (retenue_brute)
    );

    // --- Faut-il corriger ? (somme brute > 9) ------------------------------
    wire depasse_neuf = somme_brute[3] & (somme_brute[2] | somme_brute[1]);
    wire correction   = retenue_brute | depasse_neuf;

    // --- Correction : + 6 si nécessaire, + 0 sinon -------------------------
    // 0110 quand correction vaut 1, 0000 sinon — deux bits suffisent à câbler.
    wire [3:0] six_conditionnel = {1'b0, correction, correction, 1'b0};
    wire       retenue_ignoree;

    ripple_carry_adder #(.N(4)) correction_decimale (
        .a     (somme_brute),
        .b     (six_conditionnel),
        .c_in  (1'b0),
        .somme (somme),
        .c_out (retenue_ignoree)
    );

    assign c_out = correction;

endmodule
