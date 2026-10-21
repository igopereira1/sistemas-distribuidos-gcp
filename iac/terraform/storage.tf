# =========================================================================
# 1. Google Cloud Storage (Bucket para Upload de Imagens)
# Equivalente ao Amazon S3 da AWS
# =========================================================================

# Gera um sufixo aleatório para garantir nome único global no Cloud Storage
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "google_storage_bucket" "images_bucket" {
  name                        = "${var.environment_name}-imagens-${random_id.bucket_suffix.hex}"
  location                    = var.region
  force_destroy               = true # Permite destruir o bucket em encerramento do ambiente mesmo com arquivos
  uniform_bucket_level_access = true # Boa prática recomendada pelo Google Cloud

  cors {
    origin          = ["*"]
    method          = ["GET", "HEAD"]
    response_header = ["*"]
    max_age_seconds = 3600
  }
}

# Permite que qualquer usuário na internet visualize/baixe as fotos enviadas
# (Equivalente à política de acesso público do S3)
resource "google_storage_bucket_iam_member" "public_read" {
  bucket = google_storage_bucket.images_bucket.name
  role   = "roles/storage.objectViewer"
  member = "allUsers"
}

# =========================================================================
# 2. Google Artifact Registry (Repositório Docker)
# Equivalente ao Amazon ECR da AWS
# =========================================================================
resource "google_artifact_registry_repository" "docker_repo" {
  repository_id = "backend-repo"
  format        = "DOCKER"
  location      = var.region
  description   = "Repositório de imagens Docker da API Backend"

  cleanup_policies {
    id     = "delete-untagged"
    action = "DELETE"
    condition {
      tag_state = "UNTAGGED"
    }
  }

  cleanup_policies {
    id     = "keep-recent-tagged"
    action = "KEEP"
    most_recent_versions {
      keep_count = 5
    }
  }
}
