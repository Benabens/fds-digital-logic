`timescale 1ns / 1ps
//=============================================================================
// tb_half_adder — banc d'essai exhaustif du demi-additionneur.
//
// Le domaine d'entrée ne compte que 4 combinaisons : on les teste donc TOUTES,
// plutôt que d'échantillonner. Le banc est auto-vérifiant (il compare à la
// table de vérité attendue) et se termine en affichant PASS ou ECHEC, ce qui
// permet au script run_all.sh de conclure sans lecture humaine du chronogramme.
//=============================================================================
module tb_half_adder;

    reg  x, y;
    wire s, c_out;
    integer erreurs = 0;

    half_adder dut (.x(x), .y(y), .s(s), .c_out(c_out));

    // Applique un vecteur, laisse la logique se propager, compare au résultat attendu.
    task verifier (input vx, input vy, input attendu_s, input attendu_c);
        begin
            x = vx; y = vy;
            #1;
            if (s !== attendu_s || c_out !== attendu_c) begin
                erreurs = erreurs + 1;
                $display("ECHEC : x=%b y=%b -> s=%b c_out=%b (attendu s=%b c_out=%b)",
                         x, y, s, c_out, attendu_s, attendu_c);
            end
        end
    endtask

    initial begin
        //        x  y  s  c_out
        verifier(0, 0, 0, 0);
        verifier(0, 1, 1, 0);
        verifier(1, 0, 1, 0);
        verifier(1, 1, 0, 1);   // 1+1 = 10 : somme 0, retenue 1

        if (erreurs == 0) $display("PASS tb_half_adder (4/4 combinaisons)");
        else              $display("ECHEC tb_half_adder : %0d erreur(s)", erreurs);
        $finish;
    end

endmodule
