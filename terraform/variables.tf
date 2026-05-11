variable "namespace" {
  type        = string
  description = "Namespace to provision"
  default     = "devops-challenge"
}

variable "memory_quota" {
  type        = string
  description = "Total memory quota for the namespace"
  default     = "512Mi"
}

variable "api_token" {
  type        = string
  description = "API token consumed by the app"
  sensitive     = true
}

# Kubernetes Provider Variables

variable "k8s_host" {
  type        = string
  description = "Kubernetes API server endpoint"
}

variable "k8_ca_cert" {
  type        = string
  description = "Base64 encoded Kubernetes CA certificate"
}

variable "k8s_token" {
  type        = string
  description = "Kubernetes authentication token"
  sensitive   = true
}
