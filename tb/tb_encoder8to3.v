`timescale 1ns / 1ps
//=============================================================================
// tb_encoder8to3 — banc d'essai exhaustif de l'encodeur 8 vers 3.
//
// L'entrée fait 8 bits : 2^8 = 256 combinaisons, TOUTES balayées. On ne se
// limite surtout pas aux 8 entrées one-hot « légales » — un encodeur simple
// reçoit en pratique des entrées quelconques, et son comportement dans ce cas
// fait partie de sa spécification (cf. l'en-tête du module).
//
// RÉFÉRENCE INDÉPENDANTE. Le module câble trois OU figés, énumérant à la main
// les indices qui portent chaque bit de poids :
//     q[0] = d1|d3|d5|d7,  q[1] = d2|d3|d6|d7,  q[2] = d4|d5|d6|d7.
// Le banc ne recopie pas ces trois listes. Il applique la DÉFINITION dont elles
// découlent : la sortie est le OU des NUMÉROS des lignes actives. On balaie donc
// les indices et on accumule :
//
//        attendu_q = OU des i tels que d[i] = 1        (0 si aucun)
//
// Une liste d'indices écrite à la main peut contenir une faute de recopie ; une
// boucle qui parcourt les indices, non. Pour une entrée one-hot d = 1<<i, cette
// accumulation se réduit à i : c'est bien le numéro de la ligne active.
//
// Le drapeau `valide` est lui aussi recalculé autrement que par le OU de
// réduction du module : on COMPTE les lignes actives et on teste « compte > 0 ».
//
// TEST DE RÉCIPROCITÉ (partie 2). L'encodeur est censé être l'INVERSE du
// décodeur 3→8. On le vérifie littéralement : on branche la sortie d'un
// decoder3to8 sur l'entrée de l'encodeur et on contrôle que le parcours
// aller-retour redonne le nombre de départ, pour les 8 valeurs possibles :
//
//        i  ->  decoder3to8  ->  one-hot  ->  encoder8to3  ->  i
//
// C'est la vérification la plus parlante du chapitre : elle teste la PROPRIÉTÉ
// mathématique attendue plutôt qu'une table, et elle relie les deux modules.
//
// AMBIGUÏTÉ SUR LE ZÉRO. On vérifie explicitement que d = 00000000 et
// d = 00000001 donnent tous deux q = 000 mais des `valide` différents : c'est
// la raison d'être du drapeau, et l'oublier serait la faute typique.
//=============================================================================
module tb_encoder8to3;

    reg  [7:0] d;
    wire [2:0] q;
    wire       valide;

    // Deuxieme montage, pour le test de reciprocite decodeur -> encodeur.
    reg  [2:0] adresse;
    wire [7:0] one_hot;

    integer i, b;
    integer erreurs  = 0;
    integer vecteurs = 0;
    integer actives;

    reg [2:0] attendu_q;
    reg       attendu_valide;

    encoder8to3 dut (.d(d), .q(q), .valide(valide));

    decoder3to8 decodeur_reference (
        .a  (adresse),
        .en (1'b1),
        .y  (one_hot)
    );

    initial begin
        // --- Partie 1 : balayage exhaustif des 256 entrees ------------------
        for (i = 0; i < 256; i = i + 1) begin
            d = i[7:0];
            #1;

            // reference : OU des numeros des lignes actives, et comptage
            attendu_q = 3'b000;
            actives   = 0;
            for (b = 0; b < 8; b = b + 1)
                if (d[b] === 1'b1) begin
                    attendu_q = attendu_q | b[2:0];
                    actives   = actives + 1;
                end
            attendu_valide = (actives > 0);
            vecteurs       = vecteurs + 1;

            if (q !== attendu_q) begin
                erreurs = erreurs + 1;
                if (erreurs < 6)
                    $display("ECHEC q : d=%b -> q=%b (attendu %b)", d, q, attendu_q);
            end
            if (valide !== attendu_valide) begin
                erreurs = erreurs + 1;
                if (erreurs < 6)
                    $display("ECHEC valide : d=%b -> valide=%b (attendu %b)",
                             d, valide, attendu_valide);
            end
        end

        // --- Partie 2 : reciprocite decodeur 3->8 puis encodeur 8->3 --------
        for (i = 0; i < 8; i = i + 1) begin
            adresse = i[2:0];
            #1;
            d = one_hot;            // le one-hot produit par le decodeur
            #1;
            vecteurs = vecteurs + 1;

            if (q !== adresse || valide !== 1'b1) begin
                erreurs = erreurs + 1;
                $display("ECHEC aller-retour : %0d -> %b -> q=%b valide=%b (attendu q=%b valide=1)",
                         adresse, one_hot, q, valide, adresse);
            end
        end

        // --- Partie 3 : levee de l'ambiguite « rien » / « ligne 0 » ---------
        d = 8'b0000_0000; #1;
        vecteurs = vecteurs + 1;
        if (q !== 3'b000 || valide !== 1'b0) begin
            erreurs = erreurs + 1;
            $display("ECHEC cas limite : d=0 -> q=%b valide=%b (attendu q=000 valide=0)",
                     q, valide);
        end

        d = 8'b0000_0001; #1;
        vecteurs = vecteurs + 1;
        if (q !== 3'b000 || valide !== 1'b1) begin
            erreurs = erreurs + 1;
            $display("ECHEC cas limite : d=1 -> q=%b valide=%b (attendu q=000 valide=1)",
                     q, valide);
        end

        if (erreurs == 0) $display("PASS tb_encoder8to3 (%0d vecteurs : 256 exhaustifs + 8 aller-retours decodeur + cas limites)", vecteurs);
        else              $display("ECHEC tb_encoder8to3 : %0d erreur(s)", erreurs);
        $finish;
    end

endmodule
