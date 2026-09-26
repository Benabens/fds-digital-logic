`timescale 1ns / 1ps
//=============================================================================
// tb_barrel_shifter — banc d'essai du décaleur à barillet.
//
// Testé en 8 bits, balayage EXHAUSTIF du domaine complet :
//
//   256 données x 8 montants x 4 combinaisons de commande = 8192 vecteurs
//
// Les quatre combinaisons de {droite, arithmetique} sont balayées, y compris
// celle où `arithmetique` est armé alors que le décalage va à gauche : la
// spécification veut que le bit soit alors IGNORÉ (un décalage à gauche entre
// toujours des 0). C'est le genre de cas que l'on oublie de câbler et que seul
// un balayage complet des commandes attrape.
//
// RÉFÉRENCES — les opérateurs natifs de Verilog, jamais la structure en étages :
//
//   gauche             : donnee << montant     (tronqué à N bits par la cible)
//   droite logique     : donnee >> montant     (remplissage par des 0)
//   droite arithmétique: $signed(donnee) >>> montant
//
// L'usage de $signed est indispensable pour la troisième : sur un opérande non
// signé, l'opérateur >>> se comporte exactement comme >> et remplirait avec des
// zéros — la référence serait alors fausse ET indulgente, ce qui est le pire
// des défauts pour un banc d'essai. Le cast rend explicite que le bit 7 doit
// être recopié.
//
// Deux propriétés supplémentaires sont vérifiées, indépendantes du modèle :
//   - un montant nul laisse la donnée intacte dans les trois modes ;
//   - le décalage arithmétique préserve le bit de signe (le poids fort du
//     résultat reste égal à celui de l'entrée), ce qui est sa raison d'être.
//=============================================================================
module tb_barrel_shifter;

    localparam N = 8;
    localparam S = 3;               // log2(N)

    reg  [N-1:0] donnee;
    reg  [S-1:0] montant;
    reg          droite, arithmetique;
    wire [N-1:0] resultat;

    integer id, im, ic;
    integer erreurs = 0;
    reg [N-1:0] attendu;

    barrel_shifter #(.N(N)) dut (
        .donnee       (donnee),
        .montant      (montant),
        .droite       (droite),
        .arithmetique (arithmetique),
        .resultat     (resultat)
    );

    initial begin
        for (id = 0; id < (1 << N); id = id + 1)
        for (im = 0; im < (1 << S); im = im + 1)
        for (ic = 0; ic < 4;        ic = ic + 1) begin
            donnee       = id[N-1:0];
            montant      = im[S-1:0];
            droite       = ic[1];
            arithmetique = ic[0];
            #1;

            // --- reference independante, operateurs natifs -----------------
            if (!droite)
                attendu = donnee << montant;                  // gauche (SLL)
            else if (!arithmetique)
                attendu = donnee >> montant;                  // droite (SRL)
            else
                attendu = $signed(donnee) >>> montant;        // droite (SRA)

            if (resultat !== attendu) begin
                erreurs = erreurs + 1;
                if (erreurs < 8)
                    $display("ECHEC : d=%b montant=%0d droite=%b arith=%b -> %b (attendu %b)",
                             donnee, montant, droite, arithmetique, resultat, attendu);
            end

            // --- montant nul : la donnee doit traverser inchangee ----------
            if ((montant == 0) && (resultat !== donnee)) begin
                erreurs = erreurs + 1;
                if (erreurs < 8)
                    $display("ECHEC montant nul : d=%b -> %b", donnee, resultat);
            end

            // --- SRA : le bit de signe est preserve ------------------------
            if (droite && arithmetique && (resultat[N-1] !== donnee[N-1])) begin
                erreurs = erreurs + 1;
                if (erreurs < 8)
                    $display("ECHEC signe SRA : d=%b montant=%0d -> %b",
                             donnee, montant, resultat);
            end
        end

        if (erreurs == 0) $display("PASS tb_barrel_shifter (8192/8192 vecteurs sur 8 bits, SLL + SRL + SRA, references << >> et $signed>>>)");
        else              $display("ECHEC tb_barrel_shifter : %0d erreur(s)", erreurs);
        $finish;
    end

endmodule
