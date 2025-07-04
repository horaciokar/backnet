const jwt = require('jsonwebtoken');
const User = require('../models/User');

// Middleware para verificar autenticación con sesiones
const authenticateToken = async (req, res, next) => {
  try {
    // Verificar si hay sesión activa
    if (!req.session || !req.session.user) {
      return res.redirect('/auth/login');
    }
    
    // Verificar que el usuario aún exista y esté activo
    const user = await User.findByPk(req.session.user.id);
    if (!user || !user.is_active) {
      req.session.destroy();
      return res.redirect('/auth/login');
    }
    
    // Agregar usuario a request
    req.user = user;
    next();
    
  } catch (error) {
    console.error('Error en autenticación:', error);
    req.session.destroy();
    res.redirect('/auth/login');
  }
};

// Middleware para verificar roles específicos
const requireRole = (roles) => {
  return (req, res, next) => {
    if (!req.user) {
      return res.redirect('/auth/login');
    }
    
    // Convertir string a array si es necesario
    const allowedRoles = Array.isArray(roles) ? roles : [roles];
    
    if (!allowedRoles.includes(req.user.role)) {
      return res.status(403).render('error', {
        title: 'Acceso denegado',
        error: 'No tienes permisos para acceder a esta sección.',
        code: 403
      });
    }
    
    next();
  };
};

// Middleware para verificar si es admin
const requireAdmin = requireRole('admin');

// Middleware para verificar si NO está autenticado
const requireGuest = (req, res, next) => {
  if (req.session && req.session.user) {
    return res.redirect('/dashboard');
  }
  next();
};

module.exports = {
  authenticateToken,
  requireRole,
  requireAdmin,
  requireGuest
};
