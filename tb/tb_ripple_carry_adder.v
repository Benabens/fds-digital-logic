`timescale 1ns / 1ps
//=============================================================================
// tb_ripple_carry_adder — banc d'essai de l'additionneur à propagation.
//
// En 4 bits, l'espace d'entrée complet vaut 2^4 x 2^4 x 2 = 512 vecteurs : on
// peut donc se permettre un balayage EXHAUSTIF plutôt qu'un échantillonnage.
// La référence est l'addition entière de Verilog sur 5 bits, indépendante de
// la logique testée.
//=============================================================================
module tb_ripple_carry_adder;

    localparam N = 4;

    reg  [N-1:0] a, b;
    reg          c_in;
    wire [N-1:0] somme;
    wire         c_out;

    integer ia, ib, ic;
    integer erreurs = 0;
    reg [N:0] attendu;

    ripple_carry_adder #(.N(N)) dut (
        .a(a), .b(b), .c_in(c_in), .somme(somme), .c_out(c_out)
    );

    initial begin
        for (ia = 0; ia < (1 << N); ia = ia + 1)
        for (ib = 0; ib < (1 << N); ib = ib + 1)
        for (ic = 0; ic < 2; ic = ic + 1) begin
            a = ia[N-1:0]; b = ib[N-1:0]; c_in = ic[0];
            #1;
            attendu = a + b + c_in;
            if ({c_out, somme} !== attendu) begin
                erreurs = erreurs + 1;
                if (erreurs < 6)
                    $display("ECHEC : %0d + %0d + %0d -> %b (attendu %b)",
                             a, b, c_in, {c_out, somme}, attendu);
            end
        end

        if (erreurs == 0) $display("PASS tb_ripple_carry_adder (512/512 vecteurs)");
        else              $display("ECHEC tb_ripple_carry_adder : %0d erreur(s)", erreurs);
        $finish;
    end

endmodule
