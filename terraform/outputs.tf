# ─────────────────────────────────────────────────────────────
# VPC & Subnets
# ─────────────────────────────────────────────────────────────

output "vpc_id" {
  description = "ID de la VPC por defecto"
  value       = data.aws_vpc.default.id
}

output "subnet_ids" {
  description = "Subnets usadas por el ALB y ASG"
  value       = data.aws_subnets.default.ids
}

# ─────────────────────────────────────────────────────────────
# Security Group
# ─────────────────────────────────────────────────────────────

output "security_group_id" {
  description = "ID del Security Group"
  value       = aws_security_group.sg.id
}

# ─────────────────────────────────────────────────────────────
# SSM Parameters
# ─────────────────────────────────────────────────────────────

output "ssm_docker_password_name" {
  description = "Nombre del parámetro SSM para Docker password"
  value       = aws_ssm_parameter.docker_password.name
  sensitive   = true
}

output "ssm_postgres_url_name" {
  description = "Nombre del parámetro SSM para Postgres URL"
  value       = aws_ssm_parameter.postgres_url.name
  sensitive   = true
}

output "ssm_mongo_url_name" {
  description = "Nombre del parámetro SSM para Mongo URL"
  value       = aws_ssm_parameter.mongo_url.name
  sensitive   = true
}

# ─────────────────────────────────────────────────────────────
# IAM
# ─────────────────────────────────────────────────────────────

output "ec2_role_name" {
  description = "Nombre del IAM Role asignado a EC2"
  value       = aws_iam_role.ec2_ssm_role.name
}

output "instance_profile_name" {
  description = "Nombre del Instance Profile"
  value       = aws_iam_instance_profile.profile.name
}

# ─────────────────────────────────────────────────────────────
# Launch Template
# ─────────────────────────────────────────────────────────────

output "launch_template_id" {
  description = "ID del Launch Template"
  value       = aws_launch_template.lt.id
}

output "launch_template_latest_version" {
  description = "Última versión del Launch Template"
  value       = aws_launch_template.lt.latest_version
}

# ─────────────────────────────────────────────────────────────
# Load Balancer
# ─────────────────────────────────────────────────────────────

output "alb_arn" {
  description = "ARN del Application Load Balancer"
  value       = aws_lb.alb.arn
}

output "alb_dns_name" {
  description = "DNS público del Application Load Balancer"
  value       = aws_lb.alb.dns_name
}

output "alb_url" {
  description = "URL pública del servicio"
  value       = "http://${aws_lb.alb.dns_name}:${var.port}"
}

# ─────────────────────────────────────────────────────────────
# Target Group
# ─────────────────────────────────────────────────────────────

output "target_group_arn" {
  description = "ARN del Target Group"
  value       = aws_lb_target_group.tg.arn
}

# ─────────────────────────────────────────────────────────────
# Auto Scaling Group
# ─────────────────────────────────────────────────────────────

output "autoscaling_group_name" {
  description = "Nombre del Auto Scaling Group"
  value       = aws_autoscaling_group.asg.name
}

output "autoscaling_group_arn" {
  description = "ARN del Auto Scaling Group"
  value       = aws_autoscaling_group.asg.arn
}
