terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "tf-state-ms-users-exam-2026"  # Cambia esto por un nombre único
    key            = "terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "tf-locks-ms-users-exam"       # Cambia esto por un nombre único
    encrypt        = true
  }
}

provider "aws" {
  region = "us-east-1"
}

# 👇 CONFIGURA ESTO PARA CADA MICROSERVICIO 👇
locals {
  name = "ms-users"
  port = 8001
}
# 👆 ------------------------------------- 👆

# --- VPC & Subnets ---
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

# --- KEY PAIR ---
resource "tls_private_key" "pk" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "kp" {
  key_name   = "key-${local.name}"
  public_key = tls_private_key.pk.public_key_openssh
}

resource "local_sensitive_file" "pem" {
  filename        = "${path.module}/${local.name}.pem"
  content         = tls_private_key.pk.private_key_pem
  file_permission = "0400"
}

# --- SECURITY GROUP ---
resource "aws_security_group" "sg" {
  name        = "custom-sg-${local.name}"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = local.port
    to_port     = local.port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
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

# --- LAUNCH TEMPLATE ---
resource "aws_launch_template" "lt" {
  name_prefix   = "${local.name}-lt-"
  image_id      = data.aws_ami.amazon_linux_2023.id
  instance_type = "t2.micro"
  key_name      = aws_key_pair.kp.key_name

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.sg.id]
  }

  user_data = base64encode(<<-EOF
    #!/bin/bash
    setenforce 0
    sed -i 's/SELINUX=enforcing/SELINUX=permissive/g' /etc/selinux/config
    echo "Port 443" >> /etc/ssh/sshd_config
    systemctl restart sshd
    
    dnf update -y
    dnf install -y docker
    systemctl enable --now docker
    usermod -aG docker ec2-user
  EOF
  )
}

# --- ALB (Load Balancer) ---
resource "aws_lb" "alb" {
  name               = "${local.name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.sg.id]
  subnets            = data.aws_subnets.default.ids
}

resource "aws_lb_target_group" "tg" {
  name     = "${local.name}-tg"
  port     = local.port
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id
  health_check {
    path    = "/health"
    matcher = "200"
  }
}

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

# --- AUTO SCALING GROUP ---
resource "aws_autoscaling_group" "asg" {
  name                = "${local.name}-asg"
  vpc_zone_identifier = data.aws_subnets.default.ids
  target_group_arns   = [aws_lb_target_group.tg.arn]
  min_size            = 1
  max_size            = 1
  desired_capacity    = 1

  launch_template {
    id      = aws_launch_template.lt.id
    version = "$Latest"
  }

  instance_refresh {
    strategy = "Rolling"
  }
}

############################################
# DATA SOURCE PARA ASG INSTANCES
############################################
data "aws_instances" "asg_instances" {
  filter {
    name   = "tag:aws:autoscaling:groupName"
    values = [aws_autoscaling_group.asg.name]
  }
  
  depends_on = [aws_autoscaling_group.asg]
}