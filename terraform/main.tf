################################################################################
# PROVIDER
################################################################################
provider "aws" {
  region = var.region
}

################################################################################
# VPC & SUBNETS (default)
################################################################################
data "aws_vpc" "default" { default = true }

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

################################################################################
# SECURITY GROUP
################################################################################
resource "aws_security_group" "sg" {
  name_prefix = "${var.service_name}-sg-"
  description = "SG for ${var.service_name}"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "App port"
    from_port   = var.port
    to_port     = var.port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
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

  lifecycle {
    create_before_destroy = true
  }
}

################################################################################
# LAUNCH TEMPLATE
################################################################################
resource "aws_launch_template" "lt" {
  name_prefix   = "${var.service_name}-lt-"
  image_id      = "ami-0c02fb55956c7d316"   # Amazon Linux 2 (us-east-1)
  instance_type = var.instance_type
  key_name      = aws_key_pair.kp.key_name  # Keypair creado en keypair.tf

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.sg.id]
  }

  user_data = base64encode(<<-EOF
    #!/bin/bash
    # ── Deploy ID: ${var.deploy_timestamp} ──────────────────────────────────
    # Este comentario cambia en cada push (SHA del commit), forzando una nueva
    # versión del Launch Template sin modificar la lógica del script.
    exec > >(tee /var/log/user-data.log | logger -t user-data -s 2>/dev/console) 2>&1

    echo "=== INICIANDO DESPLIEGUE: ${var.service_name} (${var.deploy_timestamp}) ==="

    # ── 1. SWAP (obligatorio para t2.micro con Java/Python) ─────────────────
    if [ ! -f /swapfile ]; then
      dd if=/dev/zero of=/swapfile bs=128M count=16
      chmod 600 /swapfile
      mkswap /swapfile
      swapon /swapfile
      echo "/swapfile swap swap defaults 0 0" >> /etc/fstab
      echo "Swap creado."
    else
      echo "Swap ya existe, se omite."
    fi

    # ── 2. Instalar Docker (solo si no está instalado) ───────────────────────
    if ! command -v docker &> /dev/null; then
      echo "Instalando Docker..."
      yum update -y
      amazon-linux-extras install docker -y
      service docker start
      systemctl enable docker
      usermod -a -G docker ec2-user
      echo "Docker instalado."
    else
      echo "Docker ya instalado: $(docker --version)"
      service docker start || true
    fi

    # ── 3. Esperar a que Docker responda ─────────────────────────────────────
    echo "Esperando a Docker daemon..."
    until docker info > /dev/null 2>&1; do sleep 2; done
    echo "Docker listo."

    # ── 4. Login a Docker Hub ────────────────────────────────────────────────
    echo "${var.docker_password}" | docker login -u "${var.docker_username}" --password-stdin
    echo "Login exitoso."

    # ── 5. Detener y eliminar contenedor anterior (si existe) ────────────────
    if docker ps -a --format '{{.Names}}' | grep -q "^${var.service_name}$"; then
      echo "Deteniendo contenedor anterior..."
      docker stop ${var.service_name} || true
      docker rm   ${var.service_name} || true
    fi

    # ── 6. Pull de la imagen más reciente ────────────────────────────────────
    echo "Descargando imagen: ${var.image_name}"
    docker pull ${var.image_name}

    # ── 7. Ejecutar el microservicio ─────────────────────────────────────────
    # Solo variables de conexión. NO se instala Postgres, MongoDB ni RabbitMQ
    # aquí. El servicio se conecta a la instancia core-infra (account-db).
    docker run -d \
      --name ${var.service_name} \
      --restart always \
      -p ${var.port}:${var.port} \
      -e PORT="${var.port}" \
      -e RABBITMQ_HOST="${var.rabbitmq_host}" \
      -e RABBITMQ_USER="${var.rabbitmq_user}" \
      -e RABBITMQ_PASS="${var.rabbitmq_pass}" \
      -e POSTGRES_URL="${var.postgres_url}" \
      -e MONGO_URL="${var.mongo_url}" \
      -e MONGO_DB="events_log" \
      -e SECRET_KEY="${var.secret_key}" \
      ${var.image_name}

    echo "=== DESPLIEGUE FINALIZADO: ${var.service_name} ==="
  EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name      = var.service_name
      DeployID  = var.deploy_timestamp
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

################################################################################
# LOAD BALANCER + TARGET GROUP + LISTENER
################################################################################
resource "aws_lb" "alb" {
  name               = "${var.service_name}-alb"
  load_balancer_type = "application"
  subnets            = data.aws_subnets.default.ids
  security_groups    = [aws_security_group.sg.id]

  lifecycle {
    create_before_destroy = true
  }
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
    timeout             = 5
  }

  lifecycle {
    create_before_destroy = true
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

################################################################################
# AUTO SCALING GROUP
# ─────────────────────────────────────────────────────────────────────────────
# instance_refresh: cuando el Launch Template cambia de versión, el ASG
# reemplaza automáticamente las instancias antiguas con instancias nuevas
# (que ejecutan el user_data actualizado = imagen Docker más reciente).
# min_healthy_percentage = 0 permite hacer el reemplazo en un t2.micro
# sin necesidad de tener 2 instancias simultáneas.
################################################################################
resource "aws_autoscaling_group" "asg" {
  name                = "${var.service_name}-asg"
  desired_capacity    = 1
  max_size            = 2
  min_size            = 1
  vpc_zone_identifier = data.aws_subnets.default.ids
  target_group_arns   = [aws_lb_target_group.tg.arn]

  launch_template {
    id      = aws_launch_template.lt.id
    version = "$Latest"   # ← siempre usa la versión más reciente del LT
  }

  # ── El corazón del "actualizar sin duplicar" ──────────────────────────────
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 0    # permite reemplazar la única instancia
      instance_warmup        = 60   # segundos antes de considerar sana la nueva
    }
    triggers = ["launch_template"]  # se activa cuando cambia el LT
  }

  tag {
    key                 = "Name"
    value               = var.service_name
    propagate_at_launch = true
  }

  # No recrear el ASG si solo cambia el launch_template
  lifecycle {
    ignore_changes = [desired_capacity]
  }
}


