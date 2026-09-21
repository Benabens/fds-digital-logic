`timescale 1ns / 1ps
//=============================================================================
// tb_decoder2to4 — banc d'essai exhaustif du décodeur 2 vers 4.
//
// 3 entrées (a[1:0], en) => 8 combinaisons, toutes balayées.
//
// RÉFÉRENCE INDÉPENDANTE. Les quatre mintermes écrits dans le module ne sont
// pas recopiés : on exprime le one-hot par un DÉCALAGE, ce qui traduit
// directement la définition « la ligne numéro a est la seule active » :
//
//        attendu = en ? (4'b0001 << a) : 4'b0000
//
// On contrôle de plus la propriété ONE-HOT elle-même en comptant les bits à 1
// de la sortie réelle : exactement un quand en = 1, exactement zéro sinon.
// Compter les bits est une vérification de nature différente de la comparaison
// à un motif, elle attrape des fautes que la seule égalité pourrait masquer si
// la référence était mal construite.
//=============================================================================
module tb_decoder2to4;

    reg  [1:0] a;
    reg        en;
    wire [3:0] y;

    integer i, b;
    integer erreurs  = 0;
    integer vecteurs = 0;
    integer actives;

    reg [3:0] attendu;

    decoder2to4 dut (.a(a), .en(en), .y(y));

    initial begin
        for (i = 0; i < 8; i = i + 1) begin
            {en, a} = i[2:0];
            #1;

            attendu  = en ? (4'b0001 << a) : 4'b0000;
            vecteurs = vecteurs + 1;

            if (y !== attendu) begin
                erreurs = erreurs + 1;
                $display("ECHEC : en=%b a=%b -> y=%b (attendu %b)", en, a, y, attendu);
            end

            // propriete one-hot : 1 seule ligne si valide, 0 sinon
            actives = 0;
            for (b = 0; b < 4; b = b + 1)
                if (y[b] === 1'b1) actives = actives + 1;
            if (actives !== (en ? 1 : 0)) begin
                erreurs = erreurs + 1;
                $display("ECHEC one-hot : en=%b a=%b -> %0d ligne(s) active(s)", en, a, actives);
            end
        end

        if (erreurs == 0) $display("PASS tb_decoder2to4 (%0d/8 combinaisons + propriete one-hot)", vecteurs);
        else              $display("ECHEC tb_decoder2to4 : %0d erreur(s)", erreurs);
        $finish;
    end

endmodule
