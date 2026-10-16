`timescale 1ns / 1ps
//=============================================================================
// tb_fsm_sequence_detector_moore — banc d'essai du détecteur 1011 (Moore)
//
// La trame de test est choisie pour contenir le cas piège du RECOUVREMENT :
//
//     trame = 0 1 0 1 1 0 1 1 0 0 1 0 1 1 0 1
//     index   0 1 2 3 4 5 6 7 8 9 ...
//               <--------->
//               les bits 1..7 forment 1011011, soit DEUX occurrences de 1011
//               qui partagent le bit 4 : une machine sans recouvrement n'en
//               verrait qu'une seule.
//
// La référence est recalculée indépendamment du circuit, à partir de la
// DÉFINITION du problème : une fenêtre glissante de 4 bits, et l'on attend une
// détection exactement quand cette fenêtre vaut 1011. On ne réimplémente donc
// pas l'automate — sinon on ne vérifierait que la cohérence d'une erreur avec
// elle-même.
//
// ÉCHANTILLONNAGE. La sortie de Moore est enregistrée : après le front qui
// consomme le bit d'indice i, `detecte` reflète l'état atteint, donc la
// détection du motif se terminant sur ce bit i. On échantillonne après le front
// (@(posedge clk); #1;) et on compare à la fenêtre mise à jour avec le bit i.
//=============================================================================
module tb_fsm_sequence_detector_moore;

    localparam LONGUEUR = 16;

    reg  clk   = 1'b0;
    reg  reset = 1'b1;
    reg  serie = 1'b0;
    wire detecte;

    // indexation « de gauche à droite » : trame[0] est le premier bit émis
    reg [0:LONGUEUR-1] trame = 16'b0101101100101101;

    reg [3:0] fenetre;      // modèle de référence : les 4 derniers bits reçus
    reg       attendu;
    integer   i;
    integer   erreurs    = 0;
    integer   detections = 0;

    fsm_sequence_detector_moore dut (
        .clk     (clk),
        .reset   (reset),
        .serie   (serie),
        .detecte (detecte)
    );

    always #5 clk = ~clk;

    initial begin
        fenetre = 4'b0000;

        // --- cycle de reset ---------------------------------------------
        serie = 1'b0;
        @(posedge clk); #1;
        if (detecte !== 1'b0) begin
            erreurs = erreurs + 1;
            $display("ECHEC : detecte=%b apres reset (attendu 0)", detecte);
        end
        reset = 1'b0;

        // --- émission de la trame, bit par bit --------------------------
        for (i = 0; i < LONGUEUR; i = i + 1) begin
            serie = trame[i];
            @(posedge clk); #1;

            fenetre = {fenetre[2:0], trame[i]};
            attendu = (fenetre == 4'b1011);
            if (attendu) detections = detections + 1;

            if (detecte !== attendu) begin
                erreurs = erreurs + 1;
                if (erreurs < 8)
                    $display("ECHEC bit %0d (serie=%b, fenetre=%b) : detecte=%b (attendu %b)",
                             i, trame[i], fenetre, detecte, attendu);
            end
        end

        // --- garde-fou sur le modèle de référence lui-même --------------
        if (detections != 3) begin
            erreurs = erreurs + 1;
            $display("ECHEC : la trame devait contenir 3 occurrences, le modele en compte %0d",
                     detections);
        end

        // --- le reset doit ramener la machine a l'etat initial ----------
        reset = 1'b1;
        serie = 1'b1;
        @(posedge clk); #1;
        if (detecte !== 1'b0) begin
            erreurs = erreurs + 1;
            $display("ECHEC : detecte=%b alors que reset est actif", detecte);
        end

        if (erreurs == 0)
            $display("PASS tb_fsm_sequence_detector_moore (16 bits, 3 occurrences dont 2 chevauchantes, reset verifie)");
        else
            $display("ECHEC tb_fsm_sequence_detector_moore : %0d erreur(s)", erreurs);
        $finish;
    end

endmodule
