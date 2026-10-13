`timescale 1ns / 1ps
//=============================================================================
// tb_counter_up_down — banc d'essai du compteur haut/bas (N = 4).
//
// N = 4 est choisi pour que le REBOUCLAGE soit atteint rapidement : il ne
// faut que 16 fronts pour parcourir tout le cycle et observer 1111 -> 0000.
//
// Sont vérifiés :
//   - reset synchrone prioritaire sur tout ;
//   - chargement parallèle, prioritaire sur le comptage ;
//   - gel (en = 0) : l'horloge bat, le compteur ne bouge pas ;
//   - comptage AVANT sur un cycle complet, y compris le rebouclage
//     1111 -> 0000 ;
//   - comptage ARRIÈRE sur un cycle complet, y compris 0000 -> 1111 ;
//   - la sortie `boucle`, qui doit valoir 1 exactement sur le cycle qui
//     PRÉCÈDE le rebouclage, et 0 partout ailleurs (y compris quand en = 0).
//
// La référence est un compteur logiciel en entier, ramené modulo 16 par un
// « % 16 » explicite — donc calculé autrement que par la troncature de bits
// du matériel.
//=============================================================================
module tb_counter_up_down;

    localparam N = 4;
    localparam MODULO = 16;         // 2^N

    reg          clk = 1'b0;
    reg          rst, en, load, up;
    reg  [N-1:0] d;
    wire [N-1:0] q;
    wire         boucle;

    integer      erreurs = 0;
    integer      cycles  = 0;
    integer      i;
    integer      attendu;           // reference en ARITHMETIQUE ENTIERE

    counter_up_down #(.N(N)) dut (
        .clk(clk), .rst(rst), .en(en), .load(load), .up(up),
        .d(d), .q(q), .boucle(boucle)
    );

    always #5 clk = ~clk;

    task pas;
        input         in_rst, in_en, in_load, in_up;
        input [N-1:0] in_d;
        reg           boucle_attendue;
        begin
            rst = in_rst; en = in_en; load = in_load; up = in_up; d = in_d;
            #1;                     // laisse la logique combinatoire se stabiliser

            // `boucle` est combinatoire : on la controle AVANT le front.
            if (in_rst || in_load || !in_en)
                boucle_attendue = 1'b0;
            else if (in_up)
                boucle_attendue = (attendu == MODULO - 1);
            else
                boucle_attendue = (attendu == 0);

            if (boucle !== boucle_attendue) begin
                erreurs = erreurs + 1;
                $display("ECHEC boucle (t=%0t) : q=%0d rst=%b en=%b load=%b up=%b -> boucle=%b (attendu %b)",
                         $time, q, in_rst, in_en, in_load, in_up, boucle, boucle_attendue);
            end

            @(posedge clk);
            #1;
            cycles = cycles + 1;

            // --- reference : arithmetique entiere, modulo explicite ----------
            if (in_rst)        attendu = 0;
            else if (in_load)  attendu = in_d;
            else if (in_en)    attendu = in_up ? ((attendu + 1) % MODULO)
                                              : ((attendu + MODULO - 1) % MODULO);

            if (q !== attendu[N-1:0]) begin
                erreurs = erreurs + 1;
                $display("ECHEC cycle %0d (t=%0t) : rst=%b en=%b load=%b up=%b d=%0d -> q=%0d (attendu %0d)",
                         cycles, $time, in_rst, in_en, in_load, in_up, in_d, q, attendu);
            end
        end
    endtask

    initial begin
        rst = 1'b1; en = 1'b0; load = 1'b0; up = 1'b1; d = {N{1'b0}};
        attendu = 0;

        // --- reset prioritaire -------------------------------------------------
        pas(1'b1, 1'b1, 1'b1, 1'b1, 4'hF);
        pas(1'b1, 1'b0, 1'b0, 1'b1, 4'h0);

        // --- GEL : 4 fronts sans bouger ---------------------------------------
        for (i = 0; i < 4; i = i + 1)
            pas(1'b0, 1'b0, 1'b0, 1'b1, 4'h0);
        if (q !== 4'h0) begin
            erreurs = erreurs + 1;
            $display("ECHEC : le compteur a bouge avec en=0");
        end

        // --- COMPTAGE AVANT : un cycle complet + rebouclage --------------------
        // 17 fronts depuis 0 : on passe par 15 puis on reboucle a 0, puis 1.
        for (i = 0; i < 17; i = i + 1)
            pas(1'b0, 1'b1, 1'b0, 1'b1, 4'h0);
        if (q !== 4'h1) begin
            erreurs = erreurs + 1;
            $display("ECHEC : apres 17 incrementations depuis 0, q=%0d (attendu 1)", q);
        end

        // --- CHARGEMENT PARALLELE, prioritaire sur le comptage -----------------
        pas(1'b0, 1'b1, 1'b1, 1'b1, 4'hA);      // load l'emporte sur en
        if (q !== 4'hA) begin
            erreurs = erreurs + 1;
            $display("ECHEC : chargement parallele non prioritaire (q=%0d)", q);
        end
        pas(1'b0, 1'b1, 1'b0, 1'b1, 4'h0);      // 11
        pas(1'b0, 1'b1, 1'b0, 1'b1, 4'h0);      // 12

        // --- COMPTAGE ARRIERE : depuis 3, on passe par 0 puis on reboucle ------
        pas(1'b0, 1'b0, 1'b1, 1'b0, 4'h3);      // chargement de 3
        for (i = 0; i < 6; i = i + 1)
            pas(1'b0, 1'b1, 1'b0, 1'b0, 4'h0);  // 2,1,0,15,14,13
        if (q !== 4'hD) begin
            erreurs = erreurs + 1;
            $display("ECHEC : rebouclage arriere, q=%0d (attendu 13)", q);
        end

        // --- cycle complet en arriere ------------------------------------------
        for (i = 0; i < MODULO; i = i + 1)
            pas(1'b0, 1'b1, 1'b0, 1'b0, 4'h0);
        if (q !== 4'hD) begin
            erreurs = erreurs + 1;
            $display("ECHEC : 16 decrementations ne ramenent pas au point de depart (q=%0d)", q);
        end

        // --- alternance avant / arriere / gel -----------------------------------
        for (i = 0; i < 40; i = i + 1)
            pas(1'b0, ((i % 4) != 3), 1'b0, ((i % 3) != 0), 4'h0);

        // --- reset au vol --------------------------------------------------------
        pas(1'b1, 1'b1, 1'b0, 1'b1, 4'h0);
        pas(1'b0, 1'b1, 1'b0, 1'b1, 4'h0);

        if (erreurs == 0)
            $display("PASS tb_counter_up_down (%0d cycles, N=%0d : avant, arriere, rebouclage, chargement, gel, drapeau boucle)", cycles, N);
        else
            $display("ECHEC tb_counter_up_down : %0d erreur(s)", erreurs);
        $finish;
    end

endmodule
