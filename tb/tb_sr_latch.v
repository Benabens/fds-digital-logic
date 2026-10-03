`timescale 1ns / 1ps
//=============================================================================
// tb_sr_latch — banc d'essai du verrou SR à NOR croisées.
//
// On vérifie les quatre lignes de la table de transition, ET surtout la
// propriété qui distingue un circuit SÉQUENTIEL d'un circuit combinatoire :
// la MÉMORISATION. Pour cela, on repasse en s = r = 0 après chaque commande
// et on vérifie que la sortie n'a pas bougé — un circuit combinatoire, lui,
// oublierait immédiatement.
//
// L'ÉTAT INTERDIT s = r = 1 est testé : on vérifie qu'il donne bien
// q = q_b = 0, c'est-à-dire que la complémentarité promise par le nom des
// sorties est VIOLÉE. En revanche, le banc en ressort toujours par une
// commande DÉFINIE (set ou reset), jamais par 1,1 -> 0,0 : cette transition
// est une course critique dont le résultat dépend des délais physiques et
// qu'un simulateur à délais nuls ne peut pas trancher (elle ferait osciller
// indéfiniment le modèle). C'est exactement la raison pour laquelle on ne
// l'utilise pas dans un vrai circuit.
//
// L'horloge ne pilote pas le verrou (un verrou n'a pas d'horloge) : elle sert
// uniquement à cadencer proprement les stimuli.
//=============================================================================
module tb_sr_latch;

    reg  s, r;
    reg  clk = 1'b0;
    wire q, q_b;

    integer erreurs = 0;
    integer etape   = 0;

    sr_latch dut (.s(s), .r(r), .q(q), .q_b(q_b));

    always #5 clk = ~clk;

    // Applique une commande, attend un front (pour cadencer), puis compare.
    task appliquer_et_verifier;
        input cmd_s, cmd_r;
        input att_q, att_qb;
        begin
            etape = etape + 1;
            s = cmd_s;
            r = cmd_r;
            @(posedge clk);
            #1;
            if (q !== att_q || q_b !== att_qb) begin
                erreurs = erreurs + 1;
                $display("ECHEC etape %0d : s=%b r=%b -> q=%b q_b=%b (attendu q=%b q_b=%b)",
                         etape, s, r, q, q_b, att_q, att_qb);
            end
        end
    endtask

    initial begin
        s = 1'b0;
        r = 1'b0;

        // --- sortie de l'indétermination initiale : SET ---------------------
        appliquer_et_verifier(1'b1, 1'b0, 1'b1, 1'b0);   // set
        appliquer_et_verifier(1'b0, 1'b0, 1'b1, 1'b0);   // memorise le 1
        appliquer_et_verifier(1'b0, 1'b0, 1'b1, 1'b0);   // toujours memorise

        // --- RESET puis mémorisation ---------------------------------------
        appliquer_et_verifier(1'b0, 1'b1, 1'b0, 1'b1);   // reset
        appliquer_et_verifier(1'b0, 1'b0, 1'b0, 1'b1);   // memorise le 0
        appliquer_et_verifier(1'b0, 1'b0, 1'b0, 1'b1);   // toujours memorise

        // --- SET redondant : appliquer set sur un verrou deja a 1 -----------
        appliquer_et_verifier(1'b1, 1'b0, 1'b1, 1'b0);
        appliquer_et_verifier(1'b1, 1'b0, 1'b1, 1'b0);
        appliquer_et_verifier(1'b0, 1'b0, 1'b1, 1'b0);

        // --- RESET redondant ------------------------------------------------
        appliquer_et_verifier(1'b0, 1'b1, 1'b0, 1'b1);
        appliquer_et_verifier(1'b0, 1'b1, 1'b0, 1'b1);

        // --- ETAT INTERDIT : les deux sorties tombent a 0 --------------------
        appliquer_et_verifier(1'b1, 1'b1, 1'b0, 1'b0);   // q_b n'est plus ~q !
        appliquer_et_verifier(1'b1, 1'b1, 1'b0, 1'b0);

        // On en ressort par une commande DEFINIE (set), jamais par 1,1 -> 0,0.
        appliquer_et_verifier(1'b1, 1'b0, 1'b1, 1'b0);
        appliquer_et_verifier(1'b0, 1'b0, 1'b1, 1'b0);

        // Deuxieme passage dans l'etat interdit, sortie par un reset.
        appliquer_et_verifier(1'b1, 1'b1, 1'b0, 1'b0);
        appliquer_et_verifier(1'b0, 1'b1, 1'b0, 1'b1);
        appliquer_et_verifier(1'b0, 1'b0, 1'b0, 1'b1);

        if (erreurs == 0)
            $display("PASS tb_sr_latch (%0d etapes : set, reset, memorisation, etat interdit)", etape);
        else
            $display("ECHEC tb_sr_latch : %0d erreur(s)", erreurs);
        $finish;
    end

endmodule
