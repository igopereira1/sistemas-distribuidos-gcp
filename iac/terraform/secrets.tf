# =========================================================================
# Google Secret Manager (Gerenciamento de Segredos e Credenciais)
# Equivalente ao AWS Secrets Manager
# =========================================================================

# Gera senha forte e aleatoria para o banco MySQL
resource "random_password" "db_password" {
  length  = 16
  special = false
}

# Cria o container do segredo no Secret Manager
resource "google_secret_manager_secret" "db_credentials" {
  secret_id = "${var.environment_name}-db-credentials"

  replication {
    auto {}
  }
}

# Cria a versao do segredo com as credenciais em formato JSON
resource "google_secret_manager_secret_version" "db_credentials_version" {
  secret      = google_secret_manager_secret.db_credentials.id
  secret_data = jsonencode({
    username = "admin"
    password = random_password.db_password.result
    database = "app_db"
    host     = google_sql_database_instance.mysql.public_ip_address
  })
}
