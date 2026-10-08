# =========================================================================
# Google Compute Engine: Template de Instâncias e Auto Scaling (MIG)
# Equivalente ao EC2 Launch Template e Auto Scaling Group (ASG) da AWS
# [Referência Teórica: Tanenbaum - Tolerância a Falhas e Redundância de Hardware]
# =========================================================================

# 1. Template de Instâncias (Launch Template)
resource "google_compute_instance_template" "api_template" {
  name_prefix  = "${var.environment_name}-template-"
  machine_type = "e2-micro" # Tipo economico de VM para testes e estudos
  region       = var.region

  tags = ["backend-instance"]

  disk {
    source_image = "ubuntu-os-cloud/ubuntu-2204-lts"
    auto_delete  = true
    boot         = true
    disk_size_gb = 20
    disk_type    = "pd-balanced"
  }

  network_interface {
    network    = google_compute_network.vpc.id
    subnetwork = google_compute_subnetwork.subnet.id

    access_config {
      # Atribui IP publico efemero para permitir saida a internet e download de pacotes
    }
  }

  service_account {
    email  = google_service_account.vm_service_account.email
    scopes = ["cloud-platform"]
  }

  # Startup Script: Executado automaticamente no primeiro boot da VM (equivalente ao UserData do EC2)
  metadata_startup_script = <<-EOF
    #!/bin/bash
    set -e

    # 1. Update do SO e instalacao do Docker e utilitarios
    apt-get update -y
    apt-get install -y docker.io jq curl
    systemctl enable docker
    systemctl start docker

    # 2. Leitura dinamica dos segredos no Secret Manager via gcloud CLI
    SECRET_JSON=$(gcloud secrets versions access latest --secret="${google_secret_manager_secret.db_credentials.secret_id}" --project="${var.project_id}")
    DB_USER=$(echo "$SECRET_JSON" | jq -r .username)
    DB_PASS=$(echo "$SECRET_JSON" | jq -r .password)
    DB_NAME=$(echo "$SECRET_JSON" | jq -r .database)
    DB_HOST=$(echo "$SECRET_JSON" | jq -r .host)

    # 3. Autenticacao no Artifact Registry e download da imagem Docker
    gcloud auth configure-docker ${var.region}-docker.pkg.dev --quiet
    IMAGE_URI="${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.docker_repo.name}/backend-api:latest"

    # Tenta baixar a imagem (se ja houver imagem publicada)
    docker pull $IMAGE_URI || true

    # 4. Inicia o container da API injetando as credenciais e o bucket GCS
    docker run -d \
      --name backend-api \
      --restart always \
      -p 80:3000 \
      -e PORT=3000 \
      -e DB_HOST="$DB_HOST" \
      -e DB_USER="$DB_USER" \
      -e DB_PASSWORD="$DB_PASS" \
      -e DB_NAME="$DB_NAME" \
      -e DB_PORT=3306 \
      -e GCP_PROJECT_ID="${var.project_id}" \
      -e GCS_BUCKET_NAME="${google_storage_bucket.images_bucket.name}" \
      $IMAGE_URI || true
  EOF

  lifecycle {
    create_before_destroy = true
  }
}

# 2. Health Check para Autorrecuperacao (Autohealing) do MIG
resource "google_compute_health_check" "mig_health_check" {
  name                = "${var.environment_name}-mig-health-check"
  check_interval_sec  = 10
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 2

  http_health_check {
    port         = 80
    request_path = "/api/health"
  }
}

# 3. Managed Instance Group (MIG Regional)
# Distribui as VMs automaticamente entre as zonas da regiao para tolerancia a falhas
resource "google_compute_region_instance_group_manager" "api_mig" {
  name               = "${var.environment_name}-mig"
  base_instance_name = "${var.environment_name}-api"
  region             = var.region

  version {
    instance_template = google_compute_instance_template.api_template.id
  }

  named_port {
    name = "http"
    port = 80
  }

  auto_healing_policies {
    health_check      = google_compute_health_check.mig_health_check.id
    initial_delay_sec = 180 # Tempo para instalacao do Docker e subida do container
  }
}

# 4. Autoscaler Regional (Elasticidade de 2 a 5 instâncias)
resource "google_compute_region_autoscaler" "api_autoscaler" {
  name   = "${var.environment_name}-autoscaler"
  region = var.region
  target = google_compute_region_instance_group_manager.api_mig.id

  autoscaling_policy {
    min_replicas    = 2 # Redundancia minima (Principio de Sistemas Distribuidos)
    max_replicas    = 5 # Limite maximo de escala
    cooldown_period = 60

    cpu_utilization {
      target = 0.6 # Dispara nova instancia se o consumo de CPU superar 60%
    }
  }
}
