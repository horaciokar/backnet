#!/bin/bash

# Script de actualización BackNet - Versión corregida
# Dividido en partes para evitar errores de EOF

set -e

PROJECT_DIR="$HOME/projects/backnet"
BACKUP_DIR="$PROJECT_DIR/backup_$(date +%Y%m%d_%H%M%S)"

echo "🚀 Iniciando actualización de BackNet..."

# Verificar directorio
if [ ! -d "$PROJECT_DIR" ]; then
    echo "❌ Error: El directorio $PROJECT_DIR no existe"
    exit 1
fi

# Crear backup
echo "💾 Creando backup..."
mkdir -p "$BACKUP_DIR"
cp -r "$PROJECT_DIR"/* "$BACKUP_DIR/" 2>/dev/null || true

cd "$PROJECT_DIR"

# Función para crear controladores
create_controllers() {
    echo "📊 Creando controladores..."
    
    # DashboardController
    cat > controllers/dashboardController.js << 'DASH_EOF'
const { Enrollment } = require('../models/Enrollment');
const Course = require('../models/Course');
const { ExamAttempt } = require('../models/Exam');
const User = require('../models/User');
const { Op } = require('sequelize');

class DashboardController {
  static async index(req, res) {
    try {
      const user = req.user;
      
      switch(user.role) {
        case 'admin':
          return res.redirect('/admin/dashboard');
        case 'instructor':
          return DashboardController.instructorDashboard(req, res);
        case 'student':
          return DashboardController.studentDashboard(req, res);
        default:
          return res.redirect('/auth/login');
      }
    } catch (error) {
      console.error('Error en dashboard:', error);
      res.status(500).render('error', {
        title: 'Error',
        error: 'Error al cargar el dashboard',
        code: 500
      });
    }
  }
  
  static async studentDashboard(req, res) {
    try {
      const user = req.user;
      
      const enrollments = await Enrollment.findAll({
        where: { user_id: user.id, is_active: true },
        include: [{
          model: Course,
          as: 'course',
          where: { is_active: true }
        }],
        order: [['enrolled_at', 'DESC']]
      });
      
      const examAttempts = await ExamAttempt.findAll({
        where: { user_id: user.id },
        order: [['created_at', 'DESC']],
        limit: 5
      });
      
      const totalCourses = enrollments.length;
      const completedCourses = enrollments.filter(e => e.progress >= 100).length;
      const totalExams = examAttempts.length;
      const passedExams = examAttempts.filter(e => e.passed).length;
      
      const avgProgress = enrollments.length > 0 
        ? Math.round(enrollments.reduce((sum, e) => sum + e.progress, 0) / enrollments.length)
        : 0;
      
      res.render('dashboard/student', {
        title: 'Dashboard Estudiante',
        user,
        enrollments,
        examAttempts,
        stats: {
          totalCourses,
          completedCourses,
          totalExams,
          passedExams,
          avgProgress
        }
      });
      
    } catch (error) {
      console.error('Error en dashboard estudiante:', error);
      res.status(500).render('error', {
        title: 'Error',
        error: 'Error al cargar el dashboard',
        code: 500
      });
    }
  }
  
  static async instructorDashboard(req, res) {
    try {
      const user = req.user;
      
      const courses = await Course.findAll({
        where: { 
          created_by: user.id,
          is_active: true 
        },
        order: [['created_at', 'DESC']]
      });
      
      const courseIds = courses.map(c => c.id);
      const totalStudents = await Enrollment.count({
        where: { 
          course_id: { [Op.in]: courseIds },
          is_active: true 
        }
      });
      
      const recentExamAttempts = await ExamAttempt.findAll({
        where: {
          completed_at: { [Op.not]: null },
          created_at: { [Op.gte]: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000) }
        },
        order: [['created_at', 'DESC']],
        limit: 10
      });
      
      res.render('dashboard/instructor', {
        title: 'Dashboard Instructor',
        user,
        courses,
        recentExamAttempts,
        stats: {
          totalCourses: courses.length,
          totalStudents,
          recentExams: recentExamAttempts.length
        }
      });
      
    } catch (error) {
      console.error('Error en dashboard instructor:', error);
      res.status(500).render('error', {
        title: 'Error',
        error: 'Error al cargar el dashboard',
        code: 500
      });
    }
  }
  
  static async progressDetail(req, res) {
    try {
      const user = req.user;
      
      if (user.role !== 'student') {
        return res.status(403).render('error', {
          title: 'Acceso denegado',
          error: 'Solo estudiantes pueden ver progreso detallado',
          code: 403
        });
      }
      
      const enrollments = await Enrollment.findAll({
        where: { user_id: user.id, is_active: true },
        include: [{
          model: Course,
          as: 'course'
        }],
        order: [['enrolled_at', 'DESC']]
      });
      
      const examAttempts = await ExamAttempt.findAll({
        where: { user_id: user.id },
        order: [['created_at', 'DESC']]
      });
      
      res.render('dashboard/progress', {
        title: 'Progreso Detallado',
        user,
        enrollments,
        examAttempts
      });
      
    } catch (error) {
      console.error('Error en progreso detallado:', error);
      res.status(500).render('error', {
        title: 'Error',
        error: 'Error al cargar el progreso',
        code: 500
      });
    }
  }
}

module.exports = DashboardController;
DASH_EOF

    # AdminController
    cat > controllers/adminController.js << 'ADMIN_EOF'
const { validationResult } = require('express-validator');
const User = require('../models/User');
const Course = require('../models/Course');
const { Enrollment, EnrollmentCode } = require('../models/Enrollment');
const { ExamAttempt } = require('../models/Exam');
const { Op } = require('sequelize');

class AdminController {
  static async dashboard(req, res) {
    try {
      const totalUsers = await User.count({ where: { is_active: true } });
      const totalCourses = await Course.count({ where: { is_active: true } });
      const totalEnrollments = await Enrollment.count({ where: { is_active: true } });
      const totalExamAttempts = await ExamAttempt.count();
      
      const recentUsers = await User.findAll({
        where: { is_active: true },
        order: [['created_at', 'DESC']],
        limit: 5
      });
      
      const recentEnrollments = await Enrollment.findAll({
        include: [
          { model: User, as: 'student', attributes: ['first_name', 'last_name'] },
          { model: Course, as: 'course', attributes: ['title'] }
        ],
        order: [['enrolled_at', 'DESC']],
        limit: 5
      });
      
      res.render('admin/dashboard', {
        title: 'Panel de Administración',
        user: req.user,
        stats: {
          totalUsers,
          totalCourses,
          totalEnrollments,
          totalExamAttempts
        },
        recentUsers,
        recentEnrollments
      });
      
    } catch (error) {
      console.error('Error en dashboard admin:', error);
      res.status(500).render('error', {
        title: 'Error',
        error: 'Error al cargar el panel',
        code: 500
      });
    }
  }
  
  static async users(req, res) {
    try {
      const { search, role, page = 1 } = req.query;
      const limit = 20;
      const offset = (page - 1) * limit;
      
      let whereClause = { is_active: true };
      
      if (search) {
        whereClause[Op.or] = [
          { first_name: { [Op.like]: `%${search}%` } },
          { last_name: { [Op.like]: `%${search}%` } },
          { email: { [Op.like]: `%${search}%` } }
        ];
      }
      
      if (role && ['admin', 'instructor', 'student'].includes(role)) {
        whereClause.role = role;
      }
      
      const { count, rows: users } = await User.findAndCountAll({
        where: whereClause,
        order: [['created_at', 'DESC']],
        limit,
        offset
      });
      
      const totalPages = Math.ceil(count / limit);
      
      res.render('admin/users', {
        title: 'Gestión de Usuarios',
        user: req.user,
        users,
        pagination: {
          currentPage: parseInt(page),
          totalPages,
          hasNext: page < totalPages,
          hasPrev: page > 1
        },
        filters: { search, role }
      });
      
    } catch (error) {
      console.error('Error en gestión de usuarios:', error);
      res.status(500).render('error', {
        title: 'Error',
        error: 'Error al cargar usuarios',
        code: 500
      });
    }
  }
  
  static async toggleUserStatus(req, res) {
    try {
      const { userId } = req.params;
      const user = await User.findByPk(userId);
      
      if (!user) {
        return res.status(404).json({ success: false, message: 'Usuario no encontrado' });
      }
      
      await user.update({ is_active: !user.is_active });
      
      res.json({ 
        success: true, 
        message: `Usuario ${user.is_active ? 'activado' : 'desactivado'} exitosamente`,
        is_active: user.is_active
      });
      
    } catch (error) {
      console.error('Error al cambiar estado:', error);
      res.status(500).json({ success: false, message: 'Error del servidor' });
    }
  }
}

module.exports = AdminController;
ADMIN_EOF

    echo "✅ Controladores creados"
}

# Función para crear middleware de seguridad
create_security_middleware() {
    echo "🔒 Creando middleware de seguridad..."
    
    cat > middleware/security.js << 'SEC_EOF'
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
SEC_EOF

    echo "✅ Middleware de seguridad creado"
}

# Función para crear rutas
create_routes() {
    echo "📋 Creando rutas..."
    
    # Dashboard routes
    cat > routes/dashboard.js << 'DASH_ROUTE_EOF'
const express = require('express');
const DashboardController = require('../controllers/dashboardController');

const router = express.Router();

router.get('/', DashboardController.index);
router.get('/progress', DashboardController.progressDetail);

module.exports = router;
DASH_ROUTE_EOF

    # Admin routes
    cat > routes/admin.js << 'ADMIN_ROUTE_EOF'
const express = require('express');
const AdminController = require('../controllers/adminController');
const { requireAdmin } = require('../middleware/auth');

const router = express.Router();

router.use(requireAdmin);

router.get('/dashboard', AdminController.dashboard);
router.get('/users', AdminController.users);
router.post('/users/:userId/toggle-status', AdminController.toggleUserStatus);

module.exports = router;
ADMIN_ROUTE_EOF

    # Instructor routes
    cat > routes/instructor.js << 'INST_ROUTE_EOF'
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
INST_ROUTE_EOF

    echo "✅ Rutas creadas"
}

# Función para crear vistas
create_views() {
    echo "🎨 Creando vistas..."
    
    # Dashboard estudiante mejorado
    mkdir -p views/dashboard
    cat > views/dashboard/student.ejs << 'STUDENT_VIEW_EOF'
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><%= title %></title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css" rel="stylesheet">
    <link href="/css/style.css" rel="stylesheet">
    <style>
        .stats-card {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            border-radius: 15px;
            padding: 20px;
            margin-bottom: 20px;
        }
        .progress-ring {
            width: 100px;
            height: 100px;
        }
        .progress-ring-circle {
            stroke: #fff;
            stroke-width: 4;
            fill: transparent;
            stroke-dasharray: 314;
            stroke-dashoffset: 314;
            transform: rotate(-90deg);
            transform-origin: 50% 50%;
            transition: stroke-dashoffset 0.5s ease-in-out;
        }
    </style>
</head>
<body>
    <%- include('../partials/navbar') %>
    
    <div class="container mt-4">
        <div class="row">
            <div class="col-12">
                <h1>¡Bienvenido, <%= user.first_name %>!</h1>
                <p class="lead">Dashboard del estudiante</p>
            </div>
        </div>
        
        <div class="row">
            <div class="col-md-3">
                <div class="stats-card text-center">
                    <i class="fas fa-book fa-3x mb-3"></i>
                    <h3><%= stats.totalCourses %></h3>
                    <p>Cursos Matriculados</p>
                </div>
            </div>
            <div class="col-md-3">
                <div class="stats-card text-center">
                    <i class="fas fa-graduation-cap fa-3x mb-3"></i>
                    <h3><%= stats.completedCourses %></h3>
                    <p>Cursos Completados</p>
                </div>
            </div>
            <div class="col-md-3">
                <div class="stats-card text-center">
                    <i class="fas fa-clipboard-check fa-3x mb-3"></i>
                    <h3><%= stats.totalExams %></h3>
                    <p>Exámenes Realizados</p>
                </div>
            </div>
            <div class="col-md-3">
                <div class="stats-card text-center">
                    <i class="fas fa-trophy fa-3x mb-3"></i>
                    <h3><%= stats.passedExams %></h3>
                    <p>Exámenes Aprobados</p>
                </div>
            </div>
        </div>
        
        <div class="row mt-4">
            <div class="col-md-8">
                <div class="card">
                    <div class="card-header">
                        <h5><i class="fas fa-chart-line"></i> Mis Cursos</h5>
                    </div>
                    <div class="card-body">
                        <% if (enrollments.length > 0) { %>
                            <% enrollments.forEach(enrollment => { %>
                                <div class="d-flex justify-content-between align-items-center mb-3 p-3 border rounded">
                                    <div>
                                        <h6 class="mb-1"><%= enrollment.course.title %></h6>
                                        <small class="text-muted">
                                            Matriculado: <%= new Date(enrollment.enrolled_at).toLocaleDateString() %>
                                        </small>
                                    </div>
                                    <div class="text-end">
                                        <div class="progress mb-2" style="width: 150px;">
                                            <div class="progress-bar" role="progressbar" 
                                                 style="width: <%= enrollment.progress %>%"
                                                 aria-valuenow="<%= enrollment.progress %>" 
                                                 aria-valuemin="0" 
                                                 aria-valuemax="100">
                                                <%= enrollment.progress %>%
                                            </div>
                                        </div>
                                        <a href="/courses/<%= enrollment.course.id %>" class="btn btn-sm btn-primary">
                                            <i class="fas fa-arrow-right"></i> Continuar
                                        </a>
                                    </div>
                                </div>
                            <% }); %>
                        <% } else { %>
                            <div class="text-center py-5">
                                <i class="fas fa-book-open fa-3x text-muted mb-3"></i>
                                <h5>No tienes cursos matriculados</h5>
                                <p class="text-muted">¡Explora nuestros cursos y comienza tu aprendizaje!</p>
                                <a href="/courses" class="btn btn-primary">
                                    <i class="fas fa-search"></i> Explorar Cursos
                                </a>
                            </div>
                        <% } %>
                    </div>
                </div>
            </div>
            
            <div class="col-md-4">
                <div class="card">
                    <div class="card-header">
                        <h5><i class="fas fa-chart-pie"></i> Progreso General</h5>
                    </div>
                    <div class="card-body text-center">
                        <div class="mb-4 position-relative">
                            <svg class="progress-ring" width="120" height="120">
                                <circle class="progress-ring-circle" 
                                        stroke="#007bff" 
                                        stroke-width="8" 
                                        fill="transparent" 
                                        r="50" 
                                        cx="60" 
                                        cy="60"
                                        style="stroke-dashoffset: <%= 314 - (314 * stats.avgProgress / 100) %>"/>
                            </svg>
                            <div class="position-absolute top-50 start-50 translate-middle">
                                <h3 class="mb-0"><%= stats.avgProgress %>%</h3>
                                <small class="text-muted">Promedio</small>
                            </div>
                        </div>
                        
                        <div class="d-grid gap-2">
                            <a href="/dashboard/progress" class="btn btn-outline-primary">
                                <i class="fas fa-chart-bar"></i> Ver Progreso Detallado
                            </a>
                            <a href="/exams/history" class="btn btn-outline-secondary">
                                <i class="fas fa-history"></i> Historial de Exámenes
                            </a>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
    
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/js/bootstrap.bundle.min.js"></script>
    <script src="/js/main.js"></script>
</body>
</html>
STUDENT_VIEW_EOF

    # Admin dashboard
    mkdir -p views/admin
    cat > views/admin/dashboard.ejs << 'ADMIN_VIEW_EOF'
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><%= title %></title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css" rel="stylesheet">
    <link href="/css/style.css" rel="stylesheet">
</head>
<body>
    <%- include('../partials/navbar') %>
    
    <div class="container-fluid mt-4">
        <div class="row">
            <div class="col-12">
                <h1><i class="fas fa-tachometer-alt"></i> Panel de Administración</h1>
                <p class="lead">Gestiona toda la plataforma educativa</p>
            </div>
        </div>
        
        <div class="row mb-4">
            <div class="col-md-3">
                <div class="card bg-primary text-white">
                    <div class="card-body text-center">
                        <i class="fas fa-users fa-3x mb-3"></i>
                        <h2><%= stats.totalUsers %></h2>
                        <p class="mb-0">Usuarios Activos</p>
                    </div>
                </div>
            </div>
            <div class="col-md-3">
                <div class="card bg-success text-white">
                    <div class="card-body text-center">
                        <i class="fas fa-book fa-3x mb-3"></i>
                        <h2><%= stats.totalCourses %></h2>
                        <p class="mb-0">Cursos Disponibles</p>
                    </div>
                </div>
            </div>
            <div class="col-md-3">
                <div class="card bg-warning text-white">
                    <div class="card-body text-center">
                        <i class="fas fa-user-graduate fa-3x mb-3"></i>
                        <h2><%= stats.totalEnrollments %></h2>
                        <p class="mb-0">Matrículas Activas</p>
                    </div>
                </div>
            </div>
            <div class="col-md-3">
                <div class="card bg-info text-white">
                    <div class="card-body text-center">
                        <i class="fas fa-clipboard-check fa-3x mb-3"></i>
                        <h2><%= stats.totalExamAttempts %></h2>
                        <p class="mb-0">Exámenes Realizados</p>
                    </div>
                </div>
            </div>
        </div>
        
        <div class="row">
            <div class="col-md-4">
                <div class="card">
                    <div class="card-body">
                        <h5 class="card-title">
                            <i class="fas fa-users text-primary"></i> Gestión de Usuarios
                        </h5>
                        <p class="card-text">Administra usuarios, roles y permisos</p>
                        <a href="/admin/users" class="btn btn-primary">
                            <i class="fas fa-user-cog"></i> Gestionar Usuarios
                        </a>
                    </div>
                </div>
            </div>
            
            <div class="col-md-4">
                <div class="card">
                    <div class="card-body">
                        <h5 class="card-title">
                            <i class="fas fa-book text-success"></i> Gestión de Cursos
                        </h5>
                        <p class="card-text">Supervisa y administra todos los cursos</p>
                        <a href="/admin/courses" class="btn btn-success">
                            <i class="fas fa-plus-circle"></i> Gestionar Cursos
                        </a>
                    </div>
                </div>
            </div>
            
            <div class="col-md-4">
                <div class="card">
                    <div class="card-body">
                        <h5 class="card-title">
                            <i class="fas fa-chart-bar text-warning"></i> Reportes
                        </h5>
                        <p class="card-text">Estadísticas y reportes generales</p>
                        <a href="/admin/reports" class="btn btn-warning">
                            <i class="fas fa-chart-line"></i> Ver Reportes
                        </a>
                    </div>
                </div>
            </div>
        </div>
    </div>
    
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/js/bootstrap.bundle.min.js"></script>
    <script src="/js/main.js"></script>
</body>
</html>
ADMIN_VIEW_EOF

    echo "✅ Vistas principales creadas"
}

# Función para actualizar server.js
update_server() {
    echo "🔧 Actualizando server.js..."
    
    # Crear backup del server actual
    cp server.js server.js.backup
    
    # Actualizar server.js
    cat > server.js << 'SERVER_EOF'
const express = require('express');
const path = require('path');
const session = require('express-session');
const helmet = require('helmet');
const compression = require('compression');
const morgan = require('morgan');
const rateLimit = require('express-rate-limit');
require('dotenv').config();

// Importar rutas
const authRoutes = require('./routes/auth');
const dashboardRoutes = require('./routes/dashboard');
const courseRoutes = require('./routes/courses');
const examRoutes = require('./routes/exams');
const forumRoutes = require('./routes/forum');
const adminRoutes = require('./routes/admin');
const instructorRoutes = require('./routes/instructor');

// Importar middleware
const { authenticateToken } = require('./middleware/auth');
const { setupAssociations } = require('./models/associations');
const { securityLogger, loginRateLimit } = require('./middleware/security');

const app = express();
const PORT = process.env.PORT || 3000;

console.log(`🌍 Entorno: ${process.env.NODE_ENV || 'development'}`);

// Rate limiting
if (process.env.NODE_ENV === 'production') {
    const limiter = rateLimit({
        windowMs: 15 * 60 * 1000,
        max: 100,
        message: 'Demasiadas solicitudes, intenta de nuevo más tarde.'
    });
    app.use(limiter);
}

// Middleware de seguridad
if (process.env.NODE_ENV === 'production') {
    app.use(helmet({
        contentSecurityPolicy: {
            directives: {
                defaultSrc: ["'self'"],
                styleSrc: ["'self'", "'unsafe-inline'", "https://cdn.jsdelivr.net", "https://cdnjs.cloudflare.com"],
                scriptSrc: ["'self'", "https://cdn.jsdelivr.net", "https://cdnjs.cloudflare.com"],
                imgSrc: ["'self'", "data:", "https:"],
                frameSrc: ["https://www.youtube.com", "https://youtube.com"],
                fontSrc: ["'self'", "https://cdnjs.cloudflare.com"]
            }
        }
    }));
} else {
    app.use(helmet({
        contentSecurityPolicy: false,
        crossOriginEmbedderPolicy: false
    }));
}

app.use(compression());
app.use(morgan(process.env.NODE_ENV === 'production' ? 'combined' : 'dev'));

// Configurar EJS
app.set('view engine', 'ejs');
app.set('views', path.join(__dirname, 'views'));

// Middleware para parsear requests
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Archivos estáticos
app.use(express.static(path.join(__dirname, 'public')));
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// Configurar sesiones
app.use(session({
    secret: process.env.SESSION_SECRET || 'tu-clave-secreta-muy-segura',
    resave: false,
    saveUninitialized: false,
    cookie: {
        secure: process.env.NODE_ENV === 'production',
        httpOnly: true,
        maxAge: 24 * 60 * 60 * 1000
    }
}));

// Middleware global para variables de vista
app.use((req, res, next) => {
    res.locals.user = req.session.user || null;
    res.locals.message = req.session.message || null;
    res.locals.error = req.session.error || null;
    
    delete req.session.message;
    delete req.session.error;
    
    next();
});

// Logging de seguridad
app.use(securityLogger);

// Rutas
app.use('/auth', loginRateLimit, authRoutes);
app.use('/dashboard', authenticateToken, dashboardRoutes);
app.use('/courses', authenticateToken, courseRoutes);
app.use('/exams', authenticateToken, examRoutes);
app.use('/forum', authenticateToken, forumRoutes);
app.use('/admin', authenticateToken, adminRoutes);
app.use('/instructor', authenticateToken, instructorRoutes);

// Ruta principal
app.get('/', (req, res) => {
    if (req.session.user) {
        return res.redirect('/dashboard');
    }
    res.render('index', { title: 'Plataforma Educativa' });
});

// Manejo de errores 404
app.use((req, res) => {
    res.status(404).render('error', { 
        title: 'Página no encontrada',
        error: 'La página que buscas no existe.',
        code: 404
    });
});

// Manejo de errores general
app.use((err, req, res, next) => {
    console.error('Error capturado:', err);
    res.status(500).render('error', { 
        title: 'Error del servidor',
        error: process.env.NODE_ENV === 'development' ? err.message : 'Algo salió mal en el servidor.',
        code: 500
    });
});

// Configurar asociaciones de modelos
setupAssociations();

// Iniciar servidor
app.listen(PORT, '0.0.0.0', () => {
    console.log(`🚀 Servidor corriendo en puerto ${PORT}`);
    console.log(`🌐 Aplicación disponible en: http://0.0.0.0:${PORT}`);
});

module.exports = app;
SERVER_EOF

    echo "✅ Server.js actualizado"
}

# Ejecutar todas las funciones
main() {
    echo "🚀 Iniciando actualización completa..."
    
    create_controllers
    create_security_middleware
    create_routes
    create_views
    update_server
    
    echo ""
    echo "✅ ¡Actualización completa de BackNet terminada!"
    echo ""
    echo "🎯 Funcionalidades implementadas:"
    echo "   - Dashboard avanzado con estadísticas"
    echo "   - Panel de administración"
    echo "   - Middleware de seguridad"
    echo "   - Nuevas rutas y vistas"
    echo ""
    echo "�� Para terminar:"
    echo "   1. Reinicia el servidor: npm run dev"
    echo "   2. Visita: http://localhost:3000"
    echo ""
    echo "📱 Nuevas rutas disponibles:"
    echo "   - /dashboard/progress"
    echo "   - /admin/dashboard"
    echo "   - /admin/users"
    echo "   - /instructor/dashboard"
}

# Ejecutar función principal
main
