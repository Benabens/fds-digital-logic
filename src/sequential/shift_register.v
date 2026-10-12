`timescale 1ns / 1ps
//=============================================================================
// shift_register — registre à décalage N bits universel
//
// Un registre à décalage est une chaîne de N bascules D où la sortie de
// chacune alimente l'entrée de la suivante. À chaque front d'horloge, tout le
// contenu se déplace d'une position ; un nouveau bit entre par une extrémité
// (entrée SÉRIE), le bit de l'autre extrémité sort (sortie SÉRIE).
//
// Ce module est « universel » : il réunit les quatre modes du cours.
//
//   rst load en | dir | comportement
//    1   x    x |  x  | q <- 0                      (reset synchrone)
//    0   1    x |  x  | q <- d                      (chargement PARALLÈLE)
//    0   0    0 |  x  | q inchangé                  (gel)
//    0   0    1 |  1  | q <- {q[N-2:0], s_in}       (décalage à GAUCHE)
//    0   0    1 |  0  | q <- {s_in, q[N-1:1]}       (décalage à DROITE)
//
// Conventions : q[N-1] est le bit de POIDS FORT (MSB), q[0] le poids faible.
//   - décalage à GAUCHE  : les bits montent vers le MSB, s_in entre en q[0],
//     q[N-1] sort. Équivaut à une multiplication par 2 (si s_in = 0).
//   - décalage à DROITE  : les bits descendent vers le LSB, s_in entre en
//     q[N-1], q[0] sort. Équivaut à une division par 2 non signée (si s_in=0)
//     — et à une division signée si l'on réinjecte le bit de signe, ce qui se
//     fait ici en branchant s_in sur q[N-1] (décalage ARITHMÉTIQUE).
//
// Usages typiques : conversion série <-> parallèle (UART, SPI), lignes à
// retard, générateurs pseudo-aléatoires (LFSR), multiplication/division par
// puissances de 2 dans une UAL.
//
// STYLE — les deux mondes coexistent proprement dans ce fichier :
//   - le stockage et le décalage : `always @(posedge clk)` + « <= ». Le NON
//     BLOQUANT est ici INDISPENSABLE : avec « = », q[1] = q[0] puis
//     q[2] = q[1] propagerait la même valeur dans toute la chaîne en un seul
//     front (tout le registre se remplirait d'un coup). Avec « <= », tous les
//     bits lisent les ANCIENNES valeurs, comme le fait le matériel.
//   - la sortie série, simple multiplexeur : `always @*` + « = ».
//=============================================================================
module shift_register #(
    parameter N = 8
)(
    input  wire         clk,
    input  wire         rst,    // reset synchrone
    input  wire         en,     // autorise le décalage
    input  wire         load,   // chargement parallèle (prioritaire sur en)
    input  wire         dir,    // 1 = vers la gauche (MSB), 0 = vers la droite
    input  wire         s_in,   // entrée série
    input  wire [N-1:0] d,      // entrée parallèle
    output reg  [N-1:0] q,      // sortie parallèle
    output reg          s_out   // sortie série : bit qui quitte le registre
);

    // --- partie SÉQUENTIELLE : affectations NON BLOQUANTES ------------------
    always @(posedge clk) begin
        if (rst)
            q <= {N{1'b0}};
        else if (load)
            q <= d;
        else if (en) begin
            if (dir)
                q <= {q[N-2:0], s_in};   // gauche : s_in entre par le LSB
            else
                q <= {s_in, q[N-1:1]};   // droite : s_in entre par le MSB
        end
    end

    // --- partie COMBINATOIRE : simple mux, affectations BLOQUANTES ----------
    // s_out présente le bit qui sortira au prochain décalage, c'est-à-dire
    // l'extrémité vers laquelle on décale. Le chaîner sur le s_in d'un second
    // registre à décalage donne un registre de 2N bits.
    always @* begin
        if (dir)
            s_out = q[N-1];
        else
            s_out = q[0];
    end

endmodule
