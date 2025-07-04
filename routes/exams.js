const express = require('express');
const router = express.Router();

// Rutas temporales
router.get('/', (req, res) => {
  res.render('exams/index', {
    title: 'Exámenes',
    exams: []
  });
});

module.exports = router;
