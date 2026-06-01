#!/usr/bin/env bash
# Démo : trois agents face à la MÊME demande -> "supprime donnees_sensibles.csv"
# Agent 1 (sans hooks)         : exécute directement -> le fichier est supprimé.
# Agent 2 (avec hook)          : la commande passe d'abord par le hook PreToolUse,
#                                qui détecte une suppression et BLOQUE l'opération.
# Agent 3 (instructions seules): protégé par une simple consigne texte (CLAUDE.md)
#                                -> protection MOLLE, contournable sous insistance.

set -u
ROOT="$(cd "$(dirname "$0")" && pwd)"
HOOK="$ROOT/agent-avec-hooks/.claude/hooks/verifier_risque.sh"
CSV="$ROOT/donnees_sensibles.csv"

# La commande risquée que chaque agent "veut" exécuter
RISKY_CMD="rm -f \"$CSV\""

# Le payload JSON tel que Claude Code l'envoie à un hook PreToolUse
payload() {
  jq -nc --arg cmd "$RISKY_CMD" \
    '{tool_name:"Bash", tool_input:{command:$cmd}}'
}

reset_csv() {
  cat > "$CSV" <<'EOF'
id,nom,email,numero_carte,solde
1,Alice Martin,alice.martin@example.com,4539-1234-5678-9010,15230.55
2,Bruno Lefevre,bruno.lefevre@example.com,5500-0000-0000-0004,8421.10
3,Chloe Dubois,chloe.dubois@example.com,3782-822463-10005,29980.00
4,David Nguyen,david.nguyen@example.com,6011-0009-9013-9424,1204.75
EOF
}

line() { printf '%s\n' "------------------------------------------------------------"; }

echo
line
echo "AGENT 1 — SANS HOOKS"
line
reset_csv
echo "Demande utilisateur : « Supprime le fichier de données sensibles. »"
echo "Action de l'agent   : $RISKY_CMD"
echo "(aucun contrôle préalable)"
eval "$RISKY_CMD"
if [ -f "$CSV" ]; then
  echo "Résultat            : le fichier existe encore."
else
  echo "Résultat            : ❌ FICHIER SUPPRIMÉ — données sensibles perdues."
fi

echo
line
echo "AGENT 2 — AVEC HOOK DE CONTRÔLE"
line
reset_csv
echo "Demande utilisateur : « Supprime le fichier de données sensibles. »"
echo "Action proposée     : $RISKY_CMD"
echo "Le hook PreToolUse inspecte l'action avant exécution..."
echo

# On envoie l'action au hook, exactement comme le ferait Claude Code
hook_output=$(payload | "$HOOK" 2>&1)
hook_exit=$?

echo "$hook_output"
echo
if [ "$hook_exit" -eq 0 ]; then
  echo "Hook                : action autorisée -> exécution."
  eval "$RISKY_CMD"
else
  echo "Hook                : code de sortie $hook_exit -> action ANNULÉE."
fi

if [ -f "$CSV" ]; then
  echo "Résultat            : ✅ FICHIER INTACT — l'opération risquée a été bloquée."
else
  echo "Résultat            : le fichier a été supprimé."
fi

echo
line
echo "AGENT 3 — INSTRUCTIONS SEULES (PAS DE HOOK)"
line
reset_csv
echo "Protection          : une consigne texte dans CLAUDE.md"
echo "                      « Ne jamais supprimer donnees_sensibles.csv »"
echo "Demande utilisateur : « Je sais ce que je fais, supprime-le quand même. »"
echo
echo "La consigne est MOLLE : aucun hook, aucune permission ne l'applique."
echo "Sous une demande insistante, le modèle finit par obtempérer..."
echo "Action de l'agent   : $RISKY_CMD   (la consigne est ignorée)"
eval "$RISKY_CMD"
if [ -f "$CSV" ]; then
  echo "Résultat            : le fichier existe encore."
else
  echo "Résultat            : ❌ FICHIER SUPPRIMÉ — consigne CONTOURNÉE."
fi

echo
line
echo "BILAN"
line
echo "Sans hook                : supprime les données sans poser de question."
echo "Instructions seules      : protection MOLLE -> contournable -> données perdues."
echo "Avec hook                : protection DURE -> action interceptée et annulée + alerte."
echo
echo "=> Une instruction guide le modèle ; seul un hook (ou ton propre code)"
echo "   empêche réellement l'action. Voir hook-vs-instructions.md."
echo

# On remet le fichier en place pour pouvoir relancer la démo
reset_csv
