#!/bin/bash
#=============================================================================
# run_all.sh — compile et simule TOUS les bancs d'essai du dépôt.
#
# Chaque banc d'essai tb/tb_<module>.v est compilé avec l'ensemble des sources
# (les modules se référencent entre eux : full_adder utilise half_adder, etc.),
# puis simulé. Un banc est considéré réussi s'il affiche une ligne « PASS ».
#
# Usage :  ./run_all.sh            (tous les bancs)
#          ./run_all.sh half_adder (un seul, par motif)
#
# Code de sortie 0 si tout passe, 1 sinon — utilisable en intégration continue.
#=============================================================================
set -u
cd "$(dirname "$0")" || exit 1

IVERILOG=$(command -v iverilog || echo /opt/homebrew/bin/iverilog)
VVP=$(command -v vvp || echo /opt/homebrew/bin/vvp)

if [ ! -x "$IVERILOG" ]; then
    echo "iverilog introuvable — installer avec : brew install icarus-verilog"
    exit 1
fi

MOTIF="${1:-}"
SOURCES=$(find src -name '*.v' | sort)
mkdir -p build

total=0; reussis=0; echoues=0
echoues_noms=""

for tb in $(find tb -name 'tb_*.v' | sort); do
    nom=$(basename "$tb" .v)
    if [ -n "$MOTIF" ] && [[ "$nom" != *"$MOTIF"* ]]; then
        continue
    fi
    total=$((total + 1))

    if ! "$IVERILOG" -g2012 -Wall -o "build/$nom" $SOURCES "$tb" > "build/$nom.compile.log" 2>&1; then
        echoues=$((echoues + 1)); echoues_noms="$echoues_noms $nom(compilation)"
        echo "  COMPILATION KO : $nom"
        sed 's/^/      /' "build/$nom.compile.log" | head -5
        continue
    fi

    sortie=$("$VVP" "build/$nom" 2>&1)
    if echo "$sortie" | grep -q '^PASS'; then
        reussis=$((reussis + 1))
        echo "  ok  $(echo "$sortie" | grep '^PASS')"
    else
        echoues=$((echoues + 1)); echoues_noms="$echoues_noms $nom"
        echo "  KO  $nom"
        echo "$sortie" | grep -v '\$finish' | sed 's/^/      /' | head -8
    fi
done

echo
echo "-------------------------------------------------------------"
echo "  bancs d'essai : $total   reussis : $reussis   echoues : $echoues"
if [ "$echoues" -ne 0 ]; then
    echo "  en echec :$echoues_noms"
    exit 1
fi
echo "  tout est vert"
exit 0
