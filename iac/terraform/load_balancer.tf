# =========================================================================
# Google Cloud Application Load Balancer (Balanceador de Carga HTTP Externo)
# Equivalente ao Application Load Balancer (ALB) da AWS
# =========================================================================

# 1. IP Estático Global Público reservado para o Load Balancer
resource "google_compute_global_address" "lb_ip" {
  name        = "${var.environment_name}-lb-static-ip"
  description = "Endereço IP estático público para acesso à API pelo mundo externo"
}

# 2. Health Check para o Load Balancer verificar o status das instâncias no backend
resource "google_compute_health_check" "lb_health_check" {
  name                = "${var.environment_name}-lb-health-check"
  check_interval_sec  = 10
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 2

  http_health_check {
    port         = 80
    request_path = "/api/health"
  }
}

# 3. Backend Service: Conecta o Load Balancer ao Managed Instance Group (MIG)
resource "google_compute_backend_service" "api_backend_service" {
  name                  = "${var.environment_name}-backend-service"
  protocol              = "HTTP"
  port_name             = "http"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  timeout_sec           = 30

  backend {
    group           = google_compute_region_instance_group_manager.api_mig.instance_group
    balancing_mode  = "UTILIZATION"
    max_utilization = 0.8
    capacity_scaler = 1.0
  }

  health_checks = [google_compute_health_check.lb_health_check.id]
}

# 4. URL Map: Define as regras de roteamento (envia todo o tráfego para o Backend Service)
resource "google_compute_url_map" "url_map" {
  name            = "${var.environment_name}-url-map"
  default_service = google_compute_backend_service.api_backend_service.id
}

# 5. Target HTTP Proxy: Direciona as requisições da porta 80 para o URL Map
resource "google_compute_target_http_proxy" "http_proxy" {
  name    = "${var.environment_name}-target-http-proxy"
  url_map = google_compute_url_map.url_map.id
}

# 6. Global Forwarding Rule: A porta de entrada pública do Load Balancer
resource "google_compute_global_forwarding_rule" "forwarding_rule" {
  name                  = "${var.environment_name}-forwarding-rule"
  ip_protocol           = "TCP"
  port_range            = "80"
  target                = google_compute_target_http_proxy.http_proxy.id
  ip_address            = google_compute_global_address.lb_ip.address
  load_balancing_scheme = "EXTERNAL_MANAGED"
}
