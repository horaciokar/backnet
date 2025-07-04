const express = require('express');
const router = express.Router();

// Rutas temporales - implementar controllers después
router.get('/', (req, res) => {
  res.render('courses/index', {
    title: 'Cursos',
    courses: []
  });
});

router.get('/:id', (req, res) => {
  res.render('courses/show', {
    title: 'Detalle del Curso',
    course: { id: req.params.id, title: 'Curso de Ejemplo' }
  });
});

module.exports = router;
