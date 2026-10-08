# =========================================================================
# Google Cloud IAM (Service Account para as Instâncias de Computação)
# Equivalente ao EC2InstanceRole e InstanceProfile da AWS
# =========================================================================

# 1. Cria a Service Account dedicada para as VMs
resource "google_service_account" "vm_service_account" {
  account_id   = "${var.environment_name}-vm-sa"
  display_name = "Service Account para as VMs da API Backend"
  description  = "Identidade gerenciada para as VMs acessarem Artifact Registry, Secret Manager e Storage sem senhas no codigo"
}

# 2. Atribui permissoes granulares (Principio do Menor Privilegio)

# Acesso de leitura para puxar imagens Docker do Artifact Registry
resource "google_project_iam_member" "artifact_registry_reader" {
  project = var.project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${google_service_account.vm_service_account.email}"
}

# Acesso de leitura aos segredos do Secret Manager
resource "google_project_iam_member" "secret_accessor" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.vm_service_account.email}"
}

# Acesso para gravar imagens no Cloud Storage
resource "google_project_iam_member" "storage_admin" {
  project = var.project_id
  role    = "roles/storage.objectAdmin"
  member  = "serviceAccount:${google_service_account.vm_service_account.email}"
}

# Acesso para emitir logs no Cloud Logging
resource "google_project_iam_member" "log_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.vm_service_account.email}"
}

# Acesso para emitir metricas no Cloud Monitoring
resource "google_project_iam_member" "metric_writer" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.vm_service_account.email}"
}
