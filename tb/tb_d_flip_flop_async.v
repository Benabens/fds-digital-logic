`timescale 1ns / 1ps
//=============================================================================
// tb_d_flip_flop_async — banc d'essai de la bascule D à reset ASYNCHRONE.
//
// Le banc reprend les tests de tb_d_flip_flop (échantillonnage sur front,
// complémentarité de q_b) et y ajoute LE test qui distingue les deux
// variantes :
//
//   * une impulsion de reset placée ENTIÈREMENT entre deux fronts d'horloge
//     doit ICI remettre q à 0 IMMÉDIATEMENT — alors que la version synchrone
//     l'ignorait complètement. C'est l'expérience à retenir : le même stimulus
//     donne deux résultats opposés selon le type de reset.
//
//   * tant que rst reste à 1, les fronts d'horloge n'ont aucun effet : q est
//     maintenue à 0 même si d vaut 1.
//
// On teste aussi le cas extrême « aucune horloge » : le reset doit fonctionner
// alors que l'horloge est arrêtée, ce qui est l'argument principal en faveur
// du reset asynchrone pour l'initialisation à la mise sous tension.
//=============================================================================
module tb_d_flip_flop_async;

    reg  clk = 1'b0;
    reg  clk_actif = 1'b1;      // permet d'ARRETER l'horloge pour un test
    reg  rst, d;
    wire q, q_b;

    integer erreurs = 0;
    integer cycles  = 0;
    integer i;
    reg     attendu;

    d_flip_flop_async dut (.clk(clk), .rst(rst), .d(d), .q(q), .q_b(q_b));

    always #5 if (clk_actif) clk = ~clk;

    task verifier;
        input att;
        begin
            if (q !== att) begin
                erreurs = erreurs + 1;
                $display("ECHEC cycle %0d (t=%0t) : rst=%b d=%b -> q=%b (attendu %b)",
                         cycles, $time, rst, d, q, att);
            end
            if (q_b !== ~q) begin
                erreurs = erreurs + 1;
                $display("ECHEC cycle %0d : q_b=%b n'est pas le complement de q=%b",
                         cycles, q_b, q);
            end
        end
    endtask

    task pas;
        input in_rst, in_d;
        begin
            rst = in_rst;
            d   = in_d;
            @(posedge clk);
            #1;
            cycles  = cycles + 1;
            attendu = in_rst ? 1'b0 : in_d;
            verifier(attendu);
        end
    endtask

    initial begin
        rst = 1'b1;
        d   = 1'b0;
        #1 verifier(1'b0);      // le reset agit SANS attendre le moindre front

        // --- fonctionnement normal sur front --------------------------------
        pas(1'b0, 1'b1);
        pas(1'b0, 1'b0);
        pas(1'b0, 1'b1);
        pas(1'b0, 1'b1);
        for (i = 0; i < 16; i = i + 1)
            pas(1'b0, ((i * 5) % 4) < 2);

        // --- LE test : impulsion de reset ENTRE deux fronts -----------------
        pas(1'b0, 1'b1);        // q = 1
        @(negedge clk);         // bien loin du prochain front montant
        rst = 1'b1;
        #1;
        cycles = cycles + 1;
        verifier(1'b0);         // asynchrone : q est DEJA a 0
        rst = 1'b0;             // impulsion terminee avant le front montant
        #1;
        verifier(1'b0);         // et la remise a zero est memorisee

        // --- reset maintenu : les fronts n'ont plus aucun effet -------------
        rst = 1'b1;
        d   = 1'b1;
        for (i = 0; i < 4; i = i + 1) begin
            @(posedge clk);
            #1;
            cycles = cycles + 1;
            verifier(1'b0);     // maintenue a 0 malgre d = 1
        end
        pas(1'b0, 1'b1);        // relachement : q suit enfin d
        verifier(1'b1);

        // --- cas extreme : reset alors que l'HORLOGE EST ARRETEE ------------
        @(negedge clk);
        clk_actif = 1'b0;       // plus aucun front a partir d'ici
        #20;
        d   = 1'b1;
        rst = 1'b1;
        #5;
        cycles = cycles + 1;
        verifier(1'b0);         // impossible avec un reset synchrone
        #20;
        verifier(1'b0);
        rst       = 1'b0;
        clk_actif = 1'b1;       // on relance l'horloge
        pas(1'b0, 1'b1);
        pas(1'b0, 1'b0);

        if (erreurs == 0)
            $display("PASS tb_d_flip_flop_async (%0d cycles : reset immediat hors front et sans horloge, front montant, q_b)", cycles);
        else
            $display("ECHEC tb_d_flip_flop_async : %0d erreur(s)", erreurs);
        $finish;
    end

endmodule
