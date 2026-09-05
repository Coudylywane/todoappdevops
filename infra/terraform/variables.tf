variable "aws_region" {
  description = "Région AWS"
  type        = string
  default     = "eu-west-3"
}

variable "project_name" {
  description = "Nom du projet (préfixe des ressources)"
  type        = string
  default     = "todo"
}

variable "key_name" {
  description = "Nom de la paire de clés EC2"
  type        = string
  default     = "todo-ec2-key"
}

variable "my_ip" {
  description = "Adresse IP publique autorisée à se connecter en SSH (x.x.x.x/32)"
  type        = string
  default     = "0.0.0.0/0"
}