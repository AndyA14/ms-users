output "instance_public_ip" {
  description = "La dirección IP pública de la instancia EC2"
  value       = aws_launch_template.lt.latest_version
}

output "alb_dns_name" {
  description = "El nombre DNS del Application Load Balancer"
  value       = aws_lb.alb.dns_name
}

output "instance_id" {
  description = "ID de la instancia EC2 lanzada"
  value       = aws_launch_template.lt.latest_version
}

output "key_pair_name" {
  description = "El nombre de la clave SSH creada"
  value       = aws_key_pair.kp.key_name
}

output "security_group_id" {
  description = "ID del grupo de seguridad creado"
  value       = aws_security_group.sg.id
}

output "launch_template_id" {
  description = "ID de la plantilla de lanzamiento"
  value       = aws_launch_template.lt.id
}

output "autoscaling_group_name" {
  description = "El nombre del grupo de autoescalado"
  value       = aws_autoscaling_group.asg.name
}

output "target_group_arn" {
  description = "El ARN del grupo de destino (target group)"
  value       = aws_lb_target_group.tg.arn
}

output "bucket_name" {
  description = "Nombre del bucket de S3 para el estado de Terraform"
  value       = "tf-state-ms-users-exam-2026" # Cambia esto si el nombre del bucket es diferente
}

output "dynamodb_table_name" {
  description = "Nombre de la tabla DynamoDB para bloqueo del estado"
  value       = "tf-locks-ms-users-exam" # Cambia esto si el nombre de la tabla es diferente
}
