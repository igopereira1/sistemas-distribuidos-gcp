const pool = require('../config/db');

// =========================================================================
// Controller: Operações de CRUD para a tabela `usuarios`
// =========================================================================

async function listar(req, res) {
  try {
    const [rows] = await pool.query(
      'SELECT id, nome, email, foto_url, criado_em FROM usuarios ORDER BY id DESC'
    );
    res.json(rows);
  } catch (error) {
    console.error('[ERRO DB - listar]:', error);
    res.status(500).json({ mensagem: 'Erro interno no servidor', erro: error.message });
  }
}

async function buscarPorId(req, res) {
  try {
    const { id } = req.params;
    const [rows] = await pool.query('SELECT * FROM usuarios WHERE id = ?', [id]);

    if (rows.length === 0) {
      return res.status(404).json({ mensagem: 'Usuário não encontrado' });
    }

    res.json(rows[0]);
  } catch (error) {
    console.error('[ERRO DB - buscarPorId]:', error);
    res.status(500).json({ mensagem: 'Erro interno no servidor', erro: error.message });
  }
}

async function criar(req, res) {
  try {
    const { nome, email, foto_url } = req.body;

    if (!nome || !email) {
      return res.status(400).json({ mensagem: 'Os campos nome e email são obrigatórios' });
    }

    const [result] = await pool.query(
      'INSERT INTO usuarios (nome, email, foto_url) VALUES (?, ?, ?)',
      [nome, email, foto_url || null]
    );

    res.status(201).json({ id: result.insertId, nome, email, foto_url: foto_url || null });
  } catch (error) {
    console.error('[ERRO DB - criar]:', error);

    // Trata violação de restrição UNIQUE no MySQL
    if (error.code === 'ER_DUP_ENTRY') {
      return res.status(409).json({ mensagem: 'Já existe um usuário com este e-mail' });
    }

    res.status(500).json({ mensagem: 'Erro interno no servidor', erro: error.message });
  }
}

async function atualizar(req, res) {
  try {
    const { id } = req.params;
    const { nome, email, foto_url } = req.body;

    const [result] = await pool.query(
      'UPDATE usuarios SET nome = COALESCE(?, nome), email = COALESCE(?, email), foto_url = COALESCE(?, foto_url) WHERE id = ?',
      [nome, email, foto_url, id]
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({ mensagem: 'Usuário não encontrado' });
    }

    res.json({ mensagem: 'Usuário atualizado com sucesso' });
  } catch (error) {
    console.error('[ERRO DB - atualizar]:', error);
    res.status(500).json({ mensagem: 'Erro interno no servidor', erro: error.message });
  }
}

async function remover(req, res) {
  try {
    const { id } = req.params;
    const [result] = await pool.query('DELETE FROM usuarios WHERE id = ?', [id]);

    if (result.affectedRows === 0) {
      return res.status(404).json({ mensagem: 'Usuário não encontrado' });
    }

    res.status(204).send();
  } catch (error) {
    console.error('[ERRO DB - remover]:', error);
    res.status(500).json({ mensagem: 'Erro interno no servidor', erro: error.message });
  }
}

module.exports = {
  listar,
  buscarPorId,
  criar,
  atualizar,
  remover,
};
