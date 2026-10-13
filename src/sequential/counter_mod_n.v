`timescale 1ns / 1ps
//=============================================================================
// counter_mod_n — compteur modulo N paramétré (N quelconque)
//
// Le compteur binaire de counter_up_down.v reboucle « gratuitement » modulo
// 2^N : la troncature à N bits fait le travail toute seule. Mais on a très
// souvent besoin d'un modulo qui N'EST PAS une puissance de deux : diviser
// une horloge de 50 MHz par 1000, compter 60 secondes, cadencer 12 étapes
// d'une machine d'état...
//
// Il faut alors DÉTECTER explicitement la valeur terminale et forcer le
// retour à zéro — c'est tout l'objet de ce module :
//
//        q' = (q == N-1) ? 0 : q + 1
//
// Le compteur parcourt donc les états 0, 1, ..., N-1, puis revient à 0 : N
// états distincts, quelle que soit la valeur de N.
//
// LARGEUR DU REGISTRE : il faut assez de bits pour représenter N-1, soit
// ceil(log2(N)) bits, ce que la fonction système $clog2 calcule pour nous.
// Exemples : N = 10 -> 4 bits (0..9, les états 10..15 sont inutilisés) ;
// N = 16 -> 4 bits (aucun état perdu, on retrouve le compteur binaire).
//
// ÉTATS INUTILISÉS — remarque importante de robustesse : lorsque N n'est pas
// une puissance de deux, il existe des états codés mais illégaux (10 à 15
// dans l'exemple). Un parasite pourrait y faire tomber le compteur. Le test
// `>= N-1` plutôt que `== N-1` garantit que le compteur en SORT au front
// suivant au lieu d'y tourner en rond : le circuit est dit AUTO-CORRECTEUR.
//
// SORTIE FIN DE CYCLE (`fin_cycle`, en anglais « terminal count ») : vaut 1
// pendant TOUT l'état N-1, c'est-à-dire pendant le cycle qui PRÉCÈDE le
// rebouclage. Elle sert à cascader les compteurs : `fin_cycle & en` branché
// sur le `en` d'un second étage donne un compteur modulo N*M. Attention à ne
// pas la confondre avec « q == 0 », qui arrive un cycle plus tard.
//
// STYLE : compteur = `always @(posedge clk)` + « <= » ; `fin_cycle` est un
// simple décodage combinatoire de l'état courant, donc `always @*` + « = ».
//=============================================================================
module counter_mod_n #(
    parameter N     = 10,                       // modulo, N >= 2
    // Paramètre DÉRIVÉ — à ne jamais surcharger à l'instanciation. Il est
    // déclaré ici, et non en localparam, parce qu'il sert dans la liste de
    // ports : un localparam du corps du module serait déclaré trop tard.
    parameter WIDTH = (N < 2) ? 1 : $clog2(N)
)(
    input  wire             clk,
    input  wire             rst,                // reset synchrone
    input  wire             en,                 // autorise le comptage
    output reg  [WIDTH-1:0] q,
    output reg              fin_cycle           // 1 pendant l'état N-1
);

    // --- partie SÉQUENTIELLE ------------------------------------------------
    always @(posedge clk) begin
        if (rst)
            q <= {WIDTH{1'b0}};
        else if (en) begin
            if (q >= (N - 1))
                q <= {WIDTH{1'b0}};         // rebouclage explicite
            else
                q <= q + 1'b1;
        end
    end

    // --- partie COMBINATOIRE ------------------------------------------------
    always @* begin
        fin_cycle = (q == (N - 1));
    end

endmodule
