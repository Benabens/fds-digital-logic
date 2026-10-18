`timescale 1ns / 1ps
//=============================================================================
// tb_fsm_traffic_light — banc d'essai du contrôleur de feux
//
// Durées volontairement courtes (3 / 2 / 4 cycles) pour garder une simulation
// lisible et bornée : le paramétrage est justement là pour ça.
//
// Quatre propriétés sont vérifiées :
//   1) SÛRETÉ, à CHAQUE cycle : exactement un feu allumé. C'est l'invariant
//      critique — deux feux verts simultanés seraient un accident.
//   2) Le reset conduit bien à l'état sûr ROUGE, et la phase rouge dure
//      exactement DUREE_ROUGE cycles.
//   3) Sans véhicule (capteur = 0), le feu RESTE au vert indéfiniment : on
//      l'observe pendant 20 cycles, soit largement plus que DUREE_VERT.
//   4) Avec véhicule, le cycle complet vert -> orange -> rouge -> vert se
//      déroule, chaque phase durant exactement sa durée paramétrée.
//
// La mesure des durées se fait avec la tâche `compter_phase`, qui compte les
// échantillons consécutifs où la phase demandée est active et laisse la
// simulation positionnée sur le PREMIER échantillon de la phase suivante — ce
// qui permet d'enchaîner les mesures sans perdre de cycle.
//=============================================================================
module tb_fsm_traffic_light;

    localparam DUREE_VERT   = 3;
    localparam DUREE_ORANGE = 2;
    localparam DUREE_ROUGE  = 4;

    localparam PHASE_VERT   = 0;
    localparam PHASE_ORANGE = 1;
    localparam PHASE_ROUGE  = 2;

    reg  clk     = 1'b0;
    reg  reset   = 1'b1;
    reg  capteur = 1'b0;
    wire vert, orange, rouge;

    integer erreurs = 0;
    integer n;
    integer i;

    fsm_traffic_light #(
        .DUREE_VERT   (DUREE_VERT),
        .DUREE_ORANGE (DUREE_ORANGE),
        .DUREE_ROUGE  (DUREE_ROUGE)
    ) dut (
        .clk     (clk),
        .reset   (reset),
        .capteur (capteur),
        .vert    (vert),
        .orange  (orange),
        .rouge   (rouge)
    );

    always #5 clk = ~clk;

    // --- un coup d'horloge, avec vérification de l'invariant de sûreté ---
    task pas;
        begin
            @(posedge clk); #1;
            case ({vert, orange, rouge})
                3'b100, 3'b010, 3'b001: ;   // exactement un feu allumé : OK
                default: begin
                    erreurs = erreurs + 1;
                    if (erreurs < 8)
                        $display("ECHEC surete a t=%0t : vert=%b orange=%b rouge=%b",
                                 $time, vert, orange, rouge);
                end
            endcase
        end
    endtask

    // --- la phase demandée est-elle active ? ----------------------------
    function phase_active(input integer code);
        begin
            case (code)
                PHASE_VERT:   phase_active = vert;
                PHASE_ORANGE: phase_active = orange;
                PHASE_ROUGE:  phase_active = rouge;
                default:      phase_active = 1'b0;
            endcase
        end
    endfunction

    // --- compte les cycles consécutifs de la phase `code` ----------------
    // En sortie, l'échantillon courant est le premier de la phase suivante.
    task compter_phase(input integer code, output integer nb);
        begin
            nb = 0;
            while (phase_active(code) && (nb < 40)) begin
                nb = nb + 1;
                pas;
            end
        end
    endtask

    initial begin
        // --- 1) reset : etat sur ROUGE ----------------------------------
        capteur = 1'b0;
        pas;
        reset = 1'b0;
        if (rouge !== 1'b1) begin
            erreurs = erreurs + 1;
            $display("ECHEC : apres reset le feu devrait etre ROUGE (v=%b o=%b r=%b)",
                     vert, orange, rouge);
        end

        // --- 2) duree de la phase rouge ---------------------------------
        compter_phase(PHASE_ROUGE, n);
        if (n !== DUREE_ROUGE) begin
            erreurs = erreurs + 1;
            $display("ECHEC : phase ROUGE de %0d cycles (attendu %0d)", n, DUREE_ROUGE);
        end
        if (vert !== 1'b1) begin
            erreurs = erreurs + 1;
            $display("ECHEC : apres le rouge le feu devrait passer au VERT");
        end

        // --- 3) sans vehicule, le vert ne s'interrompt jamais -----------
        for (i = 0; i < 20; i = i + 1) begin
            if (vert !== 1'b1) begin
                erreurs = erreurs + 1;
                if (erreurs < 8)
                    $display("ECHEC : le feu a quitte le VERT sans vehicule (cycle %0d)", i);
            end
            pas;
        end

        // --- 4) arrivee d'un vehicule : cycle complet -------------------
        capteur = 1'b1;

        // la duree minimale de vert est deja largement ecoulee : la phase
        // verte doit se terminer immediatement (1 cycle restant)
        compter_phase(PHASE_VERT, n);
        if ((n < 1) || (n > DUREE_VERT)) begin
            erreurs = erreurs + 1;
            $display("ECHEC : fin de phase VERTE en %0d cycles (attendu entre 1 et %0d)",
                     n, DUREE_VERT);
        end
        if (orange !== 1'b1) begin
            erreurs = erreurs + 1;
            $display("ECHEC : le vert doit etre suivi de l'ORANGE");
        end

        compter_phase(PHASE_ORANGE, n);
        if (n !== DUREE_ORANGE) begin
            erreurs = erreurs + 1;
            $display("ECHEC : phase ORANGE de %0d cycles (attendu %0d)", n, DUREE_ORANGE);
        end
        if (rouge !== 1'b1) begin
            erreurs = erreurs + 1;
            $display("ECHEC : l'orange doit etre suivi du ROUGE");
        end

        compter_phase(PHASE_ROUGE, n);
        if (n !== DUREE_ROUGE) begin
            erreurs = erreurs + 1;
            $display("ECHEC : 2e phase ROUGE de %0d cycles (attendu %0d)", n, DUREE_ROUGE);
        end
        if (vert !== 1'b1) begin
            erreurs = erreurs + 1;
            $display("ECHEC : le rouge doit etre suivi du VERT");
        end

        // --- 5) capteur toujours actif : le vert dure exactement DUREE_VERT
        compter_phase(PHASE_VERT, n);
        if (n !== DUREE_VERT) begin
            erreurs = erreurs + 1;
            $display("ECHEC : phase VERTE de %0d cycles (attendu %0d)", n, DUREE_VERT);
        end
        if (orange !== 1'b1) begin
            erreurs = erreurs + 1;
            $display("ECHEC : le vert doit reboucler sur l'ORANGE");
        end

        if (erreurs == 0)
            $display("PASS tb_fsm_traffic_light (durees 3/2/4, exclusion mutuelle a chaque cycle, attente sur capteur)");
        else
            $display("ECHEC tb_fsm_traffic_light : %0d erreur(s)", erreurs);
        $finish;
    end

endmodule
