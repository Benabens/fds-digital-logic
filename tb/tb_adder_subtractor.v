`timescale 1ns / 1ps
//=============================================================================
// tb_adder_subtractor — banc d'essai de l'additionneur-soustracteur C2.
//
// Testé en 5 bits pour garder un balayage exhaustif raisonnable
// (32 x 32 x 2 = 2048 vecteurs). Trois références INDÉPENDANTES sont
// recalculées à chaque vecteur :
//   - le résultat, via l'arithmétique entière de Verilog tronquée à N bits ;
//   - le débordement SIGNÉ, via la comparaison du résultat exact en entiers
//     signés avec l'intervalle représentable [-2^(N-1), 2^(N-1)-1] ;
//   - le débordement NON SIGNÉ (c_out).
//
// Recalculer le débordement à partir de sa DÉFINITION (« le résultat exact
// sort-il de l'intervalle ? ») plutôt qu'avec la formule carry[N]^carry[N-1]
// est essentiel : sinon on ne ferait que vérifier que la formule est égale à
// elle-même.
//=============================================================================
module tb_adder_subtractor;

    localparam N = 5;

    reg  [N-1:0] a, b;
    reg          sub;
    wire [N-1:0] resultat;
    wire         c_out, overflow, zero, negatif;

    integer ia, ib, is;
    integer erreurs = 0;
    integer a_signe, b_signe, exact;
    reg [N:0] attendu_nonsigne;
    reg       attendu_ovf;

    adder_subtractor #(.N(N)) dut (
        .a(a), .b(b), .sub(sub), .resultat(resultat),
        .c_out(c_out), .overflow(overflow), .zero(zero), .negatif(negatif)
    );

    initial begin
        for (ia = 0; ia < (1 << N); ia = ia + 1)
        for (ib = 0; ib < (1 << N); ib = ib + 1)
        for (is = 0; is < 2; is = is + 1) begin
            a = ia[N-1:0]; b = ib[N-1:0]; sub = is[0];
            #1;

            // --- référence non signée -------------------------------------
            attendu_nonsigne = sub ? (a + ((~b) & {N{1'b1}}) + 1) : (a + b);

            // --- référence signée : valeur exacte, hors intervalle ? -------
            a_signe = a[N-1] ? (a - (1 << N)) : a;
            b_signe = b[N-1] ? (b - (1 << N)) : b;
            exact   = sub ? (a_signe - b_signe) : (a_signe + b_signe);
            attendu_ovf = (exact > ((1 << (N-1)) - 1)) || (exact < -(1 << (N-1)));

            if (resultat !== attendu_nonsigne[N-1:0]) begin
                erreurs = erreurs + 1;
                if (erreurs < 6)
                    $display("ECHEC resultat : a=%0d b=%0d sub=%b -> %b (attendu %b)",
                             a, b, sub, resultat, attendu_nonsigne[N-1:0]);
            end
            if (overflow !== attendu_ovf) begin
                erreurs = erreurs + 1;
                if (erreurs < 6)
                    $display("ECHEC overflow : a=%0d b=%0d sub=%b exact=%0d -> ovf=%b (attendu %b)",
                             a_signe, b_signe, sub, exact, overflow, attendu_ovf);
            end
            if (zero !== (resultat == 0)) begin
                erreurs = erreurs + 1;
            end
            if (negatif !== resultat[N-1]) begin
                erreurs = erreurs + 1;
            end
        end

        if (erreurs == 0) $display("PASS tb_adder_subtractor (2048/2048 vecteurs, resultat + overflow + drapeaux)");
        else              $display("ECHEC tb_adder_subtractor : %0d erreur(s)", erreurs);
        $finish;
    end

endmodule
