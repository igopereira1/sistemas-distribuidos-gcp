# =========================================================================
# Outputs (Valores de Retorno da Infraestrutura Criada no GCP)
# =========================================================================

output "load_balancer_ip" {
  description = "Endereco IP publico do Load Balancer para acessar a API"
  value       = google_compute_global_address.lb_ip.address
}

output "artifact_registry_repo" {
  description = "URI do repositorio no Artifact Registry para build e push das imagens Docker"
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.docker_repo.name}"
}

output "storage_bucket_name" {
  description = "Nome do bucket no Google Cloud Storage para upload de imagens"
  value       = google_storage_bucket.images_bucket.name
}

output "cloud_sql_ip" {
  description = "Endereco IP publico da instancia Cloud SQL MySQL"
  value       = google_sql_database_instance.mysql.public_ip_address
}

output "secret_manager_name" {
  description = "Nome do segredo com as credenciais do banco no Secret Manager"
  value       = google_secret_manager_secret.db_credentials.secret_id
}
