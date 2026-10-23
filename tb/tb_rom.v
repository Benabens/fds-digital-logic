`timescale 1ns / 1ps
//=============================================================================
// tb_rom — banc d'essai de la ROM combinatoire
//
// La ROM par défaut contient la table des carrés sur 16 mots de 8 bits.
// La référence est recalculée par le banc à partir de la SPÉCIFICATION
// (contenu[i] = i*i), et non recopiée depuis le module.
//
// Vérifications :
//   1) balayage exhaustif des 16 adresses, dans l'ordre ;
//   2) balayage dans un ordre entrelacé, puis retour sur une adresse déjà lue :
//      une ROM est sans mémoire d'état, la même adresse doit toujours rendre
//      la même valeur ;
//   3) SORTIE PUREMENT COMBINATOIRE : deux adresses différentes présentées au
//      cours du MÊME cycle d'horloge doivent produire deux valeurs différentes
//      sans qu'aucun front ne survienne. C'est ce qui distingue la ROM de la
//      RAM synchrone du même répertoire.
//
// Aucune horloge n'est nécessaire pour le circuit lui-même ; on en génère une
// tout de même pour le point 3, afin de montrer qu'elle ne joue aucun rôle.
//=============================================================================
module tb_rom;

    localparam LARGEUR    = 8;
    localparam PROFONDEUR = 16;

    reg        clk     = 1'b0;
    reg  [3:0] adresse = 4'd0;
    wire [7:0] donnee;

    reg [7:0] attendu;
    reg [7:0] releve_a;
    reg [7:0] releve_b;

    integer erreurs = 0;
    integer i, k;

    rom #(
        .LARGEUR    (LARGEUR),
        .PROFONDEUR (PROFONDEUR)
    ) dut (
        .adresse (adresse),
        .donnee  (donnee)
    );

    always #5 clk = ~clk;

    initial begin
        // --- 1) balayage exhaustif dans l'ordre -------------------------
        for (i = 0; i < PROFONDEUR; i = i + 1) begin
            adresse = i[3:0];
            #1;
            attendu = i * i;
            if (donnee !== attendu) begin
                erreurs = erreurs + 1;
                if (erreurs < 8)
                    $display("ECHEC adr %0d : %0d (attendu %0d)", i, donnee, attendu);
            end
        end

        // --- 2) balayage entrelace, la ROM est sans etat ----------------
        for (i = 0; i < PROFONDEUR; i = i + 1) begin
            k       = (i * 7) % PROFONDEUR;   // 7 premier avec 16
            adresse = k[3:0];
            #1;
            attendu = k * k;
            if (donnee !== attendu) begin
                erreurs = erreurs + 1;
                if (erreurs < 8)
                    $display("ECHEC adr entrelacee %0d : %0d (attendu %0d)", k, donnee, attendu);
            end
        end

        // --- 3) sortie combinatoire : pas besoin de front d'horloge -----
        @(posedge clk); #1;          // on se cale juste apres un front
        adresse  = 4'd3;
        #1;
        releve_a = donnee;           // doit valoir 9
        adresse  = 4'd12;
        #1;
        releve_b = donnee;           // doit valoir 144, dans le MEME cycle
        if (releve_a !== 8'd9) begin
            erreurs = erreurs + 1;
            $display("ECHEC combinatoire : adr 3 -> %0d (attendu 9)", releve_a);
        end
        if (releve_b !== 8'd144) begin
            erreurs = erreurs + 1;
            $display("ECHEC combinatoire : adr 12 -> %0d (attendu 144)", releve_b);
        end

        if (erreurs == 0)
            $display("PASS tb_rom (16x8 : 16 adresses balayees deux fois, sortie combinatoire sans horloge)");
        else
            $display("ECHEC tb_rom : %0d erreur(s)", erreurs);
        $finish;
    end

endmodule
