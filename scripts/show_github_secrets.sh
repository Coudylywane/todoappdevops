#!/usr/bin/env bash
# Affiche les valeurs à ajouter dans les secrets GitHub Actions.
# Usage : ./scripts/show_github_secrets.sh
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TF_DIR="$ROOT/infra/terraform"

echo "=== Secrets à ajouter dans GitHub (Settings -> Secrets and variables -> Actions) ==="
echo
echo "1) SSH_PRIVATE_KEY (contenu du fichier) :"
KEY_FILE="$(ls "$TF_DIR"/*.pem 2>/dev/null | head -1 || true)"
if [ -n "$KEY_FILE" ]; then
  cat "$KEY_FILE"
else
  echo "Introuvable. Lancez d'abord 'terraform apply'."
fi
echo
echo "2) DEV_HOST   = adresse IP EC2 'dev'"
echo "   PROD_HOST  = adresse IP EC2 'prod'"
echo
echo "Lancez ensuite : ./scripts/update_inventory.sh  pour l'inventaire Ansible."