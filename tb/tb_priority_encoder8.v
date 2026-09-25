`timescale 1ns / 1ps
//=============================================================================
// tb_priority_encoder8 — banc d'essai exhaustif de l'encodeur prioritaire.
//
// L'entrée fait 8 bits : 2^8 = 256 combinaisons, TOUTES balayées. Contrairement
// à l'encodeur simple, ce circuit est TOTAL — sa sortie a un sens pour les 256
// vecteurs — donc l'exhaustivité vérifie réellement toute la spécification.
//
// RÉFÉRENCE INDÉPENDANTE. Le module est écrit en `casez`, comme une cascade de
// huit motifs à joker rangés du poids fort vers le poids faible. Le banc n'en
// reprend ni les motifs ni l'ordre : il applique la définition arithmétique de
// la sortie, « la POSITION DU 1 DE POIDS FORT », obtenue par un balayage
// ASCENDANT des indices qui retient le dernier trouvé :
//
//        msb = -1 ; pour b de 0 à 7 : si d[b] alors msb = b
//
// Le sens de parcours est délibérément l'inverse de celui du casez : une erreur
// de priorité (mauvais ordre des branches) fait diverger les deux et devient
// immédiatement visible. Le drapeau valide est recalculé par msb >= 0.
//
// Quand d = 0, l'en-tête du module précise que q n'a pas de signification, mais
// le `default` du casez lui donne la valeur définie 3'd0 : on le contrôle, car
// une sortie flottante ou inconnue serait un défaut réel.
//
// PROPRIÉTÉS VÉRIFIÉES EN PLUS, qui testent la NOTION de priorité plutôt qu'une
// table de valeurs :
//   - sortie toujours DÉFINIE (aucun bit à x) : c'est le test anti-verrou. Un
//     always @(*) dont une branche oublierait d'affecter q inférerait un latch,
//     et la sortie resterait inconnue ou mémorisée ;
//   - la ligne désignée est active : d[q] = 1 dès que valide = 1 ;
//   - rien au-dessus : tous les bits d'indice supérieur à q sont nuls, ce qui
//     est exactement la définition du « 1 de poids fort » ;
//   - INSENSIBILITÉ AUX BITS INFÉRIEURS : on rallume TOUS les bits situés sous
//     la position gagnante et l'on exige que q ne bouge pas. C'est le test qui
//     distingue vraiment un encodeur prioritaire d'un encodeur simple — ce
//     dernier échouerait massivement ici, puisqu'il rendrait le OU des indices.
//=============================================================================
module tb_priority_encoder8;

    reg  [7:0] d;
    wire [2:0] q;
    wire       valide;

    integer i, b, msb;
    integer erreurs  = 0;
    integer vecteurs = 0;

    reg [2:0] attendu_q;
    reg       attendu_valide;
    reg [7:0] d_original;

    priority_encoder8 dut (.d(d), .q(q), .valide(valide));

    initial begin
        for (i = 0; i < 256; i = i + 1) begin
            d = i[7:0];
            #1;

            // reference : balayage ASCENDANT, on garde le dernier indice actif
            msb = -1;
            for (b = 0; b < 8; b = b + 1)
                if (d[b] === 1'b1) msb = b;

            attendu_valide = (msb >= 0);
            attendu_q      = (msb >= 0) ? msb[2:0] : 3'd0;
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

            // sortie toujours definie : test anti-verrou (latch)
            if ((^q) === 1'bx) begin
                erreurs = erreurs + 1;
                if (erreurs < 6)
                    $display("ECHEC sortie indefinie : d=%b -> q=%b", d, q);
            end

            if (valide === 1'b1) begin
                // la ligne designee est bien active
                if (d[q] !== 1'b1) begin
                    erreurs = erreurs + 1;
                    if (erreurs < 6)
                        $display("ECHEC designation : d=%b q=%0d mais d[%0d]=%b",
                                 d, q, q, d[q]);
                end
                // rien d'actif au-dessus de la position gagnante
                for (b = 0; b < 8; b = b + 1)
                    if (b > msb && d[b] === 1'b1) begin
                        erreurs = erreurs + 1;
                        $display("ECHEC poids fort : d=%b q=%0d mais d[%0d]=1", d, q, b);
                    end
            end

            // insensibilite aux bits inferieurs : on les allume tous, q ne doit
            // pas bouger. Un encodeur NON prioritaire echouerait ici.
            if (msb > 0) begin
                d_original = d;
                d = d | ((1 << msb) - 1);
                #1;
                vecteurs = vecteurs + 1;
                if (q !== attendu_q || valide !== 1'b1) begin
                    erreurs = erreurs + 1;
                    if (erreurs < 6)
                        $display("ECHEC priorite : %b bruite en %b -> q=%b (attendu %b)",
                                 d_original, d, q, attendu_q);
                end
                d = d_original;
            end
        end

        if (erreurs == 0) $display("PASS tb_priority_encoder8 (%0d vecteurs : 256 exhaustifs + bruitage des bits inferieurs)", vecteurs);
        else              $display("ECHEC tb_priority_encoder8 : %0d erreur(s)", erreurs);
        $finish;
    end

endmodule
