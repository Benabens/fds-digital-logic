`timescale 1ns / 1ps
//=============================================================================
// register_file — banc de registres à 2 ports de lecture et 1 port d'écriture
//
// C'est LE bloc mémoire du processeur, celui du chapitre « Computer
// Architecture » du cours. Sa forme n'est pas arbitraire : elle est dictée par
// le jeu d'instructions RV32I.
//
//   POURQUOI DEUX PORTS DE LECTURE ET UN D'ÉCRITURE ?
//   Une instruction de type R en RISC-V s'écrit  add rd, rs1, rs2  : elle lit
//   DEUX registres source et en écrit UN seul. Le banc doit donc pouvoir servir
//   deux lectures et une écriture par cycle. C'est le cas le plus contraignant
//   du jeu d'instructions, et c'est lui qui fixe le nombre de ports.
//
//   POURQUOI DES LECTURES ASYNCHRONES ?
//   Dans un processeur monocycle, le cycle enchaîne : lecture des registres ->
//   traversée de l'ALU -> écriture du résultat. Si la lecture coûtait un cycle,
//   il faudrait un cycle de plus par instruction. Les lectures sont donc
//   purement combinatoires (des multiplexeurs 32 vers 1 — d'où le lien direct
//   avec mux_param du répertoire combinational/), tandis que l'écriture est
//   synchrone, cadencée par le front d'horloge en fin de cycle.
//
//   POURQUOI LE REGISTRE 0 EST-IL CÂBLÉ À ZÉRO ?
//   RV32I définit x0 comme la constante zéro : lire x0 rend toujours 0, écrire
//   dans x0 est sans effet. Ce n'est pas un gaspillage, c'est une astuce
//   d'encodage : elle permet de synthétiser une foule de pseudo-instructions
//   sans opcode dédié.
//       mv   rd, rs   ->  addi rd, rs, 0
//       li   rd, imm  ->  addi rd, x0, imm
//       nop           ->  addi x0, x0, 0
//       j    label    ->  jal  x0, label   (on jette l'adresse de retour)
//   Ici x0 est neutralisé DEUX FOIS, par prudence : le multiplexeur de lecture
//   force la sortie à 0, et l'écriture dans l'adresse 0 est inhibée.
//
//   LECTURE PENDANT ÉCRITURE (read-during-write).
//   Comme la lecture est combinatoire, elle voit l'ANCIENNE valeur pendant tout
//   le cycle d'écriture ; la nouvelle apparaît immédiatement après le front.
//   C'est précisément ce comportement qui oblige, dans un pipeline, à ajouter
//   soit un « write-first » explicite, soit un chemin de contournement
//   (forwarding) entre l'étage d'écriture et l'étage de décodage.
//
// Les paramètres LARGEUR et PROFONDEUR généralisent le bloc (RV32E n'a que
// 16 registres, un DSP peut en avoir 64).
//=============================================================================
module register_file #(
    parameter LARGEUR     = 32,  // largeur d'un registre en bits
    parameter PROFONDEUR  = 32,  // nombre de registres (puissance de 2)
    // Paramètre DÉRIVÉ : à ne jamais surcharger à l'instanciation. Il est
    // déclaré ici et non en localparam car la liste de ports l'utilise, et
    // Verilog exige qu'un identifiant soit connu avant son emploi.
    parameter LARGEUR_ADR = $clog2(PROFONDEUR)
)(
    input  wire                   clk,
    input  wire                   reset,            // synchrone, actif haut

    // --- port de lecture A (asynchrone) ---
    input  wire [LARGEUR_ADR-1:0] adr_lecture_a,
    output wire [LARGEUR-1:0]     donnee_a,

    // --- port de lecture B (asynchrone) ---
    input  wire [LARGEUR_ADR-1:0] adr_lecture_b,
    output wire [LARGEUR-1:0]     donnee_b,

    // --- port d'écriture (synchrone) ---
    input  wire                   ecriture_en,
    input  wire [LARGEUR_ADR-1:0] adr_ecriture,
    input  wire [LARGEUR-1:0]     donnee_ecriture
);

    reg [LARGEUR-1:0] banc [0:PROFONDEUR-1];
    integer           i;

    // --- écriture : SYNCHRONE, et jamais dans le registre 0 --------------
    always @(posedge clk) begin
        if (reset) begin
            for (i = 0; i < PROFONDEUR; i = i + 1)
                banc[i] <= {LARGEUR{1'b0}};
        end else if (ecriture_en && (adr_ecriture != {LARGEUR_ADR{1'b0}})) begin
            banc[adr_ecriture] <= donnee_ecriture;
        end
    end

    // --- lectures : ASYNCHRONES, avec forçage à zéro du registre 0 -------
    assign donnee_a = (adr_lecture_a == {LARGEUR_ADR{1'b0}}) ? {LARGEUR{1'b0}}
                                                             : banc[adr_lecture_a];
    assign donnee_b = (adr_lecture_b == {LARGEUR_ADR{1'b0}}) ? {LARGEUR{1'b0}}
                                                             : banc[adr_lecture_b];

endmodule
