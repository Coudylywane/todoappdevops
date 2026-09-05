#!/usr/bin/env bash
# Génère infra/ansible/inventory.ini à partir des sorties Terraform.
# Usage : ./scripts/update_inventory.sh
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TF_DIR="$ROOT/infra/terraform"
OUT_FILE="$ROOT/infra/ansible/inventory.ini"
ANSIBLE_CFG="$ROOT/infra/ansible/ansible.cfg"

cd "$TF_DIR"

OUTPUT_JSON="$(terraform output -json instance_ips 2>/dev/null || true)"

if [ -z "$OUTPUT_JSON" ]; then
  echo "[ERREUR] Sortie Terraform introuvable. Avez-vous lancé \"terraform apply\" ?"
  exit 1
fi

get_ip() {
  python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('$1',''))" <<< "$OUTPUT_JSON"
}

DEVIP="$(get_ip dev)"
PRODIP="$(get_ip prod)"

if [ -z "$DEVIP" ] || [ -z "$PRODIP" ]; then
  echo "[ERREUR] Impossible de lire les IP dev/prod dans la sortie Terraform."
  exit 1
fi

KEY_FILE="$(ls "$TF_DIR"/*.pem 2>/dev/null | head -1 || true)"
PRIVATE_KEY="$(basename "${KEY_FILE}" 2>/dev/null || true)"

cat > "$OUT_FILE" <<EOF
# Généré automatiquement par scripts/update_inventory.sh
# Ne pas éditer manuellement.

[dev]
todo-dev ansible_host=$DEVIP

[prod]
todo-prod ansible_host=$PRODIP

[dev:vars]
app_env=dev
site_display_name=Dev

[prod:vars]
app_env=prod
site_display_name=Prod

# Généré le $(date "+%Y-%m-%d %H:%M")
EOF

if [ -n "$PRIVATE_KEY" ]; then
  sed -i.bak "s|^private_key_file = .*|private_key_file = ../terraform/$PRIVATE_KEY|" "$ANSIBLE_CFG"
  rm -f "$ANSIBLE_CFG.bak"
fi

echo "Inventaire Ansible mis à jour :"
echo "  dev  -> $DEVIP"
echo "  prod -> $PRODIP"