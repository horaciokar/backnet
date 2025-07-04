const express = require('express');
const router = express.Router();

// Rutas temporales
router.get('/:courseId', (req, res) => {
  res.render('forum/index', {
    title: 'Foro',
    topics: []
  });
});

module.exports = router;
