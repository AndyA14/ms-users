terraform {
  backend "s3" {
    # Valores fijos que NO cambian entre sesiones
    key    = "terraform.tfstate"
    region = "us-east-1"

    # El bucket se inyecta desde el workflow con -backend-config
    # bucket = <inyectado en workflow>
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}
