################################################################################
# OUTPUTS
################################################################################

# Output del ID del VPC creado
output "vpc_id" {
  description = "ID del VPC por defecto"
  value       = data.aws_vpc.default.id
}

# Output de las subredes asociadas al VPC
output "subnet_ids" {
  description = "IDs de las subredes asociadas al VPC por defecto"
  value       = data.aws_subnets.default.ids
}

# Output del ID del Security Group creado
output "security_group_id" {
  description = "ID del Security Group para el servicio"
  value       = aws_security_group.sg.id
}

# Output del ID del Launch Template
output "launch_template_id" {
  description = "ID del Launch Template"
  value       = aws_launch_template.lt.id
}

# Output del ID del Load Balancer creado
output "load_balancer_id" {
  description = "ID del Load Balancer creado"
  value       = aws_lb.alb.id
}

# Output del ARN del Target Group
output "target_group_arn" {
  description = "ARN del Target Group asociado al Load Balancer"
  value       = aws_lb_target_group.tg.arn
}

# Output del ARN del Listener
output "listener_arn" {
  description = "ARN del Listener del Load Balancer"
  value       = aws_lb_listener.listener.arn
}

# Output del nombre del servicio (útil para identificar la aplicación)
output "service_name" {
  description = "Nombre del servicio"
  value       = var.service_name
}

# Output del nombre de la Key Pair asociada a la instancia EC2
output "key_pair_name" {
  description = "Nombre de la Key Pair utilizada para la instancia EC2"
  value       = aws_key_pair.kp.key_name
}

# Output del ARN del Auto Scaling Group
output "auto_scaling_group_arn" {
  description = "ARN del Auto Scaling Group"
  value       = aws_autoscaling_group.asg.arn
}

# Output del Health Check del Target Group
output "health_check_path" {
  description = "Health check path configurado en el Target Group"
  value       = aws_lb_target_group.tg.health_check[0].path
}

# Output de la URL pública de la instancia EC2 (si la IP pública está asociada)
output "instance_public_ip" {
  description = "Dirección IP pública de la instancia EC2 (si está asociada)"
  value       = aws_launch_template.lt.network_interfaces[0].associate_public_ip_address ? "Pública disponible" : "No asociada"
}

# Output del nombre de la imagen de Docker (utilizada en el user_data)
output "docker_image_name" {
  description = "Nombre de la imagen de Docker utilizada"
  value       = var.image_name
}
