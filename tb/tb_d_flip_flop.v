`timescale 1ns / 1ps
//=============================================================================
// tb_d_flip_flop — banc d'essai de la bascule D à reset SYNCHRONE.
//
// Trois choses à démontrer :
//
//  1) Échantillonnage sur FRONT : q prend la valeur que d avait juste AVANT
//     le front montant, et ne bouge pas entre deux fronts. On fait donc varier
//     d au milieu du cycle et on vérifie que q reste figée.
//
//  2) Reset SYNCHRONE : une impulsion de reset qui commence ET se termine
//     ENTRE deux fronts est totalement IGNORÉE. C'est la différence
//     observable avec d_flip_flop_async, et le piège classique du cours.
//
//  3) q_b == ~q à tout instant.
//
// Le modèle de référence est un simple `reg attendu` mis à jour par les mêmes
// règles écrites indépendamment du DUT.
//
// TIMING : on échantillonne toujours APRÈS le front (@(posedge clk); #1;)
// pour ne pas lire la sortie pendant la course de mise à jour, et on change
// les entrées juste après cette lecture, donc très loin du front suivant.
//=============================================================================
module tb_d_flip_flop;

    reg  clk = 1'b0;
    reg  rst, d;
    wire q, q_b;

    integer erreurs = 0;
    integer cycles  = 0;
    integer i;
    reg     attendu;

    d_flip_flop dut (.clk(clk), .rst(rst), .d(d), .q(q), .q_b(q_b));

    always #5 clk = ~clk;

    task verifier;
        begin
            if (q !== attendu) begin
                erreurs = erreurs + 1;
                $display("ECHEC cycle %0d (t=%0t) : rst=%b d=%b -> q=%b (attendu %b)",
                         cycles, $time, rst, d, q, attendu);
            end
            if (q_b !== ~q) begin
                erreurs = erreurs + 1;
                $display("ECHEC cycle %0d : q_b=%b n'est pas le complement de q=%b",
                         cycles, q_b, q);
            end
        end
    endtask

    // Applique (rst, d), franchit un front, puis compare a la reference.
    task pas;
        input in_rst, in_d;
        begin
            rst = in_rst;
            d   = in_d;
            @(posedge clk);
            #1;
            cycles  = cycles + 1;
            attendu = in_rst ? 1'b0 : in_d;
            verifier;
        end
    endtask

    initial begin
        rst = 1'b1;
        d   = 1'b0;

        // --- initialisation par reset ---------------------------------------
        pas(1'b1, 1'b1);        // reset prioritaire sur d
        pas(1'b1, 1'b0);

        // --- echantillonnage normal -----------------------------------------
        pas(1'b0, 1'b1);
        pas(1'b0, 1'b1);
        pas(1'b0, 1'b0);
        pas(1'b0, 1'b1);
        pas(1'b0, 1'b0);
        pas(1'b0, 1'b0);

        // --- sequence pseudo-aleatoire deterministe -------------------------
        for (i = 0; i < 20; i = i + 1)
            pas(1'b0, ((i * 7) % 3) == 0);

        // --- reset synchrone au milieu d'une sequence -----------------------
        pas(1'b0, 1'b1);
        pas(1'b1, 1'b1);        // remise a zero, malgre d = 1
        pas(1'b0, 1'b1);

        // --- q reste FIGEE entre deux fronts --------------------------------
        // q vaut 1 ; on secoue d au milieu du cycle : rien ne doit bouger.
        d = 1'b0;  #2 if (q !== 1'b1) begin
            erreurs = erreurs + 1;
            $display("ECHEC : q a change hors front (d=0)");
        end
        d = 1'b1;  #1 if (q !== 1'b1) begin
            erreurs = erreurs + 1;
            $display("ECHEC : q a change hors front (d=1)");
        end
        d = 1'b0;

        // --- IMPULSION DE RESET ENTRE DEUX FRONTS : doit etre IGNOREE -------
        // q vaut 1. On leve rst puis on le rabaisse avant le front montant.
        @(negedge clk);
        rst = 1'b1;
        #2 rst = 1'b0;          // impulsion terminee avant le front
        d   = 1'b1;
        @(posedge clk);
        #1;
        cycles = cycles + 1;
        if (q !== 1'b1) begin
            erreurs = erreurs + 1;
            $display("ECHEC : impulsion de reset entre deux fronts prise en compte (reset non synchrone ?)");
        end

        // --- le meme reset, maintenu jusqu'au front, doit AGIR --------------
        pas(1'b1, 1'b1);
        pas(1'b0, 1'b0);

        if (erreurs == 0)
            $display("PASS tb_d_flip_flop (%0d cycles : front montant, reset synchrone ignore hors front, q_b)", cycles);
        else
            $display("ECHEC tb_d_flip_flop : %0d erreur(s)", erreurs);
        $finish;
    end

endmodule
