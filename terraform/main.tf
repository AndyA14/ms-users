provider "aws" {
  region = var.region
}

# ── VPC y Subnets ─────────────────────────────────────────────────────────────
data "aws_vpc" "default" { default = true }

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# ── Security Group ─────────────────────────────────────────────────────────────
resource "aws_security_group" "sg" {
  name        = "${var.service_name}-sg"
  description = "SG for ${var.service_name}"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = var.port
    to_port     = var.port
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

# ── Launch Template ────────────────────────────────────────────────────────────
resource "aws_launch_template" "lt" {
  name_prefix   = "${var.service_name}-lt"
  image_id      = "ami-0c02fb55956c7d316"
  instance_type = var.instance_type
  key_name      = var.key_name

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.sg.id]
  }

  user_data = base64encode(<<-EOF
    #!/bin/bash
    exec > >(tee /var/log/user-data.log | logger -t user-data -s 2>/dev/console) 2>&1

    echo "--- INICIANDO DESPLIEGUE: ${var.service_name} ---"

    # 1. SWAP para t2.micro
    dd if=/dev/zero of=/swapfile bs=128M count=16
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    echo "/swapfile swap swap defaults 0 0" >> /etc/fstab

    # 2. Instalar Docker
    yum update -y
    amazon-linux-extras install docker -y
    service docker start
    usermod -a -G docker ec2-user
    systemctl enable docker

    # 3. Variables pasadas directo desde Terraform
    DOCKER_PASS="${var.docker_password}"
    POSTGRES_URL="${var.postgres_url}"
    MONGO_URL="${var.mongo_url}"

    # 4. Docker Login
    echo "$DOCKER_PASS" | docker login -u "${var.docker_username}" --password-stdin

    # 5. Pull y Run
    docker pull ${var.image_name}
    docker run -d \
      --name ${var.service_name} \
      --restart always \
      -p ${var.port}:${var.port} \
      -e PORT="${var.port}" \
      -e RABBITMQ_HOST="${var.rabbitmq_host}" \
      -e RABBITMQ_USER="${var.rabbitmq_user}" \
      -e RABBITMQ_PASS="${var.rabbitmq_pass}" \
      -e POSTGRES_URL="$POSTGRES_URL" \
      -e MONGO_URL="$MONGO_URL" \
      -e MONGO_DB="events_log" \
      ${var.image_name}

    echo "--- DESPLIEGUE FINALIZADO ---"
  EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = { Name = var.service_name }
  }
}

# ── Load Balancer ──────────────────────────────────────────────────────────────
resource "aws_lb" "alb" {
  name               = "${var.service_name}-alb"
  load_balancer_type = "application"
  subnets            = data.aws_subnets.default.ids
  security_groups    = [aws_security_group.sg.id]
}

resource "aws_lb_target_group" "tg" {
  name        = "${var.service_name}-tg"
  port        = var.port
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.default.id
  target_type = "instance"

  health_check {
    path                = "/health"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    interval            = 30
  }
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = var.port
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

# ── Auto Scaling Group ─────────────────────────────────────────────────────────
resource "aws_autoscaling_group" "asg" {
  name                = "${var.service_name}-asg"
  desired_capacity    = 1
  max_size            = 2
  min_size            = 1
  vpc_zone_identifier = data.aws_subnets.default.ids
  target_group_arns   = [aws_lb_target_group.tg.arn]

  launch_template {
    id      = aws_launch_template.lt.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = var.service_name
    propagate_at_launch = true
  }
}
