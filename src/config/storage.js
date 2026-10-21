const { Storage } = require('@google-cloud/storage');

// =========================================================================
// Cliente do Google Cloud Storage (GCS)
// =========================================================================
// O SDK do GCP utiliza "Application Default Credentials" (ADC):
// - Na nuvem (Compute Engine / Cloud Run), ele autentica automaticamente
//   através da Service Account vinculada à máquina, dispensando senhas ou
//   chaves de acesso no código (Zero Secret Hardcoding).
// - Localmente, se a variável GOOGLE_APPLICATION_CREDENTIALS estiver definida,
//   ele usará a chave JSON apontada por ela.
const storage = new Storage({
  projectId: process.env.GCP_PROJECT_ID,
});

const bucketName = process.env.GCS_BUCKET_NAME || 'app-imagens-padrao';
const bucket = storage.bucket(bucketName);

module.exports = { storage, bucket, bucketName };
