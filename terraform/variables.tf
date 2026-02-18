################################################################################
# VARIABLES
################################################################################

variable "service_name" {
  description = "Nombre del microservicio (ej: ms-users)"
  type        = string
}

variable "instance_type" {
  description = "Tipo de instancia EC2"
  type        = string
  default     = "t2.micro"
}

variable "port" {
  description = "Puerto en que corre el microservicio"
  type        = number
}

variable "region" {
  description = "Región de AWS"
  type        = string
  default     = "us-east-1"
}

# ── Versionado del deploy ─────────────────────────────────────────────────────
variable "deploy_timestamp" {
  description = "SHA del commit (github.sha). Cambia en cada push, forzando nueva versión del Launch Template y activando el Instance Refresh del ASG."
  type        = string
  default     = "manual"
}

# ── Docker Hub ────────────────────────────────────────────────────────────────
variable "docker_username" {
  description = "Usuario de Docker Hub"
  type        = string
  sensitive   = true
}

variable "docker_password" {
  description = "Contraseña o token de Docker Hub"
  type        = string
  sensitive   = true
}

variable "image_name" {
  description = "Imagen Docker completa (ej: aceofglass14/ms-users:latest)"
  type        = string
}

# ── Conexiones a core-infra (account-db) ─────────────────────────────────────
variable "rabbitmq_host" {
  description = "IP o DNS de la instancia core-infra que corre RabbitMQ"
  type        = string
}

variable "rabbitmq_user" {
  description = "Usuario de RabbitMQ"
  type        = string
  default     = "guest"
}

variable "rabbitmq_pass" {
  description = "Contraseña de RabbitMQ"
  type        = string
  sensitive   = true
  default     = "guest"
}

variable "postgres_url" {
  description = "Connection string de PostgreSQL en core-infra (ej: postgresql://admin:admin123@<IP>:5432/ms_users)"
  type        = string
  sensitive   = true
}

variable "mongo_url" {
  description = "Connection string de MongoDB en core-infra (ej: mongodb://<IP>:27017)"
  type        = string
  sensitive   = true
}

# ── Variables opcionales (solo las usa el servicio que las necesite) ──────────
variable "secret_key" {
  description = "Clave secreta para JWT (usada por ms-auth). Dejar vacío si no aplica."
  type        = string
  sensitive   = true
  default     = ""
}

variable "extra_env" {
  description = "Variables de entorno adicionales en formato KEY=VALUE separadas por \\n"
  type        = string
  default     = ""
}
