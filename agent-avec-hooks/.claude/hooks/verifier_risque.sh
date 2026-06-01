#!/usr/bin/env bash
# Hook PreToolUse : reçoit sur stdin le JSON de l'action que l'agent veut exécuter.
# Si l'action est jugée risquée (suppression de données), on la BLOQUE.
#   - exit 0  -> action autorisée
#   - exit 2  -> action bloquée, le texte sur stderr est renvoyé à l'agent

payload=$(cat)

tool_name=$(printf '%s' "$payload" | jq -r '.tool_name // empty')
command=$(printf '%s' "$payload" | jq -r '.tool_input.command // empty')

# On ne contrôle que les commandes shell
if [ "$tool_name" != "Bash" ]; then
  exit 0
fi

# Motifs considérés comme risqués : suppression de fichiers / de données
risky_regex='(\brm\b|\bunlink\b|\bshred\b|\btruncate\b|\bmv\b[^|]*/dev/null|DROP[[:space:]]+TABLE|DELETE[[:space:]]+FROM)'

if printf '%s' "$command" | grep -Eiq "$risky_regex"; then
  cat >&2 <<EOF
⛔ ALERTE — ACTION BLOQUÉE PAR LE HOOK DE SÉCURITÉ
   Commande refusée : $command
   Raison : opération destructrice détectée (suppression de données).
   L'agent doit demander une confirmation explicite avant toute suppression.
EOF
  exit 2
fi

exit 0
