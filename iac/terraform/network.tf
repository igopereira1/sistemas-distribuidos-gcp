# =========================================================================
# 1. VPC (Rede Virtual Privada em Modo Custom)
# =========================================================================
# Ao contrário do modo automático (que cria subnets em todas as regiões do mundo),
# o modo customizado cria apenas as subnets explicitamente definidas.
resource "google_compute_network" "vpc" {
  name                    = "${var.environment_name}-vpc"
  auto_create_subnetworks = false
  description             = "VPC customizada para o laboratório de Sistemas Distribuídos"
}

# =========================================================================
# 2. Sub-rede Regional
# =========================================================================
# No GCP, as sub-redes são regionais (diferente da AWS, onde subnets são zonais).
# Uma única subnet regional no GCP atende a todas as zonas de disponibilidade daquela região!
resource "google_compute_subnetwork" "subnet" {
  name          = "${var.environment_name}-subnet"
  ip_cidr_range = var.network_cidr
  region        = var.region
  network       = google_compute_network.vpc.id

  # Habilita o Google Private Access para que as VMs acessem APIs da Google sem IP público
  private_ip_google_access = true
}

# =========================================================================
# 3. Regras de Firewall
# =========================================================================

# Permite tráfego HTTP e Health Checks vindos do Google Cloud Load Balancer.
# Os IPs 130.211.0.0/22 e 35.191.0.0/16 são os ranges oficiais de Health Check do GCP.
resource "google_compute_firewall" "allow_lb_health_checks" {
  name        = "${var.environment_name}-allow-lb-and-health-checks"
  network     = google_compute_network.vpc.name
  description = "Permite requisições HTTP e sondas de saúde vindas do Load Balancer do GCP"

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = [
    "130.211.0.0/22",
    "35.191.0.0/16"
  ]

  target_tags = ["backend-instance"]
}

# Permite conexão SSH segura através do Identity-Aware Proxy (IAP)
# O range 35.235.240.0/20 é o range oficial do Google Cloud Identity-Aware Proxy (IAP)
resource "google_compute_firewall" "allow_ssh_iap" {
  name        = "${var.environment_name}-allow-ssh-iap"
  network     = google_compute_network.vpc.name
  description = "Permite conexão SSH segura através do Identity-Aware Proxy (IAP)"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["35.235.240.0/20"]
  target_tags   = ["backend-instance"]
}

# Permite comunicação interna entre os serviços da mesma sub-rede
resource "google_compute_firewall" "allow_internal" {
  name        = "${var.environment_name}-allow-internal"
  network     = google_compute_network.vpc.name
  description = "Permite comunicação interna entre instâncias na mesma sub-rede"

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }
  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }
  allow {
    protocol = "icmp"
  }

  source_ranges = [var.network_cidr]
}
