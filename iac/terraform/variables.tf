variable "project_id" {
  description = "ID do projeto na Google Cloud Platform (GCP)"
  type        = string
}

variable "region" {
  description = "Região padrão para os recursos da GCP"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "Zona padrão para recursos zonais"
  type        = string
  default     = "us-central1-a"
}

variable "environment_name" {
  description = "Nome do ambiente para prefixar recursos"
  type        = string
  default     = "app-distribuida-gcp"
}

variable "network_cidr" {
  description = "Bloco CIDR da sub-rede regional"
  type        = string
  default     = "10.0.1.0/24"
}
