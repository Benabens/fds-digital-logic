`timescale 1ns / 1ps
//=============================================================================
// tb_magnitude_comparator — banc d'essai du comparateur N bits non signé.
//
// Testé en 6 bits, ce qui autorise un balayage EXHAUSTIF : 64 x 64 = 4096
// vecteurs, soit toutes les paires possibles. Six bits suffisent à exercer la
// chaîne de ET préfixe sur une profondeur réaliste tout en gardant une
// simulation instantanée.
//
// La référence est la comparaison ENTIÈRE de Verilog sur les indices de boucle,
// qui ignore tout de la structure interne : ni chaîne préfixe, ni cellules
// 1 bit. On vérifie en plus l'invariante d'exclusivité mutuelle — la propriété
// la plus facile à casser quand on assemble N cellules, puisqu'il suffit que
// deux rangs se croient simultanément « le premier à différer » pour que deux
// sorties s'activent ensemble.
//
// Les vecteurs adjacents (b = a, b = a+1, b = a-1) sont inclus dans le balayage
// exhaustif : ce sont eux qui piègent une chaîne préfixe décalée d'un rang.
//=============================================================================
module tb_magnitude_comparator;

    localparam N = 6;

    reg  [N-1:0] a, b;
    wire         A_eq_B, A_gt_B, A_lt_B;

    integer ia, ib;
    integer erreurs = 0;
    reg attendu_eq, attendu_gt, attendu_lt;

    magnitude_comparator #(.N(N)) dut (
        .a(a), .b(b),
        .A_eq_B(A_eq_B), .A_gt_B(A_gt_B), .A_lt_B(A_lt_B)
    );

    initial begin
        for (ia = 0; ia < (1 << N); ia = ia + 1)
        for (ib = 0; ib < (1 << N); ib = ib + 1) begin
            a = ia[N-1:0]; b = ib[N-1:0];
            #1;

            attendu_eq = (ia == ib);
            attendu_gt = (ia >  ib);
            attendu_lt = (ia <  ib);

            if ({A_eq_B, A_gt_B, A_lt_B} !== {attendu_eq, attendu_gt, attendu_lt}) begin
                erreurs = erreurs + 1;
                if (erreurs < 6)
                    $display("ECHEC : a=%0d b=%0d -> eq/gt/lt = %b%b%b (attendu %b%b%b)",
                             ia, ib, A_eq_B, A_gt_B, A_lt_B,
                             attendu_eq, attendu_gt, attendu_lt);
            end

            if (({2'b00, A_eq_B} + {2'b00, A_gt_B} + {2'b00, A_lt_B}) !== 3'd1) begin
                erreurs = erreurs + 1;
                if (erreurs < 6)
                    $display("ECHEC exclusivite : a=%0d b=%0d -> %b%b%b",
                             ia, ib, A_eq_B, A_gt_B, A_lt_B);
            end
        end

        if (erreurs == 0) $display("PASS tb_magnitude_comparator (4096/4096 vecteurs sur 6 bits, relations + exclusivite mutuelle)");
        else              $display("ECHEC tb_magnitude_comparator : %0d erreur(s)", erreurs);
        $finish;
    end

endmodule
