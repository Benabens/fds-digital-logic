`timescale 1ns / 1ps
//=============================================================================
// tb_absolute_difference — banc d'essai de l'écart absolu non signé.
//
// Testé en 6 bits : 64 x 64 = 4096 vecteurs, balayage EXHAUSTIF. Les deux
// moitiés du domaine (a >= b et a < b) sont donc couvertes intégralement, ce
// qui est essentiel ici : le seul vrai risque de ce circuit est de se tromper
// de sens de soustraction et de rendre le complément à 2 du bon résultat.
//
// Référence INDÉPENDANTE : l'écart est recalculé en arithmétique entière de
// Verilog sur les indices de boucle, sans complément à 2 ni comparateur —
//
//        attendu = (ia > ib) ? ia - ib : ib - ia
//
// Deux propriétés supplémentaires sont contrôlées à chaque vecteur, car elles
// caractérisent une distance et se cassent indépendamment du cas nominal :
//
//   - SÉPARATION : le résultat est nul si et seulement si a = b ;
//   - RECONSTRUCTION : min(a,b) + |a-b| = max(a,b), sur 7 bits pour être sûr
//     qu'aucun débordement silencieux ne masque une erreur.
//=============================================================================
module tb_absolute_difference;

    localparam N = 6;

    reg  [N-1:0] a, b;
    wire [N-1:0] difference;

    integer ia, ib;
    integer erreurs = 0;
    integer attendu, minimum, maximum;

    absolute_difference #(.N(N)) dut (
        .a(a), .b(b), .difference(difference)
    );

    initial begin
        for (ia = 0; ia < (1 << N); ia = ia + 1)
        for (ib = 0; ib < (1 << N); ib = ib + 1) begin
            a = ia[N-1:0]; b = ib[N-1:0];
            #1;

            attendu = (ia > ib) ? (ia - ib) : (ib - ia);
            minimum = (ia < ib) ? ia : ib;
            maximum = (ia > ib) ? ia : ib;

            if (difference !== attendu[N-1:0]) begin
                erreurs = erreurs + 1;
                if (erreurs < 6)
                    $display("ECHEC : |%0d - %0d| -> %0d (attendu %0d)",
                             ia, ib, difference, attendu);
            end

            // Separation : nul si et seulement si les operandes sont egaux.
            if ((difference == 0) !== (ia == ib)) begin
                erreurs = erreurs + 1;
                if (erreurs < 6)
                    $display("ECHEC separation : a=%0d b=%0d -> %0d",
                             ia, ib, difference);
            end

            // Reconstruction : min + ecart = max (calcul sur 7 bits).
            if ((minimum + difference) !== maximum) begin
                erreurs = erreurs + 1;
                if (erreurs < 6)
                    $display("ECHEC reconstruction : min=%0d + ecart=%0d != max=%0d",
                             minimum, difference, maximum);
            end
        end

        if (erreurs == 0) $display("PASS tb_absolute_difference (4096/4096 vecteurs sur 6 bits, valeur + separation + reconstruction)");
        else              $display("ECHEC tb_absolute_difference : %0d erreur(s)", erreurs);
        $finish;
    end

endmodule
