`timescale 1ns / 1ps
//=============================================================================
// tb_register_file — banc d'essai du banc de registres RV32I (32 x 32 bits)
//
// Points vérifiés, dans l'ordre :
//   1) après reset, les 32 registres se lisent à zéro sur LES DEUX ports ;
//   2) LE REGISTRE 0 : on y écrit 0xDEADBEEF avec ecriture_en = 1, puis on
//      relit — il doit toujours valoir 0. C'est la propriété la plus
//      importante du module : x0 est une constante câblée, pas un registre ;
//   3) écriture puis relecture des 31 registres réels ;
//   4) LECTURE SIMULTANÉE sur les deux ports à des ADRESSES DIFFÉRENTES, ce
//      qui est le cas d'usage réel (add rd, rs1, rs2). Le couple lu doit être
//      (valeur(i), valeur(32-i)) : deux ports vraiment indépendants, pas un
//      seul port dupliqué ;
//   5) lecture simultanée de x0 et d'un registre non nul ;
//   6) ecriture_en = 0 : aucune modification ;
//   7) LECTURE PENDANT ÉCRITURE : la lecture combinatoire renvoie l'ancienne
//      valeur avant le front, la nouvelle après. C'est la sémantique qui
//      impose le forwarding dans un pipeline.
//
// Les valeurs de test valeur(k) mélangent l'indice sur 25 bits et une constante
// sur 7 bits : elles sont toutes distinctes et sollicitent l'ensemble des bits,
// ce qu'un simple « écrire k dans le registre k » ne ferait pas.
//=============================================================================
module tb_register_file;

    localparam LARGEUR    = 32;
    localparam PROFONDEUR = 32;

    reg         clk   = 1'b0;
    reg         reset = 1'b1;

    reg  [4:0]  adr_lecture_a = 5'd0;
    reg  [4:0]  adr_lecture_b = 5'd0;
    wire [31:0] donnee_a;
    wire [31:0] donnee_b;

    reg         ecriture_en     = 1'b0;
    reg  [4:0]  adr_ecriture    = 5'd0;
    reg  [31:0] donnee_ecriture = 32'd0;

    integer erreurs = 0;
    integer i;

    register_file #(
        .LARGEUR    (LARGEUR),
        .PROFONDEUR (PROFONDEUR)
    ) dut (
        .clk             (clk),
        .reset           (reset),
        .adr_lecture_a   (adr_lecture_a),
        .donnee_a        (donnee_a),
        .adr_lecture_b   (adr_lecture_b),
        .donnee_b        (donnee_b),
        .ecriture_en     (ecriture_en),
        .adr_ecriture    (adr_ecriture),
        .donnee_ecriture (donnee_ecriture)
    );

    always #5 clk = ~clk;

    // --- motif de test distinct pour chaque registre ---------------------
    function [31:0] valeur(input integer k);
        begin
            valeur = {k[4:0], k[4:0], k[4:0], k[4:0], k[4:0], 7'h5A};
        end
    endfunction

    // --- une écriture synchrone ------------------------------------------
    task ecrire(input [4:0] adr, input [31:0] val);
        begin
            adr_ecriture    = adr;
            donnee_ecriture = val;
            ecriture_en     = 1'b1;
            @(posedge clk); #1;
            ecriture_en     = 1'b0;
        end
    endtask

    initial begin
        // --- 1) reset : tout a zero -------------------------------------
        @(posedge clk); #1;
        reset = 1'b0;

        for (i = 0; i < PROFONDEUR; i = i + 1) begin
            adr_lecture_a = i[4:0];
            adr_lecture_b = i[4:0];
            #1;
            if ((donnee_a !== 32'd0) || (donnee_b !== 32'd0)) begin
                erreurs = erreurs + 1;
                if (erreurs < 8)
                    $display("ECHEC reset : x%0d vaut a=%h b=%h (attendu 0)",
                             i, donnee_a, donnee_b);
            end
        end

        // --- 2) le registre 0 ignore les ecritures ----------------------
        @(posedge clk); #1;
        ecrire(5'd0, 32'hDEAD_BEEF);
        adr_lecture_a = 5'd0;
        adr_lecture_b = 5'd0;
        #1;
        if (donnee_a !== 32'd0) begin
            erreurs = erreurs + 1;
            $display("ECHEC x0 : port A lit %h apres ecriture de DEADBEEF (attendu 0)", donnee_a);
        end
        if (donnee_b !== 32'd0) begin
            erreurs = erreurs + 1;
            $display("ECHEC x0 : port B lit %h apres ecriture de DEADBEEF (attendu 0)", donnee_b);
        end

        // et l'ecriture ne doit avoir contamine aucun autre registre
        for (i = 1; i < PROFONDEUR; i = i + 1) begin
            adr_lecture_a = i[4:0];
            #1;
            if (donnee_a !== 32'd0) begin
                erreurs = erreurs + 1;
                if (erreurs < 8)
                    $display("ECHEC : x%0d=%h apres une ecriture dans x0 (attendu 0)",
                             i, donnee_a);
            end
        end

        // --- 3) ecriture des 31 registres reels -------------------------
        @(posedge clk); #1;
        for (i = 1; i < PROFONDEUR; i = i + 1)
            ecrire(i[4:0], valeur(i));

        // --- 4) lecture SIMULTANEE sur deux adresses differentes --------
        for (i = 1; i < PROFONDEUR; i = i + 1) begin
            adr_lecture_a = i[4:0];
            adr_lecture_b = (PROFONDEUR - i);
            #1;
            if (donnee_a !== valeur(i)) begin
                erreurs = erreurs + 1;
                if (erreurs < 8)
                    $display("ECHEC port A : x%0d=%h (attendu %h)", i, donnee_a, valeur(i));
            end
            if (donnee_b !== valeur(PROFONDEUR - i)) begin
                erreurs = erreurs + 1;
                if (erreurs < 8)
                    $display("ECHEC port B : x%0d=%h (attendu %h)",
                             PROFONDEUR - i, donnee_b, valeur(PROFONDEUR - i));
            end
        end

        // --- 5) x0 sur un port, registre reel sur l'autre ---------------
        adr_lecture_a = 5'd0;
        adr_lecture_b = 5'd17;
        #1;
        if (donnee_a !== 32'd0) begin
            erreurs = erreurs + 1;
            $display("ECHEC lecture simultanee : x0 lit %h (attendu 0)", donnee_a);
        end
        if (donnee_b !== valeur(17)) begin
            erreurs = erreurs + 1;
            $display("ECHEC lecture simultanee : x17 lit %h (attendu %h)", donnee_b, valeur(17));
        end

        // --- 6) ecriture_en = 0 : rien ne change ------------------------
        @(posedge clk); #1;
        adr_ecriture    = 5'd9;
        donnee_ecriture = 32'h0BAD_0BAD;
        ecriture_en     = 1'b0;
        @(posedge clk); #1;
        adr_lecture_a = 5'd9;
        #1;
        if (donnee_a !== valeur(9)) begin
            erreurs = erreurs + 1;
            $display("ECHEC : x9=%h alors que ecriture_en=0 (attendu %h)", donnee_a, valeur(9));
        end

        // --- 7) lecture pendant ecriture (meme adresse) -----------------
        @(posedge clk); #1;
        adr_lecture_a   = 5'd7;
        adr_ecriture    = 5'd7;
        donnee_ecriture = 32'hFFFF_0000;
        ecriture_en     = 1'b1;
        #1;
        if (donnee_a !== valeur(7)) begin
            erreurs = erreurs + 1;
            $display("ECHEC read-during-write : avant le front x7=%h (attendu l'ancienne valeur %h)",
                     donnee_a, valeur(7));
        end
        @(posedge clk); #1;
        ecriture_en = 1'b0;
        if (donnee_a !== 32'hFFFF_0000) begin
            erreurs = erreurs + 1;
            $display("ECHEC read-during-write : apres le front x7=%h (attendu FFFF0000)", donnee_a);
        end

        if (erreurs == 0)
            $display("PASS tb_register_file (32x32 : x0 cable a zero, 31 registres ecrits/relus, 2 ports simultanes, read-during-write)");
        else
            $display("ECHEC tb_register_file : %0d erreur(s)", erreurs);
        $finish;
    end

endmodule
