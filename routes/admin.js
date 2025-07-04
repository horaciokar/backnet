const express = require('express');
const { requireAdmin } = require('../middleware/auth');
const router = express.Router();

// Aplicar middleware de admin a todas las rutas
router.use(requireAdmin);

// Dashboard admin
router.get('/dashboard', (req, res) => {
  res.render('admin/dashboard', {
    title: 'Panel de Administración',
    stats: {}
  });
});

module.exports = router;
