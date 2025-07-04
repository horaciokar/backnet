const express = require('express');
const { body } = require('express-validator');
const AuthController = require('../controllers/authController');
const { requireGuest } = require('../middleware/auth');

const router = express.Router();

// Validaciones
const loginValidation = [
  body('email')
    .isEmail()
    .normalizeEmail()
    .withMessage('Email inválido'),
  body('password')
    .isLength({ min: 6 })
    .withMessage('La contraseña debe tener al menos 6 caracteres')
];

// Rutas
router.get('/login', requireGuest, AuthController.showLogin);
router.post('/login', requireGuest, loginValidation, AuthController.processLogin);
router.get('/logout', AuthController.logout);

module.exports = router;
