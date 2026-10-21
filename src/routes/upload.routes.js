const { Router } = require('express');
const multer = require('multer');
const { bucket, bucketName } = require('../config/storage');

const router = Router();

// =========================================================================
// Middleware do Multer (armazenamento temporário em memória)
// =========================================================================
const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 5 * 1024 * 1024 }, // Limite de 5MB por imagem
  fileFilter: (req, file, cb) => {
    if (!file.mimetype.startsWith('image/')) {
      return cb(new Error('Apenas arquivos de imagem são permitidos.'));
    }
    cb(null, true);
  },
});

// =========================================================================
// POST /upload - Envia a imagem para o Google Cloud Storage (GCS)
// =========================================================================
router.post('/', upload.single('imagem'), async (req, res) => {
  if (!req.file) {
    return res.status(400).json({ mensagem: 'Nenhum arquivo enviado no campo "imagem".' });
  }

  const file = req.file;
  // Nome único com timestamp para evitar sobrescrita de objetos no bucket
  const fileName = `${Date.now()}_${file.originalname.replace(/\s+/g, '_')}`;
  const gcsFile = bucket.file(fileName);

  try {
    // Salva o buffer diretamente no bucket GCS
    await gcsFile.save(file.buffer, {
      contentType: file.mimetype,
      resumable: false,
      metadata: {
        cacheControl: 'public, max-age=31536000',
      },
    });

    // Formato padrão de URL pública para objetos acessíveis no Google Cloud Storage
    const publicUrl = `https://storage.googleapis.com/${bucketName}/${fileName}`;

    return res.status(200).json({
      mensagem: 'Upload realizado com sucesso no Google Cloud Storage!',
      url: publicUrl,
      key: fileName,
    });
  } catch (error) {
    console.error('[ERRO GCS - upload]:', error);
    return res.status(500).json({
      mensagem: 'Erro ao fazer upload da imagem para o Google Cloud Storage',
      erro: error.message,
    });
  }
});

module.exports = router;
