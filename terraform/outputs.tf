output "key_pair_name" {
  description = "The name of the SSH Key Pair"
  value       = aws_key_pair.kp.key_name
}

output "key_pair_public_key" {
  description = "The public key of the generated SSH Key Pair"
  value       = tls_private_key.pk.public_key_openssh
}

output "key_pair_private_key_file" {
  description = "The file path to the private key"
  value       = local.pem.filename
}

output "security_group_id" {
  description = "The ID of the security group"
  value       = aws_security_group.sg.id
}

output "security_group_name" {
  description = "The name of the security group"
  value       = aws_security_group.sg.name
}

output "security_group_ingress_port" {
  description = "The port that is open for the service (configured as local.port)"
  value       = aws_security_group.sg.ingress[0].from_port
}

output "instance_id" {
  description = "The ID of the EC2 instance"
  value       = aws_instance.server.id
}

output "instance_public_ip" {
  description = "The public IP address of the EC2 instance"
  value       = aws_instance.server.public_ip
}

output "instance_private_ip" {
  description = "The private IP address of the EC2 instance"
  value       = aws_instance.server.private_ip
}

output "instance_public_dns" {
  description = "The public DNS of the EC2 instance"
  value       = aws_instance.server.public_dns
}

output "instance_private_dns" {
  description = "The private DNS of the EC2 instance"
  value       = aws_instance.server.private_dns
}

output "instance_type" {
  description = "The instance type of the EC2 instance"
  value       = aws_instance.server.instance_type
}

output "instance_ami" {
  description = "The AMI ID used for the EC2 instance"
  value       = aws_instance.server.ami
}

output "instance_state" {
  description = "The current state of the EC2 instance"
  value       = aws_instance.server.state
}
