`timescale 1ns / 1ps
//=============================================================================
// tb_parity_checker — banc d'essai du détecteur de parité.
//
// Testé en 8 bits : balayage EXHAUSTIF des 256 mots possibles.
//
// RÉFÉRENCE INDÉPENDANTE. Plutôt que de réutiliser l'opérateur de réduction ^
// (qui EST la logique testée), le banc COMPTE réellement les bits à 1 dans une
// boucle, puis regarde la parité de ce compte :
//
//        nb_uns = somme des bits ;   attendu_impaire = (nb_uns % 2 == 1)
//
// C'est la définition littérale de la parité, et elle n'a aucun rapport avec le
// câblage en arbre de XOR du module.
//
// On vérifie aussi la COMPLÉMENTARITÉ des deux sorties (parite_paire doit
// toujours être l'inverse de parite_impaire) et le cas limite du mot nul, dont
// la parité est PAIRE — un zéro bit à 1 est un nombre pair, ce qui surprend
// souvent et qu'une implémentation naïve à base de « OU » raterait.
//
// Enfin on contrôle la propriété qui fonde l'usage du bit de parité en
// transmission : inverser UN bit quelconque du mot doit TOUJOURS faire basculer
// la sortie. C'est la garantie « toute erreur simple est détectée ».
//=============================================================================
module tb_parity_checker;

    localparam N = 8;

    reg  [N-1:0] d;
    wire         parite_paire, parite_impaire;

    integer id, k;
    integer erreurs = 0;
    integer nb_uns;
    reg     attendu_impaire;
    reg     precedente;

    // Masque d'un seul bit, sur la largeur du mot, pour simuler une erreur.
    localparam [N-1:0] masque_un_bit = 1;

    parity_checker #(.N(N)) dut (
        .d(d), .parite_paire(parite_paire), .parite_impaire(parite_impaire)
    );

    initial begin
        for (id = 0; id < (1 << N); id = id + 1) begin
            d = id[N-1:0];
            #1;

            // --- reference : on compte reellement les bits a 1 -------------
            nb_uns = 0;
            for (k = 0; k < N; k = k + 1)
                if (d[k]) nb_uns = nb_uns + 1;
            attendu_impaire = (nb_uns % 2) == 1;

            if (parite_impaire !== attendu_impaire) begin
                erreurs = erreurs + 1;
                if (erreurs < 6)
                    $display("ECHEC : d=%b (%0d uns) -> impaire=%b (attendu %b)",
                             d, nb_uns, parite_impaire, attendu_impaire);
            end
            if (parite_paire !== ~attendu_impaire) begin
                erreurs = erreurs + 1;
                if (erreurs < 6)
                    $display("ECHEC complementarite : d=%b -> paire=%b impaire=%b",
                             d, parite_paire, parite_impaire);
            end

            // --- detection de toute erreur simple -------------------------
            // Inverser un bit doit faire basculer la sortie, quel que soit ce bit.
            precedente = parite_impaire;
            for (k = 0; k < N; k = k + 1) begin
                d = id[N-1:0] ^ (masque_un_bit << k);
                #1;
                if (parite_impaire === precedente) begin
                    erreurs = erreurs + 1;
                    if (erreurs < 6)
                        $display("ECHEC erreur simple non detectee : d=%b bit %0d",
                                 id[N-1:0], k);
                end
            end
        end

        if (erreurs == 0) $display("PASS tb_parity_checker (256/256 mots de 8 bits, comptage explicite + complementarite + detection des 2048 erreurs simples)");
        else              $display("ECHEC tb_parity_checker : %0d erreur(s)", erreurs);
        $finish;
    end

endmodule
