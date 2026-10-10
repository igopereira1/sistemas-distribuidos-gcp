# API Backend - Sistemas Distribuídos na Google Cloud Platform (GCP)

Projeto prático de **Sistemas Distribuídos e Alta Disponibilidade**, implementando uma API REST (Node.js + Express + MySQL) com upload de imagens para o **Google Cloud Storage (GCS)**, infraestrutura como código com **Terraform**, conteinerização com **Docker** e esteira de CI/CD automatizada via **GitHub Actions**.

---

## 🏛️ Arquitetura Distribuída no GCP

A infraestrutura foi desenhada seguindo os princípios de redundância de hardware, transparência de localização e tolerância a falhas:

```
                          Internet (Clientes / Postman)
                                       │
                                       ▼
                     [ Google Cloud Load Balancer (HTTP:80) ]
                                       │
                   ┌───────────────────┴───────────────────┐
                   ▼                                       ▼
       [ Zona us-central1-a ]                  [ Zona us-central1-b ]
   ┌───────────────────────────────┐       ┌───────────────────────────────┐
   │ VM Compute Engine (e2-micro)  │       │ VM Compute Engine (e2-micro)  │
   │  └── Container: backend-api   │       │  └── Container: backend-api   │
   └───────────────┬───────────────┘       └───────────────┬───────────────┘
                   │                                       │
                   └───────────────────┬───────────────────┘
                                       │
          ┌────────────────────────────┼────────────────────────────┐
          ▼                            ▼                            ▼
[ Google Cloud SQL (MySQL) ]  [ Cloud Storage (Bucket) ]  [ Secret Manager ]
  (Banco de Dados Relacional)   (Fotos / Uploads Públicos)  (Credenciais Criptografadas)
```

---

## 🛠️ Tecnologias Utilizadas

- **Runtime & Framework**: Node.js 24 + Express 4
- **Banco de Dados**: MySQL 8.0 (Google Cloud SQL / Docker local)
- **Armazenamento de Objetos**: Google Cloud Storage (`@google-cloud/storage`)
- **Conteinerização**: Docker & Docker Compose
- **Infraestrutura como Código (IaC)**: Terraform (Google Cloud Provider v6)
- **CI/CD**: GitHub Actions integrado ao Google Artifact Registry

---

## 🚀 Como Rodar Localmente (Docker Compose)

O projeto inclui um ambiente pronto com container MySQL e container da API.

### 1. Clonar o repositório e configurar variáveis

```bash
cp .env.example .env
```

### 2. Subir os serviços

```bash
docker compose up -d --build
```

A API estará disponível em `http://localhost:3000`.

---

## 📡 Endpoints da API

| Método   | Endpoint        | Descrição                                                                   |
| :------- | :-------------- | :-------------------------------------------------------------------------- |
| `GET`    | `/`             | Teste básico de conexão                                                     |
| `GET`    | `/api/health`   | **Health check** usado pelo Load Balancer do GCP                            |
| `GET`    | `/usuarios`     | Lista todos os usuários cadastrados                                         |
| `GET`    | `/usuarios/:id` | Busca um usuário específico por ID                                          |
| `POST`   | `/usuarios`     | Cria um usuário (`nome`, `email`, `foto_url`)                               |
| `PUT`    | `/usuarios/:id` | Atualiza dados de um usuário existente                                      |
| `DELETE` | `/usuarios/:id` | Remove um usuário                                                           |
| `POST`   | `/upload`       | Upload de imagem (`form-data`, campo `imagem`) ➔ retorna URL pública no GCS |

> Uma coleção completa pronta para importação no Postman está disponível no arquivo [`postman-collection.json`](postman-collection.json).

---

## ☁️ Deploy da Infraestrutura com Terraform

Toda a infraestrutura na Google Cloud está declarada na pasta [`iac/terraform/`](iac/terraform/).

### 1. Autenticar no GCP

```bash
gcloud auth application-default login
```

### 2. Configurar variáveis do Terraform

```bash
cd iac/terraform
cp terraform.tfvars.example terraform.tfvars
```

Edite o arquivo `terraform.tfvars` preenchendo o `project_id` com o ID do seu projeto no GCP.

### 3. Inicializar e aplicar

```bash
terraform init
terraform plan
terraform apply
```

Ao finalizar, o Terraform exibirá os `outputs`:

- `load_balancer_ip`: Endereço IP público para acessar a API na nuvem.
- `artifact_registry_repo`: Repositório Docker criado para o push das imagens.
- `storage_bucket_name`: Nome do bucket do Cloud Storage.
- `cloud_sql_ip`: Endereço IP do banco de dados MySQL.
- `secret_manager_name`: Identificador do segredo criptografado das credenciais.
- `github_actions_sa_email`: E-mail da Service Account criada pelo Terraform para a esteira de CI/CD.

---

## 🔄 Pipeline de CI/CD (GitHub Actions)

A esteira em [`.github/workflows/deploy-backend-gcp.yml`](.github/workflows/deploy-backend-gcp.yml) é disparada a cada `push` na branch `main`:

1. Autentica no Google Cloud via Service Account.
2. Faz o build da imagem Docker com tag semântica (`v1.0.<run_number>`) e tag `latest`.
3. Publica a imagem no **Google Artifact Registry**.
4. Dispara um **Rolling Restart** no _Managed Instance Group (MIG)_, atualizando as instâncias sem nenhum downtime para os usuários.

### Configuração dos Secrets no GitHub:

A Service Account do CI/CD (`github-actions-sa`) e suas permissões de menor privilégio já são criadas automaticamente pelo Terraform em [`iac/terraform/iam.tf`](iac/terraform/iam.tf).

Para configurar o pipeline, basta gerar a chave JSON da conta e adicionar nos Secrets do repositório:

```bash
# 1. Gerar a chave JSON da Service Account provisionada pelo Terraform
gcloud iam service-accounts keys create ~/.config/github-actions-sa-key.json \
  --iam-account="github-actions-sa@SEU_PROJECT_ID.iam.gserviceaccount.com"
```

Configure os seguintes Secrets em **Settings > Secrets and variables > Actions**:

- `GCP_PROJECT_ID`: ID do seu projeto no Google Cloud (ex: `ybytu-dev`).
- `GCP_SA_KEY`: Conteúdo completo do arquivo JSON gerado (`cat ~/.config/github-actions-sa-key.json`).
- `GCP_REGION`: Região utilizada (ex: `us-central1`).
