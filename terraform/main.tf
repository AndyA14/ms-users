terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
  # No ponemos credenciales aquí, las toma de las variables de entorno de GitHub Actions
}

# 👇 SOLO CAMBIA ESTO EN CADA REPO 👇
locals {
  name  = "ms-users"  # ms-users, ms-auth, etc.
  port  = 8001        # 8001, 8002, etc.
  image = "aceofglass14/ms-users:latest"
}
# 👆 ----------------------------- 👆

# 1. VPC Default (Cada cuenta tiene una propia, así que no hay conflicto)
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# 2. Key Pair (Se crea una nueva en cada cuenta)
resource "tls_private_key" "pk" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "kp" {
  key_name   = "key-${local.name}"
  public_key = tls_private_key.pk.public_key_openssh
}

resource "local_file" "pem" {
  filename        = "${path.module}/${local.name}.pem"
  content         = tls_private_key.pk.private_key_pem
  file_permission = "0400"
}

# 3. Security Group
resource "aws_security_group" "sg" {
  name   = "${local.name}-sg"  # Cambié el nombre para que no empiece con sg-
  vpc_id = data.aws_vpc.default.id

  ingress {
    from_port   = local.port
    to_port     = local.port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress { # SSH
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 4. Instancia EC2 (Microservicio)
resource "aws_instance" "server" {
  ami                    = "ami-0c02fb55956c7d316"  # Amazon Linux 2 (us-east-1)
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.kp.key_name
  vpc_security_group_ids = [aws_security_group.sg.id]

  # User Data para instalar Docker al nacer
  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    amazon-linux-extras install docker -y
    service docker start
    systemctl enable docker
    usermod -a -G docker ec2-user

    # Ejecutar Docker Pull para la imagen del microservicio
    docker pull ${local.image}
  EOF

  tags = {
    Name = "server-${local.name}"
  }
}

# 5. Outputs

# Output de la llave privada
output "key_pair_private_key_file" {
  value = local_file.pem.filename
}

# Output del primer puerto de ingress (puerto especificado en la primera regla)
output "security_group_ingress_port" {
  value = [for ingress in aws_security_group.sg.ingress : ingress.from_port][0]
}

# Output del estado de la instancia
output "instance_state" {
  value = aws_instance.server.instance_state
}
