`timescale 1ns / 1ps
//=============================================================================
// barrel_shifter — décaleur à barillet N bits (N puissance de 2)
//
// Décale une donnée de 0 à N-1 positions EN UN SEUL CYCLE, contrairement au
// registre à décalage séquentiel qui avance d'un rang par coup d'horloge. Trois
// opérations, celles du jeu d'instructions de n'importe quel processeur :
//
//   droite=0                → décalage logique à GAUCHE   (SLL) : entre des 0
//   droite=1, arithmetique=0 → décalage logique à DROITE  (SRL) : entre des 0
//   droite=1, arithmetique=1 → décalage arithmétique DROITE (SRA) : recopie le
//                              bit de signe, ce qui réalise une division
//                              entière par 2^k en complément à 2.
//
// STRUCTURE EN ÉTAGES — le cœur du module. On n'écrit PAS « décale de k » : on
// exploite l'écriture BINAIRE du montant. Décaler de 5 = 101 en binaire, c'est
// décaler de 4 puis de 1. Il suffit donc de log2(N) étages, l'étage k décalant
// de 2^k ou de rien du tout selon la valeur du bit montant[k] :
//
//   donnee ─▶[ étage 0 : 1 ? ]─▶[ étage 1 : 2 ? ]─▶[ étage 2 : 4 ? ]─▶ résultat
//               montant[0]         montant[1]         montant[2]
//
// Chaque étage n'est qu'une rangée de N multiplexeurs 2 vers 1 partageant la
// même commande — aucune logique de décodage, juste du câblage. D'où le coût :
//
//   surface = N.log2(N) multiplexeurs      délai = log2(N) niveaux
//
// à comparer aux N-1 cycles d'un registre à décalage. C'est exactement le
// compromis en arbre de mux_param, appliqué au décalage.
//
// L'ASTUCE DU RETOURNEMENT. Décaler à gauche, c'est décaler à droite dans un
// miroir. Plutôt que de dupliquer les log2(N) étages pour chaque sens, on
// retourne l'ordre des bits en entrée, on décale toujours vers la droite, puis
// on retourne à nouveau en sortie. Deux inversions de câblage (gratuites au
// silicium) remplacent la moitié des multiplexeurs.
//
// LE BIT DE REMPLISSAGE. Les positions libérées reçoivent `remplissage` :
// le bit de signe donnee[N-1] en mode arithmétique droite, 0 sinon. En mode
// gauche il vaut toujours 0, et le retournement le place bien en bas.
//
// Le tableau des étages est APLATI dans un seul vecteur (le mot de l'étage k
// occupe etage[k*N +: N]), même convention que le bus d'entrée de mux_param :
// c'est ce qui permet d'indexer les nœuds avec des expressions de genvar.
//=============================================================================
module barrel_shifter #(
    parameter N = 8                         // largeur, puissance de 2, N >= 2
)(
    input  wire [N-1:0]            donnee,
    input  wire [$clog2(N)-1:0]    montant,        // 0 .. N-1
    input  wire                    droite,         // 0 = gauche, 1 = droite
    input  wire                    arithmetique,   // 1 = recopie du signe (droite)
    output wire [N-1:0]            resultat
);

    localparam S = $clog2(N);               // nombre d'étages = log2(N)

    // Bit injecté dans les positions libérées.
    wire remplissage = droite & arithmetique & donnee[N-1];

    // Entrée normalisée : on décale TOUJOURS vers la droite, quitte à
    // travailler sur l'image miroir de la donnée.
    wire [N-1:0] entree_norm;

    // Étages aplatis : le mot de l'étage k est etage[k*N +: N].
    // L'étage 0 est l'entrée normalisée, l'étage S le résultat normalisé.
    wire [(S+1)*N-1:0] etage;

    genvar k, j;
    generate
        // --- Retournement conditionnel à l'entrée --------------------------
        for (j = 0; j < N; j = j + 1) begin : miroir_entree
            assign entree_norm[j] = droite ? donnee[j] : donnee[N-1-j];
        end

        assign etage[0 +: N] = entree_norm;

        // --- S étages de décalage à droite de 2^k --------------------------
        for (k = 0; k < S; k = k + 1) begin : etage_gen
            for (j = 0; j < N; j = j + 1) begin : mux_gen
                if (j + (1 << k) < N) begin : depuis_donnee
                    // le bit vient de 2^k rangs plus haut
                    assign etage[(k+1)*N + j] = montant[k] ? etage[k*N + j + (1 << k)]
                                                           : etage[k*N + j];
                end else begin : depuis_remplissage
                    // ce rang sort du mot : on injecte le bit de remplissage
                    assign etage[(k+1)*N + j] = montant[k] ? remplissage
                                                           : etage[k*N + j];
                end
            end
        end

        // --- Retournement conditionnel à la sortie -------------------------
        for (j = 0; j < N; j = j + 1) begin : miroir_sortie
            assign resultat[j] = droite ? etage[S*N + j] : etage[S*N + N-1-j];
        end
    endgenerate

endmodule
