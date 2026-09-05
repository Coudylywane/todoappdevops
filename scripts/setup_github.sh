#!/usr/bin/env bash
# Configure la protection de la branche main + crée le dépôt GitHub.
# Prérequis : gh CLI authentifié (gh auth login)
# Usage : ./scripts/setup_github.sh [nom-du-repo]
set -euo pipefail

REPO_NAME="${1:-todo-devops}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if ! command -v gh >/dev/null 2>&1; then
  echo "[ERREUR] gh CLI non installé. Installez-le : brew install gh && gh auth login"
  exit 1
fi

echo "==> Création du dépôt GitHub '$REPO_NAME'"
gh repo create "$REPO_NAME" --public --source=. --remote=origin --push || true

echo "==> Archivage : blocage du push direct sur main"
gh api "repos/${REPO_NAME}/branches/main/protection" \
  -X PUT \
  -f "required_status_checks[strict]=true" \
  -f "required_status_checks[contexts][]=CI - Build & Test / build (backend)" \
  -f "required_status_checks[contexts][]=CI - Build & Test / build (frontend)" \
  -f "required_status_checks[contexts][]=CI - Build & Test / docker-build" \
  -f "enforce_admins=true" \
  -f "required_pull_request_reviews[required_approving_review_count]=1" \
  -f "required_linear_history=true" \
  -f "allow_force_pushes=false" \
  -f "allow_deletions=false" >/dev/null

echo "==> Protection active sur main :"
echo "    - PR obligatoire avant merge"
echo "    - Checks CI requis (build backend, build frontend, docker-build)"
echo "    - Push direct bloqué (force push interdit)"
echo
echo "==> Ajout des secrets GitHub Actions"
INVENTORY="$ROOT/infra/ansible/inventory.ini"
if [ -f "$INVENTORY" ]; then
  DEV_IP="$(grep "^todo-dev " "$INVENTORY" | awk '{print $2}' | cut -d= -f2)"
  PROD_IP="$(grep "^todo-prod " "$INVENTORY" | awk '{print $2}' | cut -d= -f2)"
  echo "    DEV_HOST  -> $DEV_IP"
  echo "    PROD_HOST -> $PROD_IP"
  echo "$DEV_IP"  | gh secret set DEV_HOST --repo "$REPO_NAME"
  echo "$PROD_IP" | gh secret set PROD_HOST --repo "$REPO_NAME"
else
  echo "    [AVERTISSEMENT] inventory.ini absent, définissez DEV_HOST/PROD_HOST manuellement."
fi

KEY_FILE="$(ls "$ROOT/infra/terraform"/*.pem 2>/dev/null | head -1 || true)"
if [ -n "$KEY_FILE" ]; then
  gh secret set SSH_PRIVATE_KEY --repo "$REPO_NAME" < "$KEY_FILE"
  echo "    SSH_PRIVATE_KEY -> $KEY_FILE"
else
  echo "    [AVERTISSEMENT] clé .pem absente (terraform apply), définissez SSH_PRIVATE_KEY manuellement."
fi
echo "==> Secrets configurés."