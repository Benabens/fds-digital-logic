`timescale 1ns / 1ps
//=============================================================================
// tb_ram_sync — banc d'essai de la RAM synchrone
//
// Configuration testée : 16 mots de 8 bits (les valeurs par défaut).
//
// Le point délicat d'une RAM synchrone est la LATENCE : l'adresse est présentée
// pendant un cycle, la donnée n'apparaît qu'au cycle suivant. Le banc respecte
// donc scrupuleusement la chronologie :
//
//     adresse = k;  @(posedge clk); #1;   -> donnee_lecture vaut memoire[k]
//
// Étapes :
//   1) écriture des 16 mots avec un motif distinct par adresse ;
//   2) relecture séquentielle des 16 mots ;
//   3) relecture dans un ORDRE DIFFÉRENT (adresses entrelacées), pour écarter
//      un modèle qui se contenterait d'incrémenter un compteur interne ;
//   4) POLITIQUE READ-FIRST : on lit et on écrit la même adresse dans le même
//      cycle. La sortie doit donner l'ANCIEN contenu, et le nouveau doit être
//      visible au cycle d'après ;
//   5) ecriture_en = 0 : la mémoire n'est pas modifiée.
//=============================================================================
module tb_ram_sync;

    localparam LARGEUR    = 8;
    localparam PROFONDEUR = 16;

    reg        clk             = 1'b0;
    reg        ecriture_en     = 1'b0;
    reg  [3:0] adresse         = 4'd0;
    reg  [7:0] donnee_ecriture = 8'd0;
    wire [7:0] donnee_lecture;

    integer erreurs = 0;
    integer i, k;

    ram_sync #(
        .LARGEUR    (LARGEUR),
        .PROFONDEUR (PROFONDEUR)
    ) dut (
        .clk             (clk),
        .ecriture_en     (ecriture_en),
        .adresse         (adresse),
        .donnee_ecriture (donnee_ecriture),
        .donnee_lecture  (donnee_lecture)
    );

    always #5 clk = ~clk;

    // motif distinct par adresse, bits de poids fort et faible sollicites
    function [7:0] motif(input integer k);
        begin
            motif = {k[3:0], ~k[3:0]};
        end
    endfunction

    initial begin
        // --- 1) ecriture des 16 mots ------------------------------------
        for (i = 0; i < PROFONDEUR; i = i + 1) begin
            adresse         = i[3:0];
            donnee_ecriture = motif(i);
            ecriture_en     = 1'b1;
            @(posedge clk); #1;
        end
        ecriture_en = 1'b0;

        // --- 2) relecture sequentielle ----------------------------------
        for (i = 0; i < PROFONDEUR; i = i + 1) begin
            adresse = i[3:0];
            @(posedge clk); #1;
            if (donnee_lecture !== motif(i)) begin
                erreurs = erreurs + 1;
                if (erreurs < 8)
                    $display("ECHEC lecture adr %0d : %h (attendu %h)",
                             i, donnee_lecture, motif(i));
            end
        end

        // --- 3) relecture dans un ordre entrelace -----------------------
        for (i = 0; i < PROFONDEUR; i = i + 1) begin
            k       = (i * 7) % PROFONDEUR;   // 7 premier avec 16 : parcourt tout
            adresse = k[3:0];
            @(posedge clk); #1;
            if (donnee_lecture !== motif(k)) begin
                erreurs = erreurs + 1;
                if (erreurs < 8)
                    $display("ECHEC lecture entrelacee adr %0d : %h (attendu %h)",
                             k, donnee_lecture, motif(k));
            end
        end

        // --- 4) read-first : lecture et ecriture au meme cycle ----------
        adresse         = 4'd5;
        donnee_ecriture = 8'hA5;
        ecriture_en     = 1'b1;
        @(posedge clk); #1;
        ecriture_en     = 1'b0;
        if (donnee_lecture !== motif(5)) begin
            erreurs = erreurs + 1;
            $display("ECHEC read-first : sortie %h pendant l'ecriture (attendu l'ancien contenu %h)",
                     donnee_lecture, motif(5));
        end
        adresse = 4'd5;
        @(posedge clk); #1;
        if (donnee_lecture !== 8'hA5) begin
            erreurs = erreurs + 1;
            $display("ECHEC : apres ecriture adr 5 = %h (attendu A5)", donnee_lecture);
        end

        // --- 5) ecriture_en = 0 : aucune modification -------------------
        adresse         = 4'd5;
        donnee_ecriture = 8'h3C;
        ecriture_en     = 1'b0;
        @(posedge clk); #1;
        adresse = 4'd5;
        @(posedge clk); #1;
        if (donnee_lecture !== 8'hA5) begin
            erreurs = erreurs + 1;
            $display("ECHEC : adr 5 = %h alors que ecriture_en=0 (attendu A5)", donnee_lecture);
        end

        if (erreurs == 0)
            $display("PASS tb_ram_sync (16x8 : ecriture/relecture, ordre entrelace, latence d'un cycle, politique read-first)");
        else
            $display("ECHEC tb_ram_sync : %0d erreur(s)", erreurs);
        $finish;
    end

endmodule
