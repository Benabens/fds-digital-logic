# fds-digital-logic

**Bibliothèque de logique numérique en Verilog** — 42 modules synthétisables, chacun accompagné d'un banc d'essai auto-vérifiant, couvrant la chaîne complète qui va de la porte logique au banc de registres d'un processeur.

Projet personnel construit autour du cours **CS-173 — Fundamentals of Digital Systems** (EPFL, BA2). Ce n'est pas un projet noté : c'est une reprise des notions du cours, consolidée et poussée bien au-delà des exercices, avec une vérification systématique par simulation.

> `Verilog-2005` · 42 modules · 42 bancs d'essai · **42/42 verts** · zéro avertissement `iverilog -Wall`

---

## Vérifier soi-même

```bash
brew install icarus-verilog     # macOS ; sinon : apt install iverilog
./run_all.sh                    # compile et simule les 42 bancs
./run_all.sh counter            # ou un sous-ensemble, par motif
```

Le script rend un code de sortie non nul si un seul banc échoue — il est utilisable tel quel en intégration continue.

## Ce que couvre la bibliothèque

### Combinatoire — `src/combinational/` (24 modules)

**Addition et soustraction.** `half_adder` et `full_adder` (décrits en structurel, par instanciation de portes) servent de briques au `ripple_carry_adder` paramétré. Le `carry_lookahead_adder4` reprend le même calcul avec les signaux de génération `g = a·b` et de propagation `p = a⊕b`, faisant tomber le délai de O(N) à O(log N) — son banc d'essai le fait tourner **en parallèle** d'un `ripple_carry_adder` pour prouver l'équivalence fonctionnelle sur les 512 vecteurs. L'`adder_subtractor` exploite l'identité `a − b = a + ¬b + 1` du complément à 2 et expose les quatre drapeaux ; son débordement **signé** est vérifié non pas par la formule `carry[N] ⊕ carry[N−1]` mais par sa définition (« le résultat exact sort-il de l'intervalle représentable ? »), pour éviter de tester une formule contre elle-même.

**Sélection et décodage.** Multiplexeurs 2, 4, 8 vers 1 et un `mux_param` générique en 2^SEL vers 1 ; démultiplexeur ; décodeurs 2→4, 3→8, et un 4→16 construit hiérarchiquement à partir de deux 3→8 ; encodeur simple et encodeur **prioritaire**.

**Codes et manipulation de bits.** `barrel_shifter` en log2(N) étages de multiplexeurs (décalages logiques et arithmétique, avec l'astuce du miroir pour le sens gauche), conversions `binary_to_gray` / `gray_to_binary`, `parity_checker`, `bcd_adder` avec sa correction +6, `seven_segment_decoder`, comparateurs et `absolute_difference`.

### Séquentiel — `src/sequential/` (15 modules)

La progression du cours : verrous (`sr_latch` sur portes NOR croisées, `d_latch` transparent sur niveau), puis bascules sur front (`d_flip_flop` en reset synchrone **et** asynchrone, `t_flip_flop` et `jk_flip_flop` bâties par instanciation d'une bascule D), puis les circuits qui en découlent — registre, registre à décalage, compteurs haut/bas et modulo N, compteur en anneau et sa variante Johnson.

Enfin les **machines à états** : le même détecteur de séquence `1011` implémenté en **Moore** (5 états) et en **Mealy** (4 états), pour rendre la différence tangible — Mealy réagit un cycle plus tôt avec moins d'états. Plus un contrôleur de feux de circulation à durées paramétrables et un anti-rebond de bouton mécanique.

### Mémoire — `src/memory/` (3 modules)

`register_file` reproduit le banc de registres d'un **RV32I** : 32 × 32 bits, deux ports de lecture asynchrones, un port d'écriture synchrone, et le registre `x0` câblé à zéro y compris en écriture. Complété par une RAM synchrone et une ROM combinatoire, toutes deux paramétrées.

## Sur la qualité des bancs d'essai

Un test qui passe ne prouve rien s'il ne peut pas échouer. Trois principes ont été appliqués :

1. **Balayage exhaustif** partout où le domaine le permet — les 512 vecteurs du plein additionneur 4 bits, les 4096 du comparateur 6 bits, les 19968 du multiplexeur générique, les 16 valeurs du décodeur 7 segments.
2. **Références indépendantes** : le résultat attendu est recalculé par un chemin différent de celui testé (arithmétique entière de Verilog, opérateurs `<<` `>>` `>>>`, reconstruction des glyphes segment par segment, aller-retour Gray↔binaire), jamais recopié depuis la logique du module.
3. **Test de mutation** : chaque module a été délibérément cassé dans une copie jetable pour vérifier que son banc le détecte — un banc qui reste vert sur du code fauté ne teste rien.

## Organisation

```
src/combinational/   24 modules
src/sequential/      15 modules
src/memory/           3 modules
tb/                  42 bancs d'essai (un par module)
run_all.sh           compilation + simulation de l'ensemble
```

Chaque fichier porte un en-tête expliquant le rôle du module, son équation ou sa table de transition, et la raison d'être du circuit — l'intention est que le dépôt se lise comme un support de révision, pas seulement comme du code.

## Contexte

Cours CS-173 donné par la Prof. Mirjana Stojilović à l'EPFL. Le programme couvre les systèmes de nombres (complément à 2, codes de Gray et BCD, virgule fixe et flottante), les circuits logiques (algèbre de Boole, additionneurs rapides, bascules, machines à états, mémoire) et une introduction à l'architecture des ordinateurs (jeu d'instructions RV32I). Ce dépôt matérialise le deuxième bloc et amorce le troisième.
