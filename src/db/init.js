require('dotenv').config();
const fs = require('fs');
const path = require('path');
const mysql = require('mysql2/promise');

async function runMigration() {
  console.log('[MIGRATION] Iniciando migração do banco de dados...');

  const schemaPath = path.join(__dirname, 'schema.sql');
  if (!fs.existsSync(schemaPath)) {
    console.error(`[ERRO] Arquivo schema.sql não encontrado em: ${schemaPath}`);
    process.exit(1);
  }

  const sql = fs.readFileSync(schemaPath, 'utf8');

  const connection = await mysql.createConnection({
    host: process.env.DB_HOST || 'localhost',
    user: process.env.DB_USER || 'admin',
    password: process.env.DB_PASSWORD || 'senha_banco',
    port: Number(process.env.DB_PORT) || 3306,
    multipleStatements: true,
  });

  try {
    console.log(`[MIGRATION] Conectado ao MySQL em ${process.env.DB_HOST || 'localhost'}. Aplicando schema.sql...`);
    await connection.query(sql);
    console.log('[MIGRATION] Migração concluída com sucesso! Tabelas verificadas/criadas.');
  } catch (error) {
    console.error('[ERRO MIGRATION]:', error.message);
    process.exit(1);
  } finally {
    await connection.end();
  }
}

runMigration();
