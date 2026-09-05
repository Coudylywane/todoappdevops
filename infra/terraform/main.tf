terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

resource "tls_private_key" "todo_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "todo_key" {
  key_name   = var.key_name
  public_key = tls_private_key.todo_key.public_key_openssh
}

resource "local_file" "todo_private_key" {
  filename        = "${path.module}/${var.key_name}.pem"
  content         = tls_private_key.todo_key.private_key_pem
  file_permission = "0600"
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_security_group" "todo_sg" {
  name        = "${var.project_name}-sg"
  description = "Security group for todo servers (dev/prod)"

  ingress {
    # Ouvre le SSH au monde : nécessaire pour que GitHub Actions puisse
    # déployer (IP des runners variables). Sécurisé par clé privée.
    # Pour restreindre à votre IP seule (perd l'accès CI/CD) :
    #   cidr_blocks = [var.my_ip]
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP (frontend via Traefik)"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Traefik dashboard"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "API backend via Traefik"
    from_port   = 8081
    to_port     = 8081
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Prometheus"
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Grafana"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-sg"
  }
}

resource "aws_instance" "todo" {
  for_each = {
    dev  = "t3.micro"
    prod = "t3.micro"
  }

  ami                    = data.aws_ami.ubuntu.id
  instance_type          = each.value
  key_name               = aws_key_pair.todo_key.key_name
  vpc_security_group_ids = [aws_security_group.todo_sg.id]

  associate_public_ip_address = true

  user_data = <<-EOF
    #!/bin/bash
    set -e
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -y && apt-get upgrade -y
    apt-get install -y ca-certificates curl
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    chmod a+r /etc/apt/keyrings/docker.asc
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$${UBUNTU_CODENAME:-$${VERSION_CODENAME}}") stable" > /etc/apt/sources.list.d/docker.list
    apt-get update -y
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    usermod -aG docker ubuntu
    systemctl enable --now docker
  EOF

  tags = {
    Name        = "todo-${each.key}"
    Environment = each.key
    Project     = var.project_name
  }

  depends_on = [local_file.todo_private_key]
}

output "instance_ips" {
  description = "Adresses IP publiques des serveurs dev et prod"
  value = {
    dev  = aws_instance.todo["dev"].public_ip
    prod = aws_instance.todo["prod"].public_ip
  }
}

output "ssh_commands" {
  description = "Commandes SSH pour chaque serveur"
  value = {
    dev  = "ssh -i ${var.key_name}.pem ubuntu@${aws_instance.todo["dev"].public_ip}"
    prod = "ssh -i ${var.key_name}.pem ubuntu@${aws_instance.todo["prod"].public_ip}"
  }
}

output "private_key_file" {
  description = "Chemin vers la clé privée SSH générée"
  value       = "${path.module}/${var.key_name}.pem"
}