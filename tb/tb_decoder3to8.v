`timescale 1ns / 1ps
//=============================================================================
// tb_decoder3to8 — banc d'essai exhaustif du décodeur 3 vers 8.
//
// 4 entrées (a[2:0] et en) => 2^4 = 16 combinaisons, TOUTES balayées. Le
// domaine est minuscule : il n'y a ni échantillonnage ni cas limite à ajouter,
// puisque tous les cas sont des cas testés.
//
// RÉFÉRENCE INDÉPENDANTE. Le module décrit sa sortie par un comparateur
// d'égalité répliqué huit fois (« y[i] = en AND (a == i) »). Le banc n'en
// reprend rien : il part de l'autre définition équivalente du one-hot, celle
// par DÉCALAGE d'un unique bit à 1 vers la position demandée :
//
//        attendu = en ? (8'b0000_0001 << a) : 8'b0000_0000
//
// Décalage contre comparaison : deux formulations sans code commun, donc une
// faute de conception ne peut pas se retrouver à l'identique des deux côtés.
//
// PROPRIÉTÉS VÉRIFIÉES EN PLUS de l'égalité au motif attendu, car une égalité
// seule ne teste que ce que la référence sait déjà exprimer :
//   - one-hot : on COMPTE les bits à 1 de la sortie réelle (exactement 1 quand
//     en = 1, exactement 0 sinon) ;
//   - cohérence indice/valeur : la ligne active est bien celle d'indice a ;
//   - inhibition : en = 0 éteint les huit sorties quelle que soit l'adresse.
//=============================================================================
module tb_decoder3to8;

    reg  [2:0] a;
    reg        en;
    wire [7:0] y;

    integer i, b;
    integer erreurs  = 0;
    integer vecteurs = 0;
    integer actives;

    reg [7:0] attendu;

    decoder3to8 dut (.a(a), .en(en), .y(y));

    initial begin
        for (i = 0; i < 16; i = i + 1) begin
            {en, a} = i[3:0];
            #1;

            attendu  = en ? (8'b0000_0001 << a) : 8'b0000_0000;
            vecteurs = vecteurs + 1;

            if (y !== attendu) begin
                erreurs = erreurs + 1;
                $display("ECHEC : en=%b a=%b -> y=%b (attendu %b)", en, a, y, attendu);
            end

            // propriete one-hot : exactement une ligne active si valide
            actives = 0;
            for (b = 0; b < 8; b = b + 1)
                if (y[b] === 1'b1) actives = actives + 1;
            if (actives !== (en ? 1 : 0)) begin
                erreurs = erreurs + 1;
                $display("ECHEC one-hot : en=%b a=%b -> %0d ligne(s) active(s)",
                         en, a, actives);
            end

            // coherence : c'est bien la ligne d'indice a qui repond
            if (en === 1'b1 && y[a] !== 1'b1) begin
                erreurs = erreurs + 1;
                $display("ECHEC coherence : a=%0d mais y[%0d]=%b", a, a, y[a]);
            end

            // inhibition complete par l'enable
            if (en === 1'b0 && y !== 8'b0000_0000) begin
                erreurs = erreurs + 1;
                $display("ECHEC inhibition : en=0 a=%b mais y=%b", a, y);
            end
        end

        if (erreurs == 0) $display("PASS tb_decoder3to8 (%0d/16 combinaisons + one-hot, coherence, inhibition)", vecteurs);
        else              $display("ECHEC tb_decoder3to8 : %0d erreur(s)", erreurs);
        $finish;
    end

endmodule
