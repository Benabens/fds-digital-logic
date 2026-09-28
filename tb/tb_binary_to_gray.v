`timescale 1ns / 1ps
//=============================================================================
// tb_binary_to_gray — banc d'essai de la conversion binaire vers Gray.
//
// Testé en 8 bits : balayage EXHAUSTIF des 256 valeurs.
//
// Trois contrôles, dont deux portent sur les PROPRIÉTÉS mathématiques du code
// de Gray plutôt que sur sa formule — c'est ce qui rend ce banc convaincant :
//
//   1. VALEUR : la référence est calculée avec l'opérateur de décalage,
//      gray = binaire ^ (binaire >> 1), une écriture arithmétique compacte
//      étrangère au câblage XOR rang par rang du module.
//
//   2. DISTANCE DE HAMMING UNITAIRE — la propriété qui DÉFINIT le code de
//      Gray : deux valeurs consécutives doivent différer d'EXACTEMENT un bit.
//      Le banc compte réellement les bits qui changent entre gray(k-1) et
//      gray(k), et exige le compte 1. Une conversion fausse d'un rang passerait
//      peut-être le contrôle 1 par coïncidence, jamais celui-ci.
//
//   3. BIJECTIVITÉ : les 256 codes produits doivent être deux à deux distincts
//      (une numérotation qui répète un code est inutilisable). Un vecteur de
//      256 marqueurs mémorise les codes déjà rencontrés.
//=============================================================================
module tb_binary_to_gray;

    localparam N = 8;

    reg  [N-1:0] binaire;
    wire [N-1:0] gray;

    integer id, k;
    integer erreurs = 0;
    integer nb_changements;
    reg [N-1:0] attendu;
    reg [N-1:0] gray_precedent;
    reg [N-1:0] ecart;
    reg [255:0] deja_vu;            // marqueurs de bijectivite

    binary_to_gray #(.N(N)) dut (
        .binaire(binaire), .gray(gray)
    );

    initial begin
        deja_vu        = 256'b0;
        gray_precedent = {N{1'b0}};

        for (id = 0; id < (1 << N); id = id + 1) begin
            binaire = id[N-1:0];
            #1;

            // --- 1. valeur ------------------------------------------------
            attendu = binaire ^ (binaire >> 1);
            if (gray !== attendu) begin
                erreurs = erreurs + 1;
                if (erreurs < 6)
                    $display("ECHEC valeur : %0d = %b -> gray %b (attendu %b)",
                             id, binaire, gray, attendu);
            end

            // --- 2. un seul bit change d'une valeur a la suivante ----------
            if (id > 0) begin
                ecart = gray ^ gray_precedent;
                nb_changements = 0;
                for (k = 0; k < N; k = k + 1)
                    if (ecart[k]) nb_changements = nb_changements + 1;
                if (nb_changements != 1) begin
                    erreurs = erreurs + 1;
                    if (erreurs < 6)
                        $display("ECHEC distance : gray(%0d)=%b et gray(%0d)=%b different de %0d bits",
                                 id-1, gray_precedent, id, gray, nb_changements);
                end
            end
            gray_precedent = gray;

            // --- 3. bijectivite -------------------------------------------
            if (deja_vu[gray]) begin
                erreurs = erreurs + 1;
                if (erreurs < 6)
                    $display("ECHEC bijectivite : le code %b est produit deux fois", gray);
            end
            deja_vu[gray] = 1'b1;
        end

        if (erreurs == 0) $display("PASS tb_binary_to_gray (256/256 valeurs sur 8 bits, valeur + distance de Hamming unitaire + bijectivite)");
        else              $display("ECHEC tb_binary_to_gray : %0d erreur(s)", erreurs);
        $finish;
    end

endmodule
