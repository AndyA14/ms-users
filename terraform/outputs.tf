output "key_pair_name" {
  description = "Nombre del Key Pair generado"
  value       = aws_key_pair.kp.key_name
}

output "public_ip" {
  description = "Dirección IP pública del Auto Scaling Group"
  value       = aws_eip.elastic_ip.public_ip
}

output "alb_dns_name" {
  description = "DNS del Load Balancer"
  value       = aws_lb.alb.dns_name
}

output "security_group_id" {
  description = "ID del Security Group creado"
  value       = aws_security_group.sg.id
}

output "launch_template_id" {
  description = "ID del Launch Template"
  value       = aws_launch_template.lt.id
}

output "autoscaling_group_name" {
  description = "Nombre del Auto Scaling Group"
  value       = aws_autoscaling_group.asg.name
}

output "target_group_arn" {
  description = "ARN del Target Group del Load Balancer"
  value       = aws_lb_target_group.tg.arn
}
