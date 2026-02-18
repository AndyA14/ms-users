# Outputs para la Key Pair

output "key_pair_private_key_file" {
  description = "Ubicación del archivo .pem de la llave privada"
  value       = local_file.pem.filename
  sensitive   = true
}

# Outputs para el Security Group

output "security_group_id" {
  description = "ID del Security Group"
  value       = aws_security_group.sg.id
}

# Puerto de ingreso de la primera regla del Security Group
output "security_group_ingress_port" {
  description = "Puerto de ingreso configurado en el primer rule"
  value       = [for ingress in aws_security_group.sg.ingress : ingress.from_port][0]
}

# Outputs para la Instancia EC2

output "instance_id" {
  description = "ID de la instancia EC2"
  value       = aws_instance.server.id
}

output "instance_public_ip" {
  description = "Dirección IP pública de la instancia EC2"
  value       = aws_instance.server.public_ip
}

output "instance_state" {
  description = "Estado de la instancia EC2"
  value       = aws_instance.server.instance_state
}

output "instance_ami" {
  description = "AMI usada para la instancia EC2"
  value       = aws_instance.server.ami
}

# Salida para la Key Pair
output "key_pair_name" {
  description = "Nombre del Key Pair"
  value       = aws_key_pair.kp.key_name
}

# Output para la URL de la imagen Docker (para referencia)
output "docker_image" {
  description = "URL de la imagen Docker"
  value       = local.image
}
