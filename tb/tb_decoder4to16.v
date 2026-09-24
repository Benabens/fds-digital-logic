`timescale 1ns / 1ps
//=============================================================================
// tb_decoder4to16 — banc d'essai exhaustif du décodeur 4 vers 16 hiérarchique.
//
// 5 entrées (a[3:0] et en) => 2^5 = 32 combinaisons, TOUTES balayées.
//
// RÉFÉRENCE INDÉPENDANTE. Le module ne contient aucune porte : il câble deux
// decoder3to8 et joue sur leurs validations. Le banc ignore complètement cette
// construction et se contente de la spécification EXTERNE du composant, écrite
// par décalage :
//
//        attendu = en ? (16'h0001 << a) : 16'h0000
//
// C'est ici que la référence indépendante prend tout son sens : si l'assemblage
// avait interverti les deux moitiés, ou oublié un `~` sur a[3], le décalage le
// verrait immédiatement — alors qu'une référence recopiée de l'assemblage
// contiendrait la même inversion et ne verrait rien.
//
// PROPRIÉTÉS SUPPLÉMENTAIRES, choisies pour cibler les fautes propres à un
// montage hiérarchique :
//   - one-hot GLOBAL sur les 16 lignes : c'est le point où les deux moitiés
//     pourraient se marcher dessus (si les deux enable étaient actifs à la
//     fois, on compterait 2 lignes) ;
//   - découpage en moitiés : a[3] = 0 doit laisser la moitié haute totalement
//     éteinte, et réciproquement — l'exclusivité mutuelle des validations ;
//   - inhibition globale : en = 0 éteint les 16 lignes.
//=============================================================================
module tb_decoder4to16;

    reg  [3:0]  a;
    reg         en;
    wire [15:0] y;

    integer i, b;
    integer erreurs  = 0;
    integer vecteurs = 0;
    integer actives;

    reg [15:0] attendu;

    decoder4to16 dut (.a(a), .en(en), .y(y));

    initial begin
        for (i = 0; i < 32; i = i + 1) begin
            {en, a} = i[4:0];
            #1;

            attendu  = en ? (16'h0001 << a) : 16'h0000;
            vecteurs = vecteurs + 1;

            if (y !== attendu) begin
                erreurs = erreurs + 1;
                $display("ECHEC : en=%b a=%b -> y=%b (attendu %b)", en, a, y, attendu);
            end

            // one-hot global : les deux moities ne doivent jamais repondre ensemble
            actives = 0;
            for (b = 0; b < 16; b = b + 1)
                if (y[b] === 1'b1) actives = actives + 1;
            if (actives !== (en ? 1 : 0)) begin
                erreurs = erreurs + 1;
                $display("ECHEC one-hot : en=%b a=%b -> %0d ligne(s) active(s)",
                         en, a, actives);
            end

            // decoupage en moities pilote par le bit de poids fort
            if (en === 1'b1 && a[3] === 1'b0 && y[15:8] !== 8'b0000_0000) begin
                erreurs = erreurs + 1;
                $display("ECHEC moitie : a=%b (haut interdit) mais y[15:8]=%b", a, y[15:8]);
            end
            if (en === 1'b1 && a[3] === 1'b1 && y[7:0] !== 8'b0000_0000) begin
                erreurs = erreurs + 1;
                $display("ECHEC moitie : a=%b (bas interdit) mais y[7:0]=%b", a, y[7:0]);
            end

            // inhibition complete par l'enable
            if (en === 1'b0 && y !== 16'h0000) begin
                erreurs = erreurs + 1;
                $display("ECHEC inhibition : en=0 a=%b mais y=%b", a, y);
            end
        end

        if (erreurs == 0) $display("PASS tb_decoder4to16 (%0d/32 combinaisons + one-hot global, moities, inhibition)", vecteurs);
        else              $display("ECHEC tb_decoder4to16 : %0d erreur(s)", erreurs);
        $finish;
    end

endmodule
