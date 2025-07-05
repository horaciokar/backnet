const express = require('express');
const { validateInstructorPermission } = require('../middleware/security');

const router = express.Router();

router.use(validateInstructorPermission);

router.get('/dashboard', (req, res) => {
  res.render('instructor/dashboard', {
    title: 'Panel de Instructor',
    user: req.user
  });
});

module.exports = router;
