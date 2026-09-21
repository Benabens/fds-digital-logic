`timescale 1ns / 1ps
//=============================================================================
// tb_demux1to4 — banc d'essai exhaustif du démultiplexeur 1 vers 4.
//
// Le domaine d'entrée ne compte que 2^4 = 16 combinaisons (d, sel[1:0], en) :
// le balayage est intégralement exhaustif, il n'y a donc rien à échantillonner
// ni aucun cas limite à ajouter — ILS SONT TOUS TESTÉS.
//
// RÉFÉRENCE INDÉPENDANTE. Les quatre mintermes du module ne sont pas réécrits.
// On part de la définition fonctionnelle : « si le circuit est validé et que la
// donnée vaut 1, un seul 1 apparaît, en position sel ». Cela s'écrit avec un
// simple DÉCALAGE d'une constante :
//
//        attendu = (en AND d) ? (4'b0001 << sel) : 4'b0000
//
// On vérifie en outre deux INVARIANTS structurels que la table seule ne
// garantit pas explicitement :
//   - au plus une sortie est active à la fois (le décalage l'assure côté
//     référence, mais on le contrôle aussi sur la sortie réelle) ;
//   - en = 0 force les quatre sorties à zéro, quelles que soient d et sel.
//=============================================================================
module tb_demux1to4;

    reg        d, en;
    reg  [1:0] sel;
    wire [3:0] y;

    integer i;
    integer erreurs  = 0;
    integer vecteurs = 0;
    integer actives;
    integer b;

    reg [3:0] attendu;

    demux1to4 dut (.d(d), .sel(sel), .en(en), .y(y));

    initial begin
        for (i = 0; i < 16; i = i + 1) begin
            {en, d, sel} = i[3:0];
            #1;

            attendu  = (en & d) ? (4'b0001 << sel) : 4'b0000;
            vecteurs = vecteurs + 1;

            if (y !== attendu) begin
                erreurs = erreurs + 1;
                $display("ECHEC : en=%b d=%b sel=%b -> y=%b (attendu %b)",
                         en, d, sel, y, attendu);
            end

            // invariant 1 : jamais plus d'une sortie active
            actives = 0;
            for (b = 0; b < 4; b = b + 1)
                if (y[b] === 1'b1) actives = actives + 1;
            if (actives > 1) begin
                erreurs = erreurs + 1;
                $display("ECHEC invariant : %0d sorties actives (en=%b d=%b sel=%b)",
                         actives, en, d, sel);
            end

            // invariant 2 : inhibition complete quand en = 0
            if (en === 1'b0 && y !== 4'b0000) begin
                erreurs = erreurs + 1;
                $display("ECHEC inhibition : en=0 mais y=%b", y);
            end
        end

        if (erreurs == 0) $display("PASS tb_demux1to4 (%0d/16 combinaisons + invariants)", vecteurs);
        else              $display("ECHEC tb_demux1to4 : %0d erreur(s)", erreurs);
        $finish;
    end

endmodule
