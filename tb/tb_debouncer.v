`timescale 1ns / 1ps
//=============================================================================
// tb_debouncer — banc d'essai de l'anti-rebond
//
// Le banc rejoue le scénario physique d'un appui sur un bouton mécanique, avec
// STABLE_CYCLES = 4 :
//
//   A) repos                      : brut = 0 pendant 6 cycles
//   B) PARASITE de 3 cycles       : brut = 1 pendant 3 cycles seulement.
//      3 < STABLE_CYCLES, donc le filtre doit l'IGNORER complètement.
//      C'est le cas limite : une impulsion d'un cycle de plus serait validée.
//   C) APPUI avec rebonds         : 1, 0, 1, 1, 0 puis 1 stable pendant 15
//      cycles. Aucun des paliers de rebond ne dure assez longtemps ; seule la
//      phase stable finale doit faire monter `propre`.
//   D) RELÂCHEMENT avec rebonds   : 0, 1, 0, 0, 1 puis 0 stable pendant 15
//      cycles. Symétrique du précédent.
//
// Vérifications :
//   - `propre` reste à 0 pendant toute la phase B (le parasite ne passe pas) ;
//   - `propre` vaut 1 à la fin de C et 0 à la fin de D ;
//   - `front_montant` et `front_descendant` émettent CHACUN exactement UNE
//     impulsion sur l'ensemble du scénario. C'est le test décisif : un
//     compteur branché directement sur le bouton en compterait une dizaine.
//=============================================================================
module tb_debouncer;

    localparam STABLE_CYCLES = 4;

    reg  clk   = 1'b0;
    reg  reset = 1'b1;
    reg  brut  = 1'b0;
    wire propre, front_montant, front_descendant;

    integer erreurs        = 0;
    integer nb_montants    = 0;
    integer nb_descendants = 0;
    integer i;

    debouncer #(.STABLE_CYCLES(STABLE_CYCLES)) dut (
        .clk              (clk),
        .reset            (reset),
        .brut             (brut),
        .propre           (propre),
        .front_montant    (front_montant),
        .front_descendant (front_descendant)
    );

    always #5 clk = ~clk;

    // --- un coup d'horloge, avec comptage des impulsions de front -------
    task pas;
        begin
            @(posedge clk); #1;
            if (front_montant    === 1'b1) nb_montants    = nb_montants    + 1;
            if (front_descendant === 1'b1) nb_descendants = nb_descendants + 1;
        end
    endtask

    initial begin
        // --- reset ------------------------------------------------------
        brut = 1'b0;
        pas;
        reset = 1'b0;
        if (propre !== 1'b0) begin
            erreurs = erreurs + 1;
            $display("ECHEC : propre=%b apres reset (attendu 0)", propre);
        end

        // --- A) repos ---------------------------------------------------
        for (i = 0; i < 6; i = i + 1) pas;
        if (propre !== 1'b0) begin
            erreurs = erreurs + 1;
            $display("ECHEC : propre=%b au repos (attendu 0)", propre);
        end

        // --- B) parasite de 3 cycles (< STABLE_CYCLES) : doit etre filtre
        brut = 1'b1;
        for (i = 0; i < 3; i = i + 1) begin
            pas;
            if (propre !== 1'b0) begin
                erreurs = erreurs + 1;
                if (erreurs < 8)
                    $display("ECHEC : parasite propage pendant l'impulsion (cycle %0d)", i);
            end
        end
        brut = 1'b0;
        for (i = 0; i < 12; i = i + 1) begin
            pas;
            if (propre !== 1'b0) begin
                erreurs = erreurs + 1;
                if (erreurs < 8)
                    $display("ECHEC : parasite propage apres l'impulsion (cycle %0d)", i);
            end
        end

        // --- C) appui avec rebonds, puis niveau stable ------------------
        brut = 1'b1; pas;
        brut = 1'b0; pas;
        brut = 1'b1; pas; pas;
        brut = 1'b0; pas;
        brut = 1'b1;
        for (i = 0; i < 15; i = i + 1) pas;
        if (propre !== 1'b1) begin
            erreurs = erreurs + 1;
            $display("ECHEC : propre=%b apres un appui stable (attendu 1)", propre);
        end

        // --- D) relachement avec rebonds, puis niveau stable ------------
        brut = 1'b0; pas;
        brut = 1'b1; pas;
        brut = 1'b0; pas; pas;
        brut = 1'b1; pas;
        brut = 1'b0;
        for (i = 0; i < 15; i = i + 1) pas;
        if (propre !== 1'b0) begin
            erreurs = erreurs + 1;
            $display("ECHEC : propre=%b apres un relachement stable (attendu 0)", propre);
        end

        // --- bilan des impulsions de front ------------------------------
        if (nb_montants !== 1) begin
            erreurs = erreurs + 1;
            $display("ECHEC : %0d impulsion(s) front_montant (attendu 1)", nb_montants);
        end
        if (nb_descendants !== 1) begin
            erreurs = erreurs + 1;
            $display("ECHEC : %0d impulsion(s) front_descendant (attendu 1)", nb_descendants);
        end

        if (erreurs == 0)
            $display("PASS tb_debouncer (parasite de 3 cycles filtre, 1 front montant et 1 front descendant sur 60 cycles de rebonds)");
        else
            $display("ECHEC tb_debouncer : %0d erreur(s)", erreurs);
        $finish;
    end

endmodule
