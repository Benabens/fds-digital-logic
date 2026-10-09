`timescale 1ns / 1ps
//=============================================================================
// tb_register — banc d'essai du registre N bits (N = 8 ici).
//
// Ce qui est vérifié, dans l'ordre des priorités du module :
//   - reset synchrone : q <- 0, même si en = 1 et d != 0 ;
//   - chargement (en = 1) : q <- d, y compris sur des motifs qui exercent
//     TOUS les bits (0x00, 0xFF, 0xAA, 0x55, ...) ;
//   - GEL (en = 0) : c'est le test le plus important, car c'est celui qu'un
//     module buggé rate. On maintient en = 0 pendant plusieurs fronts en
//     faisant varier d à chaque cycle : q ne doit strictement pas bouger ;
//   - stabilité entre deux fronts : d change au milieu du cycle, q est figée.
//
// La référence est un simple registre logiciel `attendu` mis à jour selon la
// table de transition, indépendamment du DUT.
//=============================================================================
module tb_register;

    localparam N = 8;

    reg          clk = 1'b0;
    reg          rst, en;
    reg  [N-1:0] d;
    wire [N-1:0] q;

    integer      erreurs = 0;
    integer      cycles  = 0;
    integer      i;
    reg  [N-1:0] attendu;

    register #(.N(N)) dut (.clk(clk), .rst(rst), .en(en), .d(d), .q(q));

    always #5 clk = ~clk;

    task pas;
        input          in_rst, in_en;
        input [N-1:0]  in_d;
        begin
            rst = in_rst;
            en  = in_en;
            d   = in_d;
            @(posedge clk);
            #1;
            cycles = cycles + 1;

            if (in_rst)     attendu = {N{1'b0}};
            else if (in_en) attendu = in_d;
            // sinon : attendu inchange (gel)

            if (q !== attendu) begin
                erreurs = erreurs + 1;
                $display("ECHEC cycle %0d (t=%0t) : rst=%b en=%b d=%02h -> q=%02h (attendu %02h)",
                         cycles, $time, in_rst, in_en, in_d, q, attendu);
            end
        end
    endtask

    initial begin
        rst = 1'b1;
        en  = 1'b0;
        d   = {N{1'b0}};

        // --- reset prioritaire sur le chargement -----------------------------
        pas(1'b1, 1'b1, 8'hFF);
        pas(1'b1, 1'b0, 8'hAA);

        // --- chargements successifs ------------------------------------------
        pas(1'b0, 1'b1, 8'hFF);     // tous les bits a 1
        pas(1'b0, 1'b1, 8'h00);     // tous les bits a 0
        pas(1'b0, 1'b1, 8'hAA);     // damier
        pas(1'b0, 1'b1, 8'h55);     // damier complementaire
        pas(1'b0, 1'b1, 8'h01);
        pas(1'b0, 1'b1, 8'h80);
        pas(1'b0, 1'b1, 8'h3C);

        // --- GEL : en = 0 pendant 8 fronts, d change a chaque cycle ----------
        pas(1'b0, 1'b1, 8'h5A);     // valeur de reference a conserver
        for (i = 0; i < 8; i = i + 1)
            pas(1'b0, 1'b0, i[N-1:0] ^ 8'hF0);
        if (q !== 8'h5A) begin
            erreurs = erreurs + 1;
            $display("ECHEC : le registre n'a pas gele avec en=0 (q=%02h au lieu de 5a)", q);
        end

        // --- un seul cycle d'ecriture au milieu d'une periode de gel ---------
        pas(1'b0, 1'b1, 8'hC3);
        pas(1'b0, 1'b0, 8'h00);
        pas(1'b0, 1'b0, 8'hFF);
        if (q !== 8'hC3) begin
            erreurs = erreurs + 1;
            $display("ECHEC : ecriture unique non conservee (q=%02h au lieu de c3)", q);
        end

        // --- q figee ENTRE deux fronts ---------------------------------------
        en = 1'b1;
        d  = 8'h00;  #2 if (q !== 8'hC3) begin
            erreurs = erreurs + 1;
            $display("ECHEC : q a change hors front");
        end
        d  = 8'h0F;  #1 if (q !== 8'hC3) begin
            erreurs = erreurs + 1;
            $display("ECHEC : q a change hors front");
        end

        // --- balayage : 16 chargements puis 16 gels alternes -----------------
        for (i = 0; i < 32; i = i + 1)
            pas(1'b0, ((i % 3) != 0), (i * 17) & 8'hFF);

        // --- reset au vol ------------------------------------------------------
        pas(1'b0, 1'b1, 8'hFF);
        pas(1'b1, 1'b1, 8'hFF);
        if (q !== 8'h00) begin
            erreurs = erreurs + 1;
            $display("ECHEC : reset synchrone non prioritaire sur en");
        end
        pas(1'b0, 1'b0, 8'hFF);     // gel apres reset

        if (erreurs == 0)
            $display("PASS tb_register (%0d cycles, N=%0d : reset, chargement, gel, stabilite hors front)", cycles, N);
        else
            $display("ECHEC tb_register : %0d erreur(s)", erreurs);
        $finish;
    end

endmodule
