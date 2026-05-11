terraform {
  required_version = ">= 1.5.0"
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.20"
    }
  }
}

provider "kubernetes" {
  host                   = trimspace(var.k8s_host)
  cluster_ca_certificate = base64decode(trimspace(var.k8_ca_cert))
  token                  = trimspace(var.k8s_token)
}

