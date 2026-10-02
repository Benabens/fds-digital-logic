`timescale 1ns / 1ps
//=============================================================================
// tb_seven_segment_decoder — banc d'essai du décodeur 7 segments.
//
// Balayage EXHAUSTIF : les 16 valeurs d'entrée, sans exception. Le domaine
// étant minuscule, il n'y a aucune raison d'en tester moins.
//
// COMMENT FABRIQUER UNE RÉFÉRENCE INDÉPENDANTE POUR UNE TABLE ? Une fonction
// définie par une table n'a pas de formule dont on pourrait dériver un modèle.
// Recopier les constantes du module ne prouverait rien. Le banc reconstruit
// donc chaque motif à partir de la DESCRIPTION PHYSIQUE du glyphe : pour chaque
// caractère, on énumère les segments qui doivent être ALLUMÉS pour le dessiner,
// et on assemble le motif par un OU de masques d'un seul bit.
//
//        4'h2 : segments A, B, G, E, D  ->  SEG_A|SEG_B|SEG_G|SEG_E|SEG_D
//
// C'est bien une dérivation autonome : elle part du dessin de l'afficheur, pas
// du code source du décodeur. Une erreur de recopie dans le module produirait
// un motif différent de la description du glyphe et serait détectée.
//
// Deux propriétés globales sont vérifiées en plus de la table :
//   - AUCUN glyphe n'est éteint (un motif tout à zéro signifierait un caractère
//     invisible sur l'afficheur) ;
//   - les 16 motifs sont DEUX À DEUX DISTINCTS : sans quoi deux valeurs
//     s'afficheraient de la même façon et l'afficheur serait ambigu. C'est
//     précisément pourquoi b et d sont dessinés en minuscule.
//=============================================================================
module tb_seven_segment_decoder;

    // Masques d'un seul segment. Convention du module :
    // segments = { a, b, c, d, e, f, g }, donc segments[6] = a et segments[0] = g.
    localparam [6:0] SEG_A = 7'b1000000;
    localparam [6:0] SEG_B = 7'b0100000;
    localparam [6:0] SEG_C = 7'b0010000;
    localparam [6:0] SEG_D = 7'b0001000;
    localparam [6:0] SEG_E = 7'b0000100;
    localparam [6:0] SEG_F = 7'b0000010;
    localparam [6:0] SEG_G = 7'b0000001;

    reg  [3:0] d;
    wire [6:0] segments;

    integer i, j;
    integer erreurs = 0;
    reg [6:0] attendu;
    reg [6:0] vus [0:15];           // motifs observes, pour le test d'unicite

    seven_segment_decoder dut (
        .d(d), .segments(segments)
    );

    initial begin
        for (i = 0; i < 16; i = i + 1) begin
            d = i[3:0];
            #1;

            // --- reference : quels segments faut-il allumer pour DESSINER
            //     le caractere ? (description physique du glyphe) ----------
            case (d)
                4'h0: attendu = SEG_A | SEG_B | SEG_C | SEG_D | SEG_E | SEG_F;
                4'h1: attendu = SEG_B | SEG_C;
                4'h2: attendu = SEG_A | SEG_B | SEG_G | SEG_E | SEG_D;
                4'h3: attendu = SEG_A | SEG_B | SEG_G | SEG_C | SEG_D;
                4'h4: attendu = SEG_F | SEG_G | SEG_B | SEG_C;
                4'h5: attendu = SEG_A | SEG_F | SEG_G | SEG_C | SEG_D;
                4'h6: attendu = SEG_A | SEG_F | SEG_G | SEG_E | SEG_D | SEG_C;
                4'h7: attendu = SEG_A | SEG_B | SEG_C;
                4'h8: attendu = SEG_A | SEG_B | SEG_C | SEG_D | SEG_E | SEG_F | SEG_G;
                4'h9: attendu = SEG_A | SEG_B | SEG_C | SEG_D | SEG_F | SEG_G;
                4'hA: attendu = SEG_A | SEG_B | SEG_C | SEG_E | SEG_F | SEG_G;
                4'hB: attendu = SEG_C | SEG_D | SEG_E | SEG_F | SEG_G;          // b
                4'hC: attendu = SEG_A | SEG_D | SEG_E | SEG_F;
                4'hD: attendu = SEG_B | SEG_C | SEG_D | SEG_E | SEG_G;          // d
                4'hE: attendu = SEG_A | SEG_D | SEG_E | SEG_F | SEG_G;
                4'hF: attendu = SEG_A | SEG_E | SEG_F | SEG_G;
                default: attendu = 7'b0000000;
            endcase

            if (segments !== attendu) begin
                erreurs = erreurs + 1;
                $display("ECHEC : d=%h -> abcdefg = %b (attendu %b)",
                         d, segments, attendu);
            end

            // Aucun caractere ne doit etre invisible.
            if (segments === 7'b0000000) begin
                erreurs = erreurs + 1;
                $display("ECHEC glyphe eteint : d=%h", d);
            end

            vus[i] = segments;
        end

        // --- unicite des 16 motifs : l'afficheur ne doit pas etre ambigu ---
        for (i = 0; i < 16; i = i + 1)
            for (j = i + 1; j < 16; j = j + 1)
                if (vus[i] === vus[j]) begin
                    erreurs = erreurs + 1;
                    $display("ECHEC ambiguite : %h et %h affichent le meme motif %b",
                             i[3:0], j[3:0], vus[i]);
                end

        if (erreurs == 0) $display("PASS tb_seven_segment_decoder (16/16 valeurs 0-F, motifs reconstruits segment par segment + unicite des glyphes)");
        else              $display("ECHEC tb_seven_segment_decoder : %0d erreur(s)", erreurs);
        $finish;
    end

endmodule
