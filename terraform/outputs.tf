# Salidas para la infraestructura desplegada

# Nombre de la VPC
output "vpc_name" {
  value = data.aws_vpc.default.id
  description = "ID de la VPC por defecto"
}

# Subnet IDs
output "subnet_ids" {
  value = data.aws_subnets.default.ids
  description = "IDs de las subredes dentro de la VPC"
}

# AMI ID
output "ami_id" {
  value = data.aws_ami.amazon_linux_2023.id
  description = "ID de la AMI de Amazon Linux 2023 utilizada"
}

# Key Pair Name
output "key_pair_name" {
  value = aws_key_pair.kp.key_name
  description = "Nombre del Key Pair utilizado para las instancias EC2"
}

# Security Group ID
output "security_group_id" {
  value = aws_security_group.sg.id
  description = "ID del Security Group creado"
}

# Launch Template ID
output "launch_template_id" {
  value = aws_launch_template.lt.id
  description = "ID del Launch Template creado"
}

# Load Balancer DNS Name
output "alb_dns_name" {
  value = aws_lb.alb.dns_name
  description = "DNS del Application Load Balancer"
}

# Load Balancer ARN
output "alb_arn" {
  value = aws_lb.alb.arn
  description = "ARN del Application Load Balancer"
}

# Target Group ARN
output "target_group_arn" {
  value = aws_lb_target_group.tg.arn
  description = "ARN del Target Group asociado al ALB"
}

# Listener ARN
output "alb_listener_arn" {
  value = aws_lb_listener.front_end.arn
  description = "ARN del Listener del ALB"
}

# Auto Scaling Group Name
output "autoscaling_group_name" {
  value = aws_autoscaling_group.asg.name
  description = "Nombre del Auto Scaling Group"
}

# Auto Scaling Group ARN
output "autoscaling_group_arn" {
  value = aws_autoscaling_group.asg.arn
  description = "ARN del Auto Scaling Group"
}

# Auto Scaling Group Launch Template Version
output "autoscaling_group_launch_template_version" {
  value = aws_autoscaling_group.asg.launch_template[0].version
  description = "Versión del Launch Template en el Auto Scaling Group"
}

# Instancias dentro del Auto Scaling Group (ASG)
output "asg_instances_public_ips" {
  value = flatten([
    for instance in data.aws_instances.asg_instances.instances : instance.public_ip
  ])
  description = "Las IPs públicas de las instancias en el Auto Scaling Group"
}

output "asg_instances_private_ips" {
  value = flatten([
    for instance in data.aws_instances.asg_instances.instances : instance.private_ip
  ])
  description = "Las IPs privadas de las instancias en el Auto Scaling Group"
}
