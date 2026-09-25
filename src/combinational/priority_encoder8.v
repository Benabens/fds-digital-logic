`timescale 1ns / 1ps
//=============================================================================
// priority_encoder8 — encodeur prioritaire 8 vers 3, priorité au poids fort
//
// Comme encoder8to3, il rend le numéro d'une ligne active — mais il accepte
// QUE PLUSIEURS lignes soient actives en même temps, et tranche par une règle
// de PRIORITÉ : c'est l'indice le plus ÉLEVÉ qui gagne. Autrement dit, q est la
// position du 1 de poids fort de d, et les entrées d'indice inférieur sont
// ignorées quel que soit leur état.
//
//   d          | q   valide      (« ? » = indifférent)
//   00000000   | 000    0        aucune ligne : q sans signification
//   00000001   | 000    1
//   0000001?   | 001    1
//   000001??   | 010    1
//   00001???   | 011    1
//   0001????   | 100    1
//   001?????   | 101    1
//   01??????   | 110    1
//   1???????   | 111    1
//
// CE QUE LA PRIORITÉ APPORTE. L'encodeur simple n'est correct que si l'entrée
// est réellement one-hot ; sinon il rend le OU des indices, qui ne désigne
// aucune ligne. L'encodeur prioritaire est TOTAL : sa sortie est définie et
// utile pour les 256 combinaisons d'entrée. C'est ce qui en fait le bloc
// employé en pratique.
//
// ÉCRITURE EN casez. Chaque motif se lit « le bit de poids fort à 1 est en
// position k, peu importe ce qu'il y a en dessous ». Le `?` de casez signifie
// « bit indifférent », et l'ordre des branches EST la règle de priorité :
// casez évalue de haut en bas et retient le premier motif qui colle. On place
// donc le poids fort en premier. Ce style traduit littéralement la chaîne de
// priorité que la synthèse produira (une cascade de portes ET/OU).
//
// Le bloc always @(*) est purement combinatoire : toutes les branches affectent
// q, y compris le default, donc aucun verrou (latch) n'est inféré. C'est la
// discipline à respecter systématiquement pour la logique combinatoire décrite
// en always.
//
// À QUOI ÇA SERT. Un contrôleur d'interruptions reçoit plusieurs requêtes
// simultanées et doit servir la plus urgente : l'encodeur prioritaire donne
// directement son numéro. Même rôle dans un arbitre de bus, dans un allocateur
// de ressources, ou dans le calcul du nombre de zéros de tête d'un flottant
// lors de la normalisation.
//=============================================================================
module priority_encoder8 (
    input  wire [7:0] d,        // quelconque : aucune hypothèse de one-hot
    output reg  [2:0] q,        // indice du 1 de poids fort
    output wire       valide    // 0 si d = 0 (q est alors sans signification)
);

    assign valide = |d;

    always @(*) begin
        casez (d)
            8'b1???????: q = 3'd7;
            8'b01??????: q = 3'd6;
            8'b001?????: q = 3'd5;
            8'b0001????: q = 3'd4;
            8'b00001???: q = 3'd3;
            8'b000001??: q = 3'd2;
            8'b0000001?: q = 3'd1;
            8'b00000001: q = 3'd0;
            default:     q = 3'd0;      // d = 0 : valide signale l'absence
        endcase
    end

endmodule
