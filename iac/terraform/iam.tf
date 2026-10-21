# =========================================================================
# Google Cloud IAM (Service Account para as Instâncias de Computação)
# Equivalente ao EC2InstanceRole e InstanceProfile da AWS
# =========================================================================

# 1. Cria a Service Account dedicada para as VMs
resource "google_service_account" "vm_service_account" {
  account_id   = "${var.environment_name}-vm-sa"
  display_name = "Service Account para as VMs da API Backend"
  description  = "Identidade gerenciada para as VMs acessarem Artifact Registry, Secret Manager e Storage sem senhas no código"
}

# 2. Atribui permissões granulares (Princípio do Menor Privilégio)

# Acesso de leitura para puxar imagens exclusivamente deste repositório no Artifact Registry
resource "google_artifact_registry_repository_iam_member" "artifact_registry_reader" {
  project    = var.project_id
  location   = var.region
  repository = google_artifact_registry_repository.docker_repo.name
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:${google_service_account.vm_service_account.email}"
}

# Acesso de leitura exclusivamente ao segredo das credenciais do banco no Secret Manager
resource "google_secret_manager_secret_iam_member" "secret_accessor" {
  project   = var.project_id
  secret_id = google_secret_manager_secret.db_credentials.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.vm_service_account.email}"
}

# Acesso para gravar imagens exclusivamente dentro do bucket de fotos deste projeto
resource "google_storage_bucket_iam_member" "storage_admin" {
  bucket = google_storage_bucket.images_bucket.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.vm_service_account.email}"
}

# Acesso para emitir logs no Cloud Logging
resource "google_project_iam_member" "log_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.vm_service_account.email}"
}

# Acesso para emitir métricas no Cloud Monitoring
resource "google_project_iam_member" "metric_writer" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.vm_service_account.email}"
}

# =========================================================================
# Google Cloud IAM (Service Account para a Esteira de CI/CD do GitHub Actions)
# =========================================================================

# 1. Cria a Service Account para o GitHub Actions
resource "google_service_account" "github_actions_sa" {
  account_id   = "github-actions-sa"
  display_name = "Service Account para o GitHub Actions CI/CD"
  description  = "Identidade usada pelo GitHub Actions para build, migração de banco, push de contêineres e deploy no MIG"
}

# 2. Atribui as permissões necessárias para o pipeline (Princípio do Menor Privilégio)
resource "google_project_iam_member" "github_actions_roles" {
  for_each = toset([
    "roles/artifactregistry.writer",
    "roles/compute.instanceAdmin.v1",
    "roles/compute.loadBalancerAdmin",
    "roles/iam.serviceAccountUser",
    "roles/secretmanager.secretAccessor",
  ])

  project = var.project_id
  role    = each.key
  member  = "serviceAccount:${google_service_account.github_actions_sa.email}"
}
