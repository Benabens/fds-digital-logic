`timescale 1ns / 1ps
//=============================================================================
// tb_bcd_adder — banc d'essai de l'additionneur BCD un chiffre.
//
// Balayage EXHAUSTIF du domaine LÉGITIME : 10 x 10 x 2 = 200 vecteurs. Les
// codes 1010..1111 sont interdits en BCD ; les soumettre au circuit n'aurait
// aucun sens puisque la spécification ne dit rien de son comportement dans ce
// cas. Restreindre le balayage au domaine de définition fait partie du contrat
// de vérification.
//
// RÉFÉRENCE INDÉPENDANTE — l'arithmétique DÉCIMALE, pas la correction +6 :
//
//        total   = a + b + c_in            (valeur exacte, 0 à 19)
//        attendu = total modulo 10         (le chiffre)
//        c_out   = total divisé par 10     (la dizaine, 0 ou 1)
//
// Les opérateurs % et / de Verilog n'ont rien à voir avec la logique testée :
// le banc ne sait pas qu'il existe une correction, ni qu'elle vaut 6.
//
// Deux contrôles supplémentaires, importants pour un circuit BCD :
//   - le chiffre produit est TOUJOURS un code BCD valide (<= 9), y compris dans
//     les cas 9+9+1 = 19 qui sollicitent le plus la correction ;
//   - la retenue est bien binaire (0 ou 1), ce qui autorise la mise en cascade
//     de plusieurs chiffres.
//
// Le maximum atteignable est 9 + 9 + 1 = 19, d'où une retenue au plus égale à 1
// et un chiffre au plus égal à 9 : un seul étage de correction suffit toujours.
//=============================================================================
module tb_bcd_adder;

    reg  [3:0] a, b;
    reg        c_in;
    wire [3:0] somme;
    wire       c_out;

    integer ia, ib, ic;
    integer erreurs = 0;
    integer total;
    integer attendu_somme, attendu_cout;

    bcd_adder dut (
        .a(a), .b(b), .c_in(c_in), .somme(somme), .c_out(c_out)
    );

    initial begin
        for (ia = 0; ia <= 9; ia = ia + 1)
        for (ib = 0; ib <= 9; ib = ib + 1)
        for (ic = 0; ic <= 1; ic = ic + 1) begin
            a = ia[3:0]; b = ib[3:0]; c_in = ic[0];
            #1;

            total         = ia + ib + ic;
            attendu_somme = total % 10;
            attendu_cout  = total / 10;

            if (somme !== attendu_somme[3:0]) begin
                erreurs = erreurs + 1;
                if (erreurs < 6)
                    $display("ECHEC chiffre : %0d + %0d + %0d = %0d -> %0d (attendu %0d)",
                             ia, ib, ic, total, somme, attendu_somme);
            end
            if (c_out !== attendu_cout[0]) begin
                erreurs = erreurs + 1;
                if (erreurs < 6)
                    $display("ECHEC retenue : %0d + %0d + %0d = %0d -> c_out=%b (attendu %0d)",
                             ia, ib, ic, total, c_out, attendu_cout);
            end
            if (somme > 4'd9) begin
                erreurs = erreurs + 1;
                if (erreurs < 6)
                    $display("ECHEC code BCD invalide : %0d + %0d + %0d -> %b",
                             ia, ib, ic, somme);
            end
            if (attendu_cout > 1) begin
                erreurs = erreurs + 1;
                if (erreurs < 6)
                    $display("ECHEC hypothese du banc : retenue attendue %0d > 1", attendu_cout);
            end
        end

        if (erreurs == 0) $display("PASS tb_bcd_adder (200/200 vecteurs BCD valides, chiffre modulo 10 + retenue decimale + validite du code)");
        else              $display("ECHEC tb_bcd_adder : %0d erreur(s)", erreurs);
        $finish;
    end

endmodule
