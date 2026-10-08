const { Router } = require('express');
const {
  listar,
  buscarPorId,
  criar,
  atualizar,
  remover,
} = require('../controllers/usuarios.controller');

const router = Router();

router.get('/', listar);
router.get('/:id', buscarPorId);
router.post('/', criar);
router.put('/:id', atualizar);
router.delete('/:id', remover);

module.exports = router;
