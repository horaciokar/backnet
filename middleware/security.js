const rateLimit = require('express-rate-limit');

const examRateLimit = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 5,
  message: 'Demasiados intentos de examen. Intenta de nuevo más tarde.',
  keyGenerator: (req) => {
    return req.user?.id || req.ip;
  }
});

const loginRateLimit = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 5,
  message: 'Demasiados intentos de login. Intenta de nuevo más tarde.'
});

const validateExamAttempt = async (req, res, next) => {
  try {
    const { examId, attemptId } = req.params;
    const user = req.user;
    
    if (!examId || !attemptId) {
      return res.status(400).json({ 
        success: false, 
        message: 'Parámetros inválidos' 
      });
    }
    
    const { ExamAttempt } = require('../models/Exam');
    const attempt = await ExamAttempt.findByPk(attemptId);
    
    if (!attempt) {
      return res.status(404).json({ 
        success: false, 
        message: 'Intento de examen no encontrado' 
      });
    }
    
    if (attempt.user_id !== user.id) {
      return res.status(403).json({ 
        success: false, 
        message: 'No tienes permisos para acceder a este examen' 
      });
    }
    
    if (attempt.exam_id !== parseInt(examId)) {
      return res.status(400).json({ 
        success: false, 
        message: 'Examen no válido' 
      });
    }
    
    req.examAttempt = attempt;
    next();
    
  } catch (error) {
    console.error('Error en validación de examen:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Error del servidor' 
    });
  }
};

const securityLogger = (req, res, next) => {
  const user = req.user;
  const action = req.method + ' ' + req.originalUrl;
  
  console.log(`[SECURITY] ${new Date().toISOString()} - User: ${user?.id || 'anonymous'} - Action: ${action} - IP: ${req.ip}`);
  
  next();
};

const validateInstructorPermission = async (req, res, next) => {
  try {
    const user = req.user;
    
    if (user.role !== 'instructor' && user.role !== 'admin') {
      return res.status(403).render('error', {
        title: 'Acceso denegado',
        error: 'Solo instructores pueden acceder a esta sección',
        code: 403
      });
    }
    
    next();
    
  } catch (error) {
    console.error('Error en validación de instructor:', error);
    res.status(500).render('error', {
      title: 'Error',
      error: 'Error de validación',
      code: 500
    });
  }
};

module.exports = {
  examRateLimit,
  loginRateLimit,
  validateExamAttempt,
  securityLogger,
  validateInstructorPermission
};
