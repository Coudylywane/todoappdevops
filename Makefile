# Makefile du projet Todo - DevOps
# Commandes principales :
#   make init         : initialise Terraform
#   make plan         : planifie l'infrastructure AWS
#   make apply        : crée les serveurs EC2 (dev + prod)
#   make inventory    : met à jour l'inventaire Ansible depuis Terraform
#   make install      : installe Docker/Traefik/Prometheus/Grafana via Ansible
#   make deploy       : provisionne l'infra (Traefik+Prom+Grafana) via Ansible
#   make deploy-dev   : provisionne l'infra uniquement sur dev
#   make deploy-prod  : provisionne l'infra uniquement sur prod
#   make secrets      : affiche les secrets à mettre dans GitHub Actions
#   make destroy      : détruit l'infrastructure (ATTENTION)

TERRAFORM_DIR = infra/terraform
ANSIBLE_DIR   = infra/ansible
ANSIBLE       = "$(CURDIR)/.venv/bin/ansible-playbook"

.PHONY: init plan apply inventory install deploy deploy-dev deploy-prod secrets destroy setup

setup:
	python3 -m venv .venv
	./.venv/bin/pip install -q ansible
	./.venv/bin/ansible-galaxy collection install ansible.posix || true

init:
	cd $(TERRAFORM_DIR) && terraform init

plan:
	cd $(TERRAFORM_DIR) && terraform plan

apply:
	cd $(TERRAFORM_DIR) && terraform apply -auto-approve

inventory:
	./scripts/update_inventory.sh

install:
	cd $(ANSIBLE_DIR) && $(ANSIBLE) playbooks/install.yml

deploy:
	cd $(ANSIBLE_DIR) && $(ANSIBLE) playbooks/deploy.yml

deploy-dev:
	cd $(ANSIBLE_DIR) && $(ANSIBLE) playbooks/deploy.yml -l dev

deploy-prod:
	cd $(ANSIBLE_DIR) && $(ANSIBLE) playbooks/deploy.yml -l prod

secrets:
	./scripts/show_github_secrets.sh

destroy:
	cd $(TERRAFORM_DIR) && terraform destroy -auto-approve