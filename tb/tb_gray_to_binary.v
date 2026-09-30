`timescale 1ns / 1ps
//=============================================================================
// tb_gray_to_binary — banc d'essai de la conversion Gray vers binaire.
//
// Testé en 8 bits : balayage EXHAUSTIF des 256 codes de Gray possibles.
//
// DEUX RÉFÉRENCES, toutes deux indépendantes de la chaîne de XOR du module :
//
//   1. FORME PRÉFIXE EXPLICITE. Le bit de rang k du binaire est le XOR de TOUS
//      les bits de Gray de rang supérieur ou égal à k. Le banc l'écrit
//      littéralement avec l'opérateur de réduction sur un décalage :
//
//          attendu[k] = ^(gray >> k)
//
//      (les zéros entrés par le décalage ne changent rien à un XOR). C'est la
//      forme fermée de la récurrence, pas la récurrence elle-même.
//
//   2. ALLER-RETOUR. Le résultat est renvoyé dans binary_to_gray : on doit
//      retrouver le code de Gray de départ. Ce contrôle ne suppose rien de
//      l'implémentation des deux modules ; il vérifie qu'ils sont bien
//      RÉCIPROQUES l'un de l'autre, ce qui est la seule chose qui compte quand
//      on les place aux deux bouts d'un franchissement de domaine d'horloge.
//
// Le balayage étant exhaustif et l'aller-retour étant l'identité sur les 256
// codes, on a de surcroît la preuve que la conversion est une BIJECTION.
//=============================================================================
module tb_gray_to_binary;

    localparam N = 8;

    reg  [N-1:0] gray;
    wire [N-1:0] binaire;           // sortie du module teste
    wire [N-1:0] gray_retour;       // re-encodage, pour l'aller-retour

    integer ig, k;
    integer erreurs = 0;
    reg [N-1:0] attendu;

    gray_to_binary #(.N(N)) dut (
        .gray(gray), .binaire(binaire)
    );

    binary_to_gray #(.N(N)) reencodage (
        .binaire(binaire), .gray(gray_retour)
    );

    initial begin
        for (ig = 0; ig < (1 << N); ig = ig + 1) begin
            gray = ig[N-1:0];
            #1;

            // --- 1. reference en forme prefixe fermee ---------------------
            for (k = 0; k < N; k = k + 1)
                attendu[k] = ^(gray >> k);

            if (binaire !== attendu) begin
                erreurs = erreurs + 1;
                if (erreurs < 6)
                    $display("ECHEC valeur : gray=%b -> binaire=%b (attendu %b)",
                             gray, binaire, attendu);
            end

            // --- 2. aller-retour : binary_to_gray(gray_to_binary(g)) = g ---
            if (gray_retour !== gray) begin
                erreurs = erreurs + 1;
                if (erreurs < 6)
                    $display("ECHEC aller-retour : gray=%b -> binaire=%b -> gray=%b",
                             gray, binaire, gray_retour);
            end
        end

        if (erreurs == 0) $display("PASS tb_gray_to_binary (256/256 codes sur 8 bits, forme prefixe + aller-retour avec binary_to_gray)");
        else              $display("ECHEC tb_gray_to_binary : %0d erreur(s)", erreurs);
        $finish;
    end

endmodule
