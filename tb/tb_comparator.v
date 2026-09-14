`timescale 1ns / 1ps
//=============================================================================
// tb_comparator — banc d'essai du comparateur 1 bit.
//
// Le domaine ne compte que 4 vecteurs : le balayage est trivialement exhaustif.
//
// Les trois références sont les COMPARAISONS ENTIÈRES de Verilog sur les
// indices de boucle (ia == ib, ia > ib, ia < ib), donc totalement étrangères
// aux portes XNOR / ET-NON du module.
//
// On vérifie en outre l'invariante structurelle du comparateur : les trois
// sorties sont mutuellement exclusives et exhaustives — leur somme vaut
// exactement 1 dans tous les cas. Un circuit qui rendrait 000 (aucune relation)
// ou 110 (à la fois supérieur et égal) serait inutilisable en aval, même si
// chaque sortie prise isolément semblait plausible.
//=============================================================================
module tb_comparator;

    reg  a, b;
    wire A_eq_B, A_gt_B, A_lt_B;

    integer ia, ib;
    integer erreurs = 0;
    reg attendu_eq, attendu_gt, attendu_lt;

    comparator dut (
        .a(a), .b(b),
        .A_eq_B(A_eq_B), .A_gt_B(A_gt_B), .A_lt_B(A_lt_B)
    );

    initial begin
        for (ia = 0; ia < 2; ia = ia + 1)
        for (ib = 0; ib < 2; ib = ib + 1) begin
            a = ia[0]; b = ib[0];
            #1;

            attendu_eq = (ia == ib);
            attendu_gt = (ia >  ib);
            attendu_lt = (ia <  ib);

            if ({A_eq_B, A_gt_B, A_lt_B} !== {attendu_eq, attendu_gt, attendu_lt}) begin
                erreurs = erreurs + 1;
                $display("ECHEC : a=%b b=%b -> eq/gt/lt = %b%b%b (attendu %b%b%b)",
                         a, b, A_eq_B, A_gt_B, A_lt_B,
                         attendu_eq, attendu_gt, attendu_lt);
            end

            // Invariante : exactement une sortie active.
            if (({2'b00, A_eq_B} + {2'b00, A_gt_B} + {2'b00, A_lt_B}) !== 3'd1) begin
                erreurs = erreurs + 1;
                $display("ECHEC exclusivite : a=%b b=%b -> %b%b%b",
                         a, b, A_eq_B, A_gt_B, A_lt_B);
            end
        end

        if (erreurs == 0) $display("PASS tb_comparator (4/4 vecteurs, relations + exclusivite mutuelle)");
        else              $display("ECHEC tb_comparator : %0d erreur(s)", erreurs);
        $finish;
    end

endmodule
