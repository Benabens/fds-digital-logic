`timescale 1ns / 1ps
//=============================================================================
// tb_carry_lookahead_adder4 — banc d'essai de l'additionneur à anticipation.
//
// Balayage EXHAUSTIF : 16 x 16 x 2 = 512 vecteurs, la totalité du domaine.
// Aucun échantillonnage aléatoire n'est nécessaire à cette taille.
//
// Quatre vérifications, toutes fondées sur des références INDÉPENDANTES de la
// logique testée :
//
//   1. {c_out, somme} = a + b + c_in, calculé par l'arithmétique entière de
//      Verilog sur 5 bits.
//   2. p_groupe, DÉFINI par sa sémantique et non par sa formule : « le bloc
//      propage la retenue entrante » signifie que la somme a+b vaut exactement
//      15 — ajouter 1 la fait alors basculer à 16, ajouter 0 la laisse en deçà.
//   3. g_groupe, de même : « le bloc génère une retenue sans aide » signifie
//      a+b >= 16.
//   4. Équivalence fonctionnelle avec ripple_carry_adder #(.N(4)), instancié
//      côte à côte. Les deux structures sont radicalement différentes (chaîne
//      contre sommes de produits) et doivent calculer la même fonction : c'est
//      la démonstration que l'anticipation ne change QUE le délai.
//
// Reprendre les équations c[i] = g[i] + p[i].c[i-1] comme référence n'aurait
// rien prouvé — on aurait comparé la formule à elle-même.
//=============================================================================
module tb_carry_lookahead_adder4;

    reg  [3:0] a, b;
    reg        c_in;

    wire [3:0] somme;
    wire       c_out, p_groupe, g_groupe;

    wire [3:0] somme_rca;
    wire       c_out_rca;

    integer ia, ib, ic;
    integer erreurs = 0;
    reg [4:0] attendu;
    reg       attendu_p, attendu_g;

    carry_lookahead_adder4 dut (
        .a(a), .b(b), .c_in(c_in),
        .somme(somme), .c_out(c_out),
        .p_groupe(p_groupe), .g_groupe(g_groupe)
    );

    // Structure concurrente, pour comparaison fonctionnelle.
    ripple_carry_adder #(.N(4)) rca (
        .a(a), .b(b), .c_in(c_in), .somme(somme_rca), .c_out(c_out_rca)
    );

    initial begin
        for (ia = 0; ia < 16; ia = ia + 1)
        for (ib = 0; ib < 16; ib = ib + 1)
        for (ic = 0; ic < 2;  ic = ic + 1) begin
            a = ia[3:0]; b = ib[3:0]; c_in = ic[0];
            #1;

            attendu   = ia + ib + ic;           // référence arithmétique
            attendu_p = ((ia + ib) == 15);      // propage : 15 + 1 bascule
            attendu_g = ((ia + ib) >= 16);      // génère : déborde seul

            if ({c_out, somme} !== attendu) begin
                erreurs = erreurs + 1;
                if (erreurs < 6)
                    $display("ECHEC somme : %0d + %0d + %0d -> %b_%b (attendu %b)",
                             ia, ib, ic, c_out, somme, attendu);
            end
            if (p_groupe !== attendu_p) begin
                erreurs = erreurs + 1;
                if (erreurs < 6)
                    $display("ECHEC p_groupe : a=%0d b=%0d -> %b (attendu %b)",
                             ia, ib, p_groupe, attendu_p);
            end
            if (g_groupe !== attendu_g) begin
                erreurs = erreurs + 1;
                if (erreurs < 6)
                    $display("ECHEC g_groupe : a=%0d b=%0d -> %b (attendu %b)",
                             ia, ib, g_groupe, attendu_g);
            end
            if ({c_out, somme} !== {c_out_rca, somme_rca}) begin
                erreurs = erreurs + 1;
                if (erreurs < 6)
                    $display("ECHEC divergence CLA/RCA : a=%0d b=%0d c_in=%0d : %b_%b vs %b_%b",
                             ia, ib, ic, c_out, somme, c_out_rca, somme_rca);
            end
        end

        if (erreurs == 0) $display("PASS tb_carry_lookahead_adder4 (512/512 vecteurs, somme + retenue + p/g de groupe + equivalence avec ripple_carry_adder)");
        else              $display("ECHEC tb_carry_lookahead_adder4 : %0d erreur(s)", erreurs);
        $finish;
    end

endmodule
