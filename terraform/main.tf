provider "aws" {
  region = var.region
}

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

# ── SSM Parameters (evita exponer secretos en user_data) ─────────────────────
# La contraseña se guarda en SSM y la instancia la lee en runtime.
resource "aws_ssm_parameter" "docker_password" {
  name  = "/${var.service_name}/docker_password"
  type  = "SecureString"
  value = var.docker_password
}

resource "aws_ssm_parameter" "postgres_url" {
  name  = "/${var.service_name}/postgres_url"
  type  = "SecureString"
  value = var.postgres_url
}

resource "aws_ssm_parameter" "mongo_url" {
  name  = "/${var.service_name}/mongo_url"
  type  = "SecureString"
  value = var.mongo_url
}

# ── IAM Role para que EC2 pueda leer SSM ──────────────────────────────────────
resource "aws_iam_role" "ec2_ssm_role" {
  name = "${var.service_name}-ec2-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_policy" {
  role       = aws_iam_role.ec2_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess"
}

resource "aws_iam_instance_profile" "profile" {
  name = "${var.service_name}-profile"
  role = aws_iam_role.ec2_ssm_role.name
}

# ── Launch Template ────────────────────────────────────────────────────────────
resource "aws_launch_template" "lt" {
  name_prefix            = "${var.service_name}-lt"
  image_id               = "ami-0c02fb55956c7d316"
  instance_type          = var.instance_type
  key_name               = var.key_name
  iam_instance_profile   { name = aws_iam_instance_profile.profile.name }

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.sg.id]
  }

  # 🔐 Los secretos se leen desde SSM en runtime, NUNCA se imprimen en user_data
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

    # 2. Instalar Docker y AWS CLI
    yum update -y
    amazon-linux-extras install docker -y
    service docker start
    usermod -a -G docker ec2-user
    systemctl enable docker

    # 3. Leer secretos desde SSM (nunca están en texto plano aquí)
    REGION="${var.region}"
    DOCKER_PASS=$(aws ssm get-parameter --name "/${var.service_name}/docker_password" \
      --with-decryption --region $REGION --query Parameter.Value --output text)
    POSTGRES_URL=$(aws ssm get-parameter --name "/${var.service_name}/postgres_url" \
      --with-decryption --region $REGION --query Parameter.Value --output text)
    MONGO_URL=$(aws ssm get-parameter --name "/${var.service_name}/mongo_url" \
      --with-decryption --region $REGION --query Parameter.Value --output text)

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
