resource "tls_private_key" "pk" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "kp" {
  key_name   = "${var.service_name}-key"
  public_key = tls_private_key.pk.public_key_openssh

  lifecycle {
    # Si la llave ya existe en AWS, no la recreamos.
    # Útil cuando el estado S3 ya la tiene registrada.
    ignore_changes = [public_key]
  }
}

resource "local_file" "ssh_key" {
  filename        = "${path.module}/${var.service_name}-key.pem"
  content         = tls_private_key.pk.private_key_pem
  file_permission = "0400"
}

output "key_name" {
  value = aws_key_pair.kp.key_name
}
