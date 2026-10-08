require('dotenv').config();
const express = require('express');
const cors = require('cors');

const usuariosRoutes = require('./routes/usuarios.routes');
const uploadRoutes = require('./routes/upload.routes');

const app = express();

// Middlewares essenciais
app.use(cors());
app.use(express.json());

// =========================================================================
// Health Checks (Essenciais para o Cloud Load Balancer e Alta Disponibilidade)
// =========================================================================
app.get('/', (req, res) => {
  res.status(200).json({ status: 'ok', mensagem: 'API funcionando!' });
});

app.get('/api/health', (req, res) => {
  res.status(200).json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
  });
});

// =========================================================================
// Rotas da Aplicação
// =========================================================================
app.use('/usuarios', usuariosRoutes);
app.use('/upload', uploadRoutes);

// Middleware de tratamento global de erros
app.use((err, req, res, next) => {
  console.error('[ERRO GLOBAL]:', err);
  res.status(err.status || 400).json({
    mensagem: err.message || 'Erro inesperado na requisicao',
  });
});

module.exports = app;
