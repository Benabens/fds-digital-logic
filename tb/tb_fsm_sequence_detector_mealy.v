`timescale 1ns / 1ps
//=============================================================================
// tb_fsm_sequence_detector_mealy — banc d'essai du détecteur 1011 (Mealy)
//
// Même trame et même modèle de référence que tb_fsm_sequence_detector_moore :
//
//     trame = 0 1 0 1 1 0 1 1 0 0 1 0 1 1 0 1
//               <--------->  1011011 : deux occurrences qui se chevauchent
//
// SEULE DIFFÉRENCE, ET ELLE EST INSTRUCTIVE — la date d'observation.
// La sortie de Mealy est COMBINATOIRE : elle vaut 1 PENDANT le cycle où le
// dernier bit du motif est présenté, c'est-à-dire AVANT le front d'horloge qui
// clôt ce cycle. L'échantillonner après le front n'aurait aucun sens : à cet
// instant l'état a déjà changé et l'entrée n'est plus la bonne.
//
// On procède donc comme le ferait un vrai circuit consommateur d'une sortie de
// Mealy : on la fait traverser une bascule cadencée par la même horloge.
//
//     always @(posedge clk) detecte_ech <= detecte;
//
// Grâce à l'affectation non bloquante, cette bascule capture la valeur de
// `detecte` telle qu'elle était JUSTE AVANT le front — exactement la valeur
// utile. On peut alors respecter la règle d'échantillonnage habituelle
// (@(posedge clk); #1;) en lisant `detecte_ech`.
//
// Conséquence directe : `detecte_ech` de Mealy coïncide cycle pour cycle avec
// le `detecte` brut de Moore. C'est la traduction expérimentale de « Mealy
// réagit un cycle plus tôt ».
//=============================================================================
module tb_fsm_sequence_detector_mealy;

    localparam LONGUEUR = 16;

    reg  clk   = 1'b0;
    reg  reset = 1'b1;
    reg  serie = 1'b0;
    wire detecte;

    reg  detecte_ech = 1'b0;    // sortie de Mealy vue à travers une bascule

    reg [0:LONGUEUR-1] trame = 16'b0101101100101101;

    reg [3:0] fenetre;          // modèle de référence : les 4 derniers bits
    reg       attendu;
    integer   i;
    integer   erreurs    = 0;
    integer   detections = 0;

    fsm_sequence_detector_mealy dut (
        .clk     (clk),
        .reset   (reset),
        .serie   (serie),
        .detecte (detecte)
    );

    always #5 clk = ~clk;

    // échantillonnage synchrone de la sortie combinatoire de Mealy
    always @(posedge clk) detecte_ech <= detecte;

    initial begin
        fenetre = 4'b0000;

        // --- cycle de reset ---------------------------------------------
        // On regarde ici la sortie BRUTE et non `detecte_ech` : avant le tout
        // premier front, l'état de la machine vaut encore X (les bascules ne
        // sont pas initialisées) et la bascule d'échantillonnage aurait donc
        // capturé un X sans signification. Après le front de reset, l'état
        // vaut S0 et la sortie combinatoire de Mealy est définie.
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

            if (detecte_ech !== attendu) begin
                erreurs = erreurs + 1;
                if (erreurs < 8)
                    $display("ECHEC bit %0d (serie=%b, fenetre=%b) : detecte=%b (attendu %b)",
                             i, trame[i], fenetre, detecte_ech, attendu);
            end
        end

        // --- garde-fou sur le modèle de référence lui-même --------------
        if (detections != 3) begin
            erreurs = erreurs + 1;
            $display("ECHEC : la trame devait contenir 3 occurrences, le modele en compte %0d",
                     detections);
        end

        // --- reset : la sortie doit retomber -----------------------------
        reset = 1'b1;
        serie = 1'b1;
        @(posedge clk); #1;
        serie = 1'b1;
        @(posedge clk); #1;
        if (detecte_ech !== 1'b0) begin
            erreurs = erreurs + 1;
            $display("ECHEC : detecte=%b alors que reset est actif", detecte_ech);
        end

        if (erreurs == 0)
            $display("PASS tb_fsm_sequence_detector_mealy (16 bits, 3 occurrences dont 2 chevauchantes, sortie de Mealy echantillonnee)");
        else
            $display("ECHEC tb_fsm_sequence_detector_mealy : %0d erreur(s)", erreurs);
        $finish;
    end

endmodule
