`timescale 1ns / 1ps
//=============================================================================
// tb_full_adder — banc d'essai exhaustif de l'additionneur complet.
//
// 3 entrées => 8 combinaisons : on les balaie toutes par une boucle, et on
// compare au résultat arithmétique de référence x + y + c_in calculé sur 2
// bits. Cette référence indépendante est plus solide qu'une table écrite à la
// main : elle ne peut pas contenir la même erreur que le module testé.
//=============================================================================
module tb_full_adder;

    reg  x, y, c_in;
    wire s, c_out;
    integer i;
    integer erreurs = 0;
    reg [1:0] attendu;

    full_adder dut (.x(x), .y(y), .c_in(c_in), .s(s), .c_out(c_out));

    initial begin
        for (i = 0; i < 8; i = i + 1) begin
            {x, y, c_in} = i[2:0];
            #1;
            attendu = x + y + c_in;      // référence : somme sur 2 bits
            if ({c_out, s} !== attendu) begin
                erreurs = erreurs + 1;
                $display("ECHEC : x=%b y=%b c_in=%b -> {c_out,s}=%b (attendu %b)",
                         x, y, c_in, {c_out, s}, attendu);
            end
        end

        if (erreurs == 0) $display("PASS tb_full_adder (8/8 combinaisons)");
        else              $display("ECHEC tb_full_adder : %0d erreur(s)", erreurs);
        $finish;
    end

endmodule
