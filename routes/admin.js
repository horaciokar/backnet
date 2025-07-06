const express = require('express');
const { body } = require('express-validator');
const AdminController = require('../controllers/adminController');
const { requireAdmin } = require('../middleware/auth');

const router = express.Router();

// Aplicar middleware de admin
router.use(requireAdmin);

// Validaciones
const userValidation = [
  body('email')
    .isEmail()
    .normalizeEmail()
    .withMessage('Email inválido'),
  body('password')
    .isLength({ min: 6 })
    .withMessage('La contraseña debe tener al menos 6 caracteres'),
  body('first_name')
    .isLength({ min: 2, max: 50 })
    .withMessage('El nombre debe tener entre 2 y 50 caracteres'),
  body('last_name')
    .isLength({ min: 2, max: 50 })
    .withMessage('El apellido debe tener entre 2 y 50 caracteres'),
  body('role')
    .isIn(['admin', 'instructor', 'student'])
    .withMessage('Rol inválido')
];

const enrollmentCodeValidation = [
  body('course_id')
    .isInt()
    .withMessage('Curso inválido'),
  body('code')
    .isLength({ min: 6, max: 20 })
    .withMessage('El código debe tener entre 6 y 20 caracteres')
    .isAlphanumeric()
    .withMessage('El código solo debe contener letras y números'),
  body('max_uses')
    .isInt({ min: 1, max: 1000 })
    .withMessage('El máximo de usos debe ser entre 1 y 1000')
];

// Rutas principales
router.get('/dashboard', AdminController.dashboard);
router.get('/users', AdminController.users);
router.get('/courses', AdminController.courses);
router.get('/enrollment-codes', AdminController.enrollmentCodes);
router.get('/reports', AdminController.reports);

// Acciones
router.post('/users', userValidation, AdminController.createUser);
router.post('/users/:userId/toggle-status', AdminController.toggleUserStatus);
router.post('/enrollment-codes', enrollmentCodeValidation, AdminController.createEnrollmentCode);

module.exports = router;
