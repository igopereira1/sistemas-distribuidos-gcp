# API Backend - Sistemas Distribuídos na Google Cloud Platform (GCP)

Projeto de **Sistemas Distribuídos e Alta Disponibilidade**, implementando uma API REST (Node.js + Express + MySQL) com upload de imagens para o **Google Cloud Storage (GCS)**, infraestrutura como código com **Terraform**, conteinerização com **Docker** e esteira de CI/CD automatizada via **GitHub Actions**.

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

## 🚀 Execução em Ambiente Local (Docker Compose)

O projeto disponibiliza configuração pronta para execução local via contêineres MySQL e da API.

### 1. Clonagem e configuração de variáveis de ambiente

```bash
cp .env.example .env
```

### 2. Inicialização dos serviços

```bash
docker compose up -d --build
```

A API ficará disponível em `http://localhost:3000`.

---

## 📡 Endpoints da API

| Método   | Endpoint        | Descrição                                                                   |
| :------- | :-------------- | :-------------------------------------------------------------------------- |
| `GET`    | `/`             | Teste básico de conexão                                                     |
| `GET`    | `/api/health`   | **Health check** utilizado pelo Load Balancer do GCP                        |
| `GET`    | `/usuarios`     | Lista todos os usuários cadastrados                                         |
| `GET`    | `/usuarios/:id` | Busca um usuário específico por ID                                          |
| `POST`   | `/usuarios`     | Cria um usuário (`nome`, `email`, `foto_url`)                               |
| `PUT`    | `/usuarios/:id` | Atualiza dados de um usuário existente                                      |
| `DELETE` | `/usuarios/:id` | Remove um usuário                                                           |
| `POST`   | `/upload`       | Upload de imagem (`form-data`, campo `imagem`) ➔ retorna URL pública no GCS |

> Uma coleção completa pronta para importação no Postman está disponível no arquivo [`postman-collection.json`](postman-collection.json).

---

## ☁️ Provisionamento da Infraestrutura com Terraform

Toda a infraestrutura na Google Cloud está declarada no diretório [`iac/terraform/`](iac/terraform/).

### 1. Autenticação no GCP

```bash
gcloud auth application-default login
```

### 2. Configuração das variáveis do Terraform

```bash
cd iac/terraform
cp terraform.tfvars.example terraform.tfvars
```

O arquivo `terraform.tfvars` deve ser configurado definindo o `project_id` com o ID do projeto GCP correspondente.

### 3. Inicialização e provisionamento

```bash
terraform init
terraform plan
terraform apply
```

Ao finalizar a aplicação, o Terraform exibirá os seguintes `outputs`:

- `load_balancer_ip`: Endereço IP público para acessar a API na nuvem.
- `artifact_registry_repo`: Repositório Docker criado para o push das imagens.
- `storage_bucket_name`: Nome do bucket do Cloud Storage.
- `cloud_sql_ip`: Endereço IP do banco de dados MySQL.
- `secret_manager_name`: Identificador do segredo criptografado das credenciais.
- `github_actions_sa_email`: E-mail da Service Account criada pelo Terraform para a esteira de CI/CD.

### 🔑 Consulta de Credenciais do Banco de Dados (Cloud SQL & DBeaver)

Como a senha do banco é gerada dinamicamente pelo Terraform e armazenada no **Google Secret Manager**, a consulta das credenciais completas pode ser realizada via terminal:

```bash
gcloud secrets versions access latest \
  --secret="app-distribuida-gcp-db-credentials" \
  --project="ID_DO_PROJETO"
```

O comando retornará o JSON pronto para preenchimento no **DBeaver** ou cliente MySQL:

```json
{
  "database": "app_db",
  "host": "<cloud_sql_ip>",
  "password": "<senha_gerada>",
  "username": "admin"
}
```

> **Configuração no DBeaver:** Na conexão MySQL, preenche-se o Host com o `cloud_sql_ip`, porta `3306`, usuário `admin`, senha fornecida no JSON e banco `app_db`. Em caso de erro de chave pública, deve-se habilitar `allowPublicKeyRetrieval = true` na aba *Driver properties*.

---

## 🔄 Esteira de CI/CD (GitHub Actions)

A esteira em [`.github/workflows/deploy-backend-gcp.yml`](.github/workflows/deploy-backend-gcp.yml) é disparada a cada `push` na branch `main`:

1. Autenticação no Google Cloud via Service Account.
2. Build da imagem Docker com tag semântica (`v1.0.<run_number>`) e tag `latest`.
3. Publicação da imagem no **Google Artifact Registry**.
4. Execução de **Rolling Restart** no *Managed Instance Group (MIG)*, atualizando as instâncias sem indisponibilidade para os usuários.

> [!NOTE]
> **Sobre o status inicial `no healthy upstream` no Load Balancer:**  
> Logo após o `terraform apply`, o repositório do Artifact Registry nasce vazio. As instâncias do MIG aguardam o primeiro deploy para realizar o download do contêiner. Por esse motivo, requisições enviadas ao IP do Load Balancer antes da primeira execução da esteira retornarão `no healthy upstream`. Após a conclusão do deploy via GitHub Actions e publicação da imagem, o Load Balancer reconhecerá as instâncias saudáveis e responderá com `{"status":"healthy"}`.

### Configuração de Secrets no GitHub

A Service Account da esteira (`github-actions-sa`) e as respectivas permissões de menor privilégio são criadas automaticamente pelo Terraform em [`iac/terraform/iam.tf`](iac/terraform/iam.tf).

Para a configuração da esteira, deve-se gerar a chave JSON da conta de serviço para inclusão nos Secrets do repositório:

```bash
# 1. Gerar a chave JSON da Service Account provisionada pelo Terraform
gcloud iam service-accounts keys create ~/.config/github-actions-sa-key.json \
  --iam-account="github-actions-sa@ID_DO_PROJETO.iam.gserviceaccount.com"
```

Devem ser configurados os seguintes Secrets em **Settings > Secrets and variables > Actions**:

- `GCP_PROJECT_ID`: ID do projeto no Google Cloud (ex: `ybytu-dev`).
- `GCP_SA_KEY`: Conteúdo completo do arquivo JSON gerado (`cat ~/.config/github-actions-sa-key.json`).
- `GCP_REGION`: Região utilizada (ex: `us-central1`).
