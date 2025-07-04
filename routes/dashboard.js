const express = require('express');
const router = express.Router();

// Dashboard principal
router.get('/', (req, res) => {
  const user = req.user;
  
  // Redirigir según rol
  switch(user.role) {
    case 'admin':
      return res.redirect('/admin/dashboard');
    case 'instructor':
      return res.render('dashboard/instructor', {
        title: 'Dashboard Instructor',
        user
      });
    case 'student':
      return res.render('dashboard/student', {
        title: 'Dashboard Estudiante', 
        user
      });
    default:
      return res.redirect('/auth/login');
  }
});

module.exports = router;
