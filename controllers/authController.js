const { validationResult } = require('express-validator');
const User = require('../models/User');

class AuthController {
  
  // Mostrar formulario de login
  static async showLogin(req, res) {
    try {
      res.render('auth/login', {
        title: 'Iniciar Sesión',
        error: null,
        email: ''
      });
    } catch (error) {
      console.error('Error al mostrar login:', error);
      res.status(500).render('error', {
        title: 'Error',
        error: 'Error interno del servidor',
        code: 500
      });
    }
  }

  // Procesar login
  static async processLogin(req, res) {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).render('auth/login', {
          title: 'Iniciar Sesión',
          error: errors.array()[0].msg,
          email: req.body.email || ''
        });
      }

      const { email, password } = req.body;

      // Buscar usuario
      const user = await User.findByEmail(email.toLowerCase());
      if (!user) {
        return res.status(400).render('auth/login', {
          title: 'Iniciar Sesión',
          error: 'Credenciales inválidas',
          email: email
        });
      }

      // Verificar si está activo
      if (!user.is_active) {
        return res.status(400).render('auth/login', {
          title: 'Iniciar Sesión',
          error: 'Cuenta desactivada. Contacta al administrador.',
          email: email
        });
      }

      // Verificar contraseña
      const isValidPassword = await user.validatePassword(password);
      if (!isValidPassword) {
        return res.status(400).render('auth/login', {
          title: 'Iniciar Sesión',
          error: 'Credenciales inválidas',
          email: email
        });
      }

      // Actualizar último login
      await user.update({ last_login: new Date() });

      // Crear sesión
      req.session.user = {
        id: user.id,
        email: user.email,
        first_name: user.first_name,
        last_name: user.last_name,
        role: user.role
      };

      req.session.message = `¡Bienvenido, ${user.first_name}!`;
      res.redirect('/dashboard');

    } catch (error) {
      console.error('Error en login:', error);
      res.status(500).render('auth/login', {
        title: 'Iniciar Sesión',
        error: 'Error interno del servidor',
        email: req.body.email || ''
      });
    }
  }

  // Cerrar sesión
  static async logout(req, res) {
    try {
      req.session.destroy((err) => {
        if (err) {
          console.error('Error al cerrar sesión:', err);
          return res.redirect('/dashboard');
        }
        res.redirect('/');
      });
    } catch (error) {
      console.error('Error en logout:', error);
      res.redirect('/dashboard');
    }
  }
}

module.exports = AuthController;
