`timescale 1ns / 1ps
//=============================================================================
// tb_t_flip_flop — banc d'essai de la bascule T.
//
// Trois propriétés :
//
//  1) t = 0 : mémorisation. Même en laissant passer de nombreux fronts, q ne
//     doit pas bouger d'un iota.
//
//  2) t = 1 : BASCULEMENT à chaque front. On le vérifie sur une longue série
//     de fronts consécutifs, ce qui met en évidence la DIVISION DE FRÉQUENCE
//     PAR DEUX : q change une fois tous les deux fronts d'horloge, donc la
//     période de q vaut deux périodes de clk. C'est le principe de l'étage
//     élémentaire d'un compteur binaire asynchrone.
//
//  3) reset synchrone prioritaire sur t.
//
// La référence est un modèle indépendant (`attendu`) qui applique la table de
// transition à la main ; on compte aussi les basculements observés pour
// vérifier la division de fréquence de façon quantitative.
//=============================================================================
module tb_t_flip_flop;

    reg  clk = 1'b0;
    reg  rst, t;
    wire q, q_b;

    integer erreurs      = 0;
    integer cycles       = 0;
    integer basculements = 0;
    integer i;
    reg     attendu;
    reg     q_precedent;

    t_flip_flop dut (.clk(clk), .rst(rst), .t(t), .q(q), .q_b(q_b));

    always #5 clk = ~clk;

    task pas;
        input in_rst, in_t;
        begin
            rst = in_rst;
            t   = in_t;
            q_precedent = q;
            @(posedge clk);
            #1;
            cycles = cycles + 1;

            // Modele de reference : table de transition ecrite a la main.
            if (in_rst)      attendu = 1'b0;
            else if (in_t)   attendu = ~attendu;
            // sinon : attendu inchange (memorisation)

            if (q !== attendu) begin
                erreurs = erreurs + 1;
                $display("ECHEC cycle %0d (t=%0t) : rst=%b t=%b -> q=%b (attendu %b)",
                         cycles, $time, in_rst, in_t, q, attendu);
            end
            if (q_b !== ~q) begin
                erreurs = erreurs + 1;
                $display("ECHEC cycle %0d : q_b=%b n'est pas le complement de q=%b",
                         cycles, q_b, q);
            end
            if (q !== q_precedent)
                basculements = basculements + 1;
        end
    endtask

    initial begin
        rst = 1'b1;
        t   = 1'b0;

        // --- initialisation --------------------------------------------------
        pas(1'b1, 1'b1);        // reset prioritaire sur t
        pas(1'b1, 1'b0);

        // --- t = 0 : memorisation stricte sur 6 fronts -----------------------
        for (i = 0; i < 6; i = i + 1)
            pas(1'b0, 1'b0);
        if (q !== 1'b0) begin
            erreurs = erreurs + 1;
            $display("ECHEC : q a bouge alors que t restait a 0");
        end

        // --- t = 1 : basculement a chaque front (division par 2) -------------
        basculements = 0;
        for (i = 0; i < 20; i = i + 1)
            pas(1'b0, 1'b1);
        if (basculements != 20) begin
            erreurs = erreurs + 1;
            $display("ECHEC : %0d basculements observes sur 20 fronts avec t=1", basculements);
        end

        // --- alternance t = 1 / t = 0 ----------------------------------------
        for (i = 0; i < 12; i = i + 1)
            pas(1'b0, i[0]);

        // --- reset au vol, puis reprise --------------------------------------
        pas(1'b0, 1'b1);
        pas(1'b1, 1'b1);        // reset malgre t = 1
        if (q !== 1'b0) begin
            erreurs = erreurs + 1;
            $display("ECHEC : reset non prioritaire sur t");
        end
        pas(1'b0, 1'b1);        // q = 1
        pas(1'b0, 1'b1);        // q = 0
        pas(1'b0, 1'b0);        // memorisation

        if (erreurs == 0)
            $display("PASS tb_t_flip_flop (%0d cycles : memorisation, basculement, division de frequence par 2, reset)", cycles);
        else
            $display("ECHEC tb_t_flip_flop : %0d erreur(s)", erreurs);
        $finish;
    end

endmodule
