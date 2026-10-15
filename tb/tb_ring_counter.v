`timescale 1ns / 1ps
//=============================================================================
// tb_ring_counter — banc d'essai du compteur en anneau et de sa variante Johnson
//
// Les DEUX configurations sont instanciées côte à côte sur la même horloge, ce
// qui permet de comparer directement leurs séquences.
//
//   anneau  (N=4) : 0001 0010 0100 1000   -> période 4, toujours « one-hot »
//   Johnson (N=4) : 0000 0001 0011 0111
//                   1111 1110 1100 1000   -> période 8, un seul bit change
//
// Les deux séquences attendues sont écrites en toutes lettres dans le banc : ce
// sont des constantes du problème, pas un recalcul de l'implémentation.
//
// Vérifications :
//   - conformité cycle par cycle sur 16 cycles (4 périodes d'anneau,
//     2 périodes de Johnson) ;
//   - invariant « one-hot » de l'anneau à chaque cycle ;
//   - invariant « distance de Hamming = 1 » entre deux états successifs du
//     compteur de Johnson (propriété de code de Gray) ;
//   - `enable = 0` gèle réellement les deux compteurs.
//=============================================================================
module tb_ring_counter;

    localparam N = 4;

    reg  clk    = 1'b0;
    reg  reset  = 1'b1;
    reg  enable = 1'b1;
    wire [N-1:0] q_anneau;
    wire [N-1:0] q_johnson;

    reg [N-1:0] seq_anneau  [0:3];
    reg [N-1:0] seq_johnson [0:7];

    reg [N-1:0] gele_anneau;
    reg [N-1:0] gele_johnson;
    reg [N-1:0] precedent_johnson;
    reg [N-1:0] difference;

    integer erreurs = 0;
    integer i, b, nb_uns, nb_changes;

    ring_counter #(.N(N), .JOHNSON(0)) anneau (
        .clk (clk), .reset (reset), .enable (enable), .q (q_anneau)
    );

    ring_counter #(.N(N), .JOHNSON(1)) tordu (
        .clk (clk), .reset (reset), .enable (enable), .q (q_johnson)
    );

    always #5 clk = ~clk;

    initial begin
        seq_anneau[0] = 4'b0001;
        seq_anneau[1] = 4'b0010;
        seq_anneau[2] = 4'b0100;
        seq_anneau[3] = 4'b1000;

        seq_johnson[0] = 4'b0000;
        seq_johnson[1] = 4'b0001;
        seq_johnson[2] = 4'b0011;
        seq_johnson[3] = 4'b0111;
        seq_johnson[4] = 4'b1111;
        seq_johnson[5] = 4'b1110;
        seq_johnson[6] = 4'b1100;
        seq_johnson[7] = 4'b1000;

        // --- front de reset : chargement de l'etat initial --------------
        @(posedge clk); #1;
        reset = 1'b0;

        precedent_johnson = q_johnson;

        // --- 16 cycles : 4 periodes d'anneau, 2 de Johnson --------------
        for (i = 0; i < 16; i = i + 1) begin
            // conformite aux sequences attendues
            if (q_anneau !== seq_anneau[i % 4]) begin
                erreurs = erreurs + 1;
                if (erreurs < 8)
                    $display("ECHEC anneau cycle %0d : q=%b (attendu %b)",
                             i, q_anneau, seq_anneau[i % 4]);
            end
            if (q_johnson !== seq_johnson[i % 8]) begin
                erreurs = erreurs + 1;
                if (erreurs < 8)
                    $display("ECHEC Johnson cycle %0d : q=%b (attendu %b)",
                             i, q_johnson, seq_johnson[i % 8]);
            end

            // invariant one-hot de l'anneau
            nb_uns = 0;
            for (b = 0; b < N; b = b + 1)
                if (q_anneau[b] === 1'b1) nb_uns = nb_uns + 1;
            if (nb_uns !== 1) begin
                erreurs = erreurs + 1;
                if (erreurs < 8)
                    $display("ECHEC one-hot cycle %0d : q=%b contient %0d bits a 1",
                             i, q_anneau, nb_uns);
            end

            // invariant de Gray du compteur de Johnson (sauf au tout premier
            // echantillon, ou il n'y a pas encore de precedent)
            if (i > 0) begin
                difference = q_johnson ^ precedent_johnson;
                nb_changes = 0;
                for (b = 0; b < N; b = b + 1)
                    if (difference[b] === 1'b1) nb_changes = nb_changes + 1;
                if (nb_changes !== 1) begin
                    erreurs = erreurs + 1;
                    if (erreurs < 8)
                        $display("ECHEC Gray cycle %0d : %b -> %b, %0d bit(s) change(s)",
                                 i, precedent_johnson, q_johnson, nb_changes);
                end
            end
            precedent_johnson = q_johnson;

            @(posedge clk); #1;
        end

        // --- enable = 0 : gel des deux compteurs ------------------------
        enable       = 1'b0;
        gele_anneau  = q_anneau;
        gele_johnson = q_johnson;
        for (i = 0; i < 5; i = i + 1) begin
            @(posedge clk); #1;
            if (q_anneau !== gele_anneau) begin
                erreurs = erreurs + 1;
                if (erreurs < 8)
                    $display("ECHEC gel anneau : q=%b (attendu %b)", q_anneau, gele_anneau);
            end
            if (q_johnson !== gele_johnson) begin
                erreurs = erreurs + 1;
                if (erreurs < 8)
                    $display("ECHEC gel Johnson : q=%b (attendu %b)", q_johnson, gele_johnson);
            end
        end

        // --- reset en cours de route : retour a l'etat initial ----------
        reset  = 1'b1;
        enable = 1'b1;
        @(posedge clk); #1;
        if (q_anneau !== seq_anneau[0]) begin
            erreurs = erreurs + 1;
            $display("ECHEC reset anneau : q=%b (attendu %b)", q_anneau, seq_anneau[0]);
        end
        if (q_johnson !== seq_johnson[0]) begin
            erreurs = erreurs + 1;
            $display("ECHEC reset Johnson : q=%b (attendu %b)", q_johnson, seq_johnson[0]);
        end

        if (erreurs == 0)
            $display("PASS tb_ring_counter (N=4 : 4 periodes d'anneau one-hot, 2 periodes de Johnson en code de Gray, gel et reset)");
        else
            $display("ECHEC tb_ring_counter : %0d erreur(s)", erreurs);
        $finish;
    end

endmodule
