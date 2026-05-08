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
  host                   = var.k8s_host
  cluster_ca_certificate = base64encode(var.k8_ca_cert)
  token                  = var.k8s_token
}

