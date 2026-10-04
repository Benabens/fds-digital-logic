`timescale 1ns / 1ps
//=============================================================================
// tb_d_latch — banc d'essai du verrou D transparent.
//
// Deux propriétés à démontrer, et elles sont opposées :
//
//  1) TRANSPARENCE (en = 1) : q doit suivre d IMMÉDIATEMENT, sans attendre
//     quoi que ce soit. On fait donc varier d plusieurs fois PENDANT que
//     en vaut 1 et on vérifie que q bouge à chaque fois. C'est le test qui
//     échouerait sur une bascule sur front — et c'est tout l'intérêt de ce
//     banc : il met en évidence la différence NIVEAU / FRONT.
//
//  2) OPACITÉ (en = 0) : q doit rester figée sur la dernière valeur vue
//     avant la retombée de en, quelles que soient les variations de d.
//
// On vérifie aussi en permanence que q_b == ~q (le verrou D n'a pas d'état
// interdit, contrairement au verrou SR).
//
// L'horloge sert de générateur de niveaux d'enable : en = clk pendant la
// phase 3, ce qui montre concrètement le « trou » de transparence pendant
// tout le demi-cycle haut.
//=============================================================================
module tb_d_latch;

    reg  d, en;
    reg  clk = 1'b0;
    wire q, q_b;

    integer erreurs = 0;
    integer etape   = 0;
    integer i;

    d_latch dut (.d(d), .en(en), .q(q), .q_b(q_b));

    always #5 clk = ~clk;

    task verifier;
        input att_q;
        begin
            etape = etape + 1;
            if (q !== att_q) begin
                erreurs = erreurs + 1;
                $display("ECHEC etape %0d (t=%0t) : d=%b en=%b -> q=%b (attendu %b)",
                         etape, $time, d, en, q, att_q);
            end
            if (q_b !== ~q) begin
                erreurs = erreurs + 1;
                $display("ECHEC etape %0d : q_b=%b n'est pas le complement de q=%b",
                         etape, q_b, q);
            end
        end
    endtask

    initial begin
        d  = 1'b0;
        en = 1'b0;

        // --- phase 1 : TRANSPARENCE ----------------------------------------
        // en reste a 1 : chaque changement de d doit traverser aussitot.
        en = 1'b1;
        #2 d = 1'b1;  #1 verifier(1'b1);
        #2 d = 1'b0;  #1 verifier(1'b0);
        #2 d = 1'b1;  #1 verifier(1'b1);
        #2 d = 1'b1;  #1 verifier(1'b1);
        #2 d = 1'b0;  #1 verifier(1'b0);

        // --- phase 2 : OPACITE ----------------------------------------------
        // On memorise un 1, puis on ferme le verrou : d peut bouger autant
        // qu'il veut, q ne doit plus jamais bouger.
        d  = 1'b1;  #2 verifier(1'b1);
        en = 1'b0;  #2 verifier(1'b1);
        for (i = 0; i < 6; i = i + 1) begin
            #2 d = ~d;
            #1 verifier(1'b1);      // fige sur 1, quoi que fasse d
        end

        // Meme chose en memorisant un 0.
        d = 1'b0;  en = 1'b1;  #2 verifier(1'b0);
        en = 1'b0;
        for (i = 0; i < 6; i = i + 1) begin
            #2 d = ~d;
            #1 verifier(1'b0);      // fige sur 0
        end

        // --- phase 3 : enable pilote par l'horloge --------------------------
        // en = clk. Pendant le demi-cycle haut, le verrou est transparent :
        // c'est LE comportement qu'une bascule sur front n'aurait pas.
        for (i = 0; i < 8; i = i + 1) begin
            @(posedge clk);
            en = 1'b1;
            #1 d = i[0];            // d change PENDANT la transparence
            #1 verifier(i[0]);      // ... et q a deja suivi
            #1 d = ~i[0];
            #1 verifier(~i[0]);     // ... encore une fois, dans le meme cycle
            @(negedge clk);
            en = 1'b0;              // fermeture : q garde la derniere valeur
            #1 d = i[0];
            #1 verifier(~i[0]);     // fige : d n'a plus d'effet
        end

        if (erreurs == 0)
            $display("PASS tb_d_latch (%0d verifications : transparence sur niveau, opacite, q_b)", etape);
        else
            $display("ECHEC tb_d_latch : %0d erreur(s)", erreurs);
        $finish;
    end

endmodule
