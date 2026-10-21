# =========================================================================
# Google Cloud SQL (MySQL 8.0 Gerenciado)
# Equivalente ao Amazon RDS for MySQL da AWS
# =========================================================================

# Sufixo aleatório para o nome da instância (o GCP proíbe reutilizar o mesmo
# nome de instância Cloud SQL por até 7 dias após a exclusão).
resource "random_id" "db_suffix" {
  byte_length = 4
}

resource "google_sql_database_instance" "mysql" {
  name             = "${var.environment_name}-mysql-${random_id.db_suffix.hex}"
  database_version = "MYSQL_8_0"
  region           = var.region

  # Permite destruir facilmente a instância no encerramento do ambiente (terraform destroy)
  deletion_protection = false

  settings {
    # Tier econômico ideal para ambientes de estudo e testes
    tier              = "db-f1-micro"
    disk_size         = 10 # 10 GB de disco SSD
    disk_type         = "PD_SSD"
    availability_type = "ZONAL" # Em produção de alta disponibilidade, utilizar REGIONAL (Multi-AZ)

    ip_configuration {
      ipv4_enabled = true # Acesso público para testes e desenvolvimento

      # Permite conectar diretamente de clientes locais (DBeaver, MySQL Workbench)
      # Para ambiente de desenvolvimento/testes. Em produção real, restringir aos IPs específicos!
      authorized_networks {
        name  = "acesso-desenvolvimento-testes"
        value = "0.0.0.0/0"
      }
    }

    backup_configuration {
      enabled = false # Desabilitado para economizar custos em ambiente de testes
    }
  }
}

# Cria o banco de dados da aplicação
resource "google_sql_database" "database" {
  name     = "app_db"
  instance = google_sql_database_instance.mysql.name
}

# Cria o usuário administrador do banco com a senha gerada aleatoriamente
resource "google_sql_user" "db_user" {
  name     = "admin"
  instance = google_sql_database_instance.mysql.name
  password = random_password.db_password.result
}
