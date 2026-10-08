# =========================================================================
# Google Cloud SQL (MySQL 8.0 Gerenciado)
# Equivalente ao Amazon RDS for MySQL da AWS
# =========================================================================

# Sufixo aleatorio para o nome da instancia (o GCP proibe reutilizar o mesmo
# nome de instancia Cloud SQL por ate 7 dias apos a exclusao).
resource "random_id" "db_suffix" {
  byte_length = 4
}

resource "google_sql_database_instance" "mysql" {
  name             = "${var.environment_name}-mysql-${random_id.db_suffix.hex}"
  database_version = "MYSQL_8_0"
  region           = var.region

  # Permite destruir facilmente a instancia no final do laboratorio (terraform destroy)
  deletion_protection = false

  settings {
    # Tier economico ideal para laboratorios de estudo e testes
    tier              = "db-f1-micro"
    disk_size         = 10 # 10 GB de disco SSD
    disk_type         = "PD_SSD"
    availability_type = "ZONAL" # Em producao de alta disponibilidade, usar REGIONAL (Multi-AZ)

    ip_configuration {
      ipv4_enabled = true # Acesso publico didatico para laboratorio

      # Permite conectar diretamente de clientes locais (DBeaver, MySQL Workbench)
      # Para ambiente de desenvolvimento/testes. Em producao real, restringir aos IPs especificos!
      authorized_networks {
        name  = "acesso-didatico-laboratorio"
        value = "0.0.0.0/0"
      }
    }

    backup_configuration {
      enabled = false # Desabilitado para economizar custos de laboratorio
    }
  }
}

# Cria o banco de dados da aplicacao
resource "google_sql_database" "database" {
  name     = "app_db"
  instance = google_sql_database_instance.mysql.name
}

# Cria o usuario administrador do banco com a senha gerada aleatoriamente
resource "google_sql_user" "db_user" {
  name     = "admin"
  instance = google_sql_database_instance.mysql.name
  password = random_password.db_password.result
}
