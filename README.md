# Todo App - Full Stack DevOps

Application todo avec backend Express, frontend React, base de données PostgreSQL, et une infrastructure DevOps complète (Terraform + Ansible + GitHub Actions).

## 🏗️ Architecture

**Séparation des responsabilités :**

- **Ansible = prérequis / infrastructure** : installe Docker et provisionne les services d'infra (Traefik, PostgreSQL, Prometheus, Grafana, node-exporter) une fois pour toutes.
- **GitHub Actions = déploiement de l'application** : à chaque push sur `develop`/`main`, il envoie le code et reconstruit les conteneurs de l'app sur le serveur cible.

```
┌────────────────┐     ┌────────────────┐
│  Serveur DEV   │     │  Serveur PROD  │
│  (EC2 t3.micro)│     │  (EC2 t3.micro)│
│                │     │                │
│  INFRA (Ansible)      │                │
│  Traefik       │     │  Traefik       │
│  PostgreSQL    │     │  PostgreSQL    │
│  Prometheus    │     │  Prometheus    │
│  Grafana       │     │  Grafana       │
│                │     │                │
│  APP (GitHub Actions)│  │                │
│  Todo backend  │     │  Todo backend  │
│  Todo frontend │     │  Todo frontend │
└────────────────┘     └────────────────┘
        ▲                       ▲
        │ push sur develop      │ push sur main
        └────── GitHub Actions ─┘
```

## 📁 Structure

```
├── backend/                    # API Express (port 5000)
├── frontend/                   # Application React + Vite
├── infra/
│   ├── terraform/              # Création des EC2 (dev + prod)
│   │   ├── main.tf             # 2 instances + clé SSH + security group
│   │   ├── variables.tf
│   │   └── terraform.tfvars.example
│   └── ansible/
│       ├── inventory.ini       # Généré automatiquement
│       ├── playbooks/
│       │   ├── install.yml     # Docker + outils de base (prérequis)
│       │   └── deploy.yml      # Infra : Traefik + Prometheus + Grafana
│       └── files/
│           ├── docker-compose.infra.yml.j2  # Services infra (Ansible)
│           ├── docker-compose.app.yml.j2    # App todo (GitHub Actions)
│           ├── traefik/  prometheus/  grafana/
├── .github/workflows/
│   ├── ci.yml                  # Build & vérification sur PRs
│   └── deploy.yml              # deploy: develop→dev, main→prod
├── scripts/
│   ├── update_inventory.sh     # inventory.ini via les sorties Terraform
│   └── show_github_secrets.sh  # Affiche les secrets pour GitHub
├── docker-compose.yml          # PostgreSQL local (dev machine)
└── Makefile                    # Raccourcis de commandes
```

## 🚀 Démarrage pas à pas

### 1. Prérequis

- Terraform ≥ 1.5, Ansible, AWS CLI
- Credentials AWS : `export AWS_ACCESS_KEY_ID=...` / `export AWS_SECRET_ACCESS_KEY=...`
- Vérifiez : `aws sts get-caller-identity`

### 2. Créer les serveurs EC2 (Terraform)

```bash
cd infra/terraform
cp terraform.tfvars.example terraform.tfvars   # ajustez la région si besoin
make init
make plan
make apply
```

> 👉 Le fichier `todo-ec2-key.pem` est généré localement (jamais versionné). 2 instances EC2 Ubuntu 24.04 sont créées (dev + prod) avec Docker préinstallé.

### 3. Mettre à jour l'inventaire Ansible

```bash
make inventory    # Remplace les IP factices par les vraies IP EC2
```

### 4. Installer les outils sur les serveurs (Ansible)

```bash
# Mot de passe Grafana/Postgres : remplir group_vars/vault.yml
mkdir -p infra/ansible/group_vars && cp infra/ansible/group_vars/vault.yml.example infra/ansible/group_vars/vault.yml

make install      # Docker sur les 2 serveurs
make deploy       # Infra : Traefik + Prometheus + Grafana (dev et prod)
```

> L'application est déployée par **GitHub Actions** à chaque push (voir section CI/CD).

### 5. Accéder aux services

| Service      | URL                                  |
|--------------|--------------------------------------|
| App Todo     | `http://<IP_SERVEUR>`                |
| Dashboard Traefik | `http://<IP_SERVEUR>:8080`      |
| API backend  | `http://<IP_SERVEUR>:8081/api/todos` |
| Prometheus   | `http://<IP_SERVEUR>:9090`           |
| Grafana      | `http://<IP_SERVEUR>:3000` (admin/admin) |

## 🔄 CI/CD (GitHub Actions)

### Secrets à configurer dans GitHub

Settings → **Secrets and variables** → **Actions** :

| Secret             | Description                              |
|--------------------|------------------------------------------|
| `SSH_PRIVATE_KEY`  | Contenu de `infra/terraform/todo-ec2-key.pem` |
| `DEV_HOST`         | IP publique du serveur dev               |
| `PROD_HOST`        | IP publique du serveur prod              |

```bash
make secrets   # affiche les valeurs à copier
```

### Déploiement automatique

| Événement                                | Action |
|------------------------------------------|--------|
| PR / push sur `develop`                  | CI (build) + déploiement sur **dev** |
| PR / push sur `main`                     | CI (build) + déploiement sur **prod** |
| Push direct sur `main`                   | 🔒 **Bloqué** (protection de branche) |

### Protection de la branche `main`

Configuration dans GitHub : Settings → Branches → Add rule :

- ✅ Require a pull request before merging
- ✅ Require status checks (CI - Build & Test)
- ✅ Require linear history
- ❌ Lock branch / Allow deletions : non

## 💻 Commandes Make

```bash
make plan            # Plan Terraform
make apply           # Créer les serveurs
make inventory       # MàJ de l'inventaire Ansible
make install         # Docker sur les serveurs
make deploy          # Provisionner l'infra partout
make deploy-dev      # Infra sur dev seulement
make deploy-prod     # Infra sur prod seulement
make secrets         # Secrets pour GitHub Actions
make destroy         # Détruire l'infra (⚠️)
```

## API

| Méthode | Route             | Description                |
|---------|-------------------|----------------------------|
| GET     | /api/todos        | Liste des todos            |
| GET     | /api/todos/:id    | Un todo par id             |
| POST    | /api/todos        | Créer un todo `{title}`    |
| PUT     | /api/todos/:id    | Mettre à jour `{title, completed}` |
| DELETE  | /api/todos/:id    | Supprimer un todo          |

## Développement local

```bash
docker compose up -d          # PostgreSQL
cd backend && npm install && npm run dev
cd frontend && npm install && npm run dev
```