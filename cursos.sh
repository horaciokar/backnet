#!/bin/bash

# Script para desarrollar gestión completa de cursos
echo "📚 Desarrollando gestión completa de cursos..."

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 1. ACTUALIZAR CONTROLADOR DE CURSOS COMPLETO
print_status "Creando controlador de cursos completo..."
cat > controllers/courseController.js << 'EOF'
const { validationResult } = require('express-validator');
const { Op } = require('sequelize');
const Course = require('../models/Course');
const CourseUnit = require('../models/CourseUnit');
const { Enrollment, EnrollmentCode } = require('../models/Enrollment');
const User = require('../models/User');

class CourseController {
  
  // Listar cursos disponibles para estudiantes
  static async index(req, res) {
    try {
      const { category, search } = req.query;
      const user = req.user;
      
      let whereClause = { is_active: true };
      
      // Filtro por categoría
      if (category && ['networks', 'security', 'both'].includes(category)) {
        whereClause.category = category;
      }
      
      // Filtro por búsqueda
      if (search) {
        whereClause[Op.or] = [
          { title: { [Op.like]: `%${search}%` } },
          { description: { [Op.like]: `%${search}%` } }
        ];
      }
      
      const courses = await Course.findAll({
        where: whereClause,
        include: [
          {
            model: User,
            as: 'creator',
            attributes: ['id', 'first_name', 'last_name']
          }
        ],
        order: [['created_at', 'DESC']]
      });
      
      // Obtener matrículas del usuario
      const enrollments = await Enrollment.findAll({
        where: { user_id: user.id },
        attributes: ['course_id', 'progress']
      });
      
      const enrollmentMap = enrollments.reduce((map, enrollment) => {
        map[enrollment.course_id] = enrollment.progress;
        return map;
      }, {});
      
      res.render('courses/index', {
        title: 'Cursos Disponibles',
        courses,
        enrollmentMap,
        category: category || '',
        search: search || '',
        user
      });
      
    } catch (error) {
      console.error('Error al listar cursos:', error);
      res.status(500).render('error', {
        title: 'Error',
        error: 'Error al cargar los cursos',
        code: 500
      });
    }
  }
  
  // Ver detalles de un curso
  static async show(req, res) {
    try {
      const courseId = req.params.id;
      const user = req.user;
      
      const course = await Course.findByPk(courseId, {
        include: [
          {
            model: User,
            as: 'creator',
            attributes: ['id', 'first_name', 'last_name']
          },
          {
            model: CourseUnit,
            as: 'units',
            where: { is_active: true },
            required: false,
            order: [['order_number', 'ASC']]
          }
        ]
      });
      
      if (!course || !course.is_active) {
        return res.status(404).render('error', {
          title: 'Curso no encontrado',
          error: 'El curso solicitado no existe o no está disponible',
          code: 404
        });
      }
      
      // Verificar si el usuario está matriculado
      const enrollment = await Enrollment.findOne({
        where: { user_id: user.id, course_id: courseId }
      });
      
      // Obtener estadísticas del curso
      const enrollmentCount = await Enrollment.count({
        where: { course_id: courseId }
      });
      
      const unitsCount = await CourseUnit.count({
        where: { course_id: courseId, is_active: true }
      });
      
      res.render('courses/show', {
        title: course.title,
        course,
        enrollment,
        enrollmentCount,
        unitsCount,
        isEnrolled: !!enrollment,
        user
      });
      
    } catch (error) {
      console.error('Error al mostrar curso:', error);
      res.status(500).render('error', {
        title: 'Error',
        error: 'Error al cargar el curso',
        code: 500
      });
    }
  }
  
  // Mostrar unidad específica
  static async showUnit(req, res) {
    try {
      const { courseId, unitId } = req.params;
      const user = req.user;
      
      // Verificar matrícula
      const enrollment = await Enrollment.findOne({
        where: { user_id: user.id, course_id: courseId }
      });
      
      if (!enrollment) {
        return res.status(403).render('error', {
          title: 'Acceso denegado',
          error: 'Debes estar matriculado en el curso para acceder a este contenido',
          code: 403
        });
      }
      
      const unit = await CourseUnit.findByPk(unitId, {
        include: [
          {
            model: Course,
            as: 'course',
            attributes: ['id', 'title']
          }
        ]
      });
      
      if (!unit || unit.course_id !== parseInt(courseId)) {
        return res.status(404).render('error', {
          title: 'Unidad no encontrada',
          error: 'La unidad solicitada no existe',
          code: 404
        });
      }
      
      // Obtener unidades del curso para navegación
      const allUnits = await CourseUnit.findAll({
        where: { course_id: courseId, is_active: true },
        order: [['order_number', 'ASC']]
      });
      
      // Obtener siguiente y anterior
      const currentIndex = allUnits.findIndex(u => u.id === unit.id);
      const nextUnit = allUnits[currentIndex + 1] || null;
      const previousUnit = allUnits[currentIndex - 1] || null;
      
      // Extraer ID de YouTube si es video
      let videoId = null;
      if (unit.content_type === 'video' && unit.video_url) {
        const regex = /(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/)([^"&?\/\s]{11})/;
        const match = unit.video_url.match(regex);
        videoId = match ? match[1] : null;
      }
      
      res.render('courses/unit', {
        title: `${unit.course.title} - ${unit.title}`,
        unit,
        allUnits,
        nextUnit,
        previousUnit,
        enrollment,
        videoId,
        user
      });
      
    } catch (error) {
      console.error('Error al mostrar unidad:', error);
      res.status(500).render('error', {
        title: 'Error',
        error: 'Error al cargar la unidad',
        code: 500
      });
    }
  }
  
  // Matricularse en un curso
  static async enroll(req, res) {
    try {
      const courseId = req.params.id;
      const user = req.user;
      
      // Verificar si ya está matriculado
      const existingEnrollment = await Enrollment.findOne({
        where: { user_id: user.id, course_id: courseId }
      });
      
      if (existingEnrollment) {
        req.session.error = 'Ya estás matriculado en este curso';
        return res.redirect(`/courses/${courseId}`);
      }
      
      // Verificar que el curso existe
      const course = await Course.findByPk(courseId);
      if (!course || !course.is_active) {
        return res.status(404).render('error', {
          title: 'Curso no encontrado',
          error: 'El curso solicitado no existe',
          code: 404
        });
      }
      
      // Verificar límite de estudiantes
      if (course.max_students) {
        const currentEnrollments = await Enrollment.count({
          where: { course_id: courseId }
        });
        
        if (currentEnrollments >= course.max_students) {
          req.session.error = 'El curso ha alcanzado el límite máximo de estudiantes';
          return res.redirect(`/courses/${courseId}`);
        }
      }
      
      // Crear matrícula
      await Enrollment.create({
        user_id: user.id,
        course_id: courseId
      });
      
      req.session.message = '¡Te has matriculado exitosamente en el curso!';
      res.redirect(`/courses/${courseId}`);
      
    } catch (error) {
      console.error('Error al matricularse:', error);
      req.session.error = 'Error al matricularse en el curso';
      res.redirect(`/courses/${req.params.id}`);
    }
  }
  
  // Matricularse con código
  static async enrollWithCode(req, res) {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        req.session.error = errors.array()[0].msg;
        return res.redirect('/courses');
      }
      
      const { enrollment_code } = req.body;
      const user = req.user;
      
      // Buscar código
      const code = await EnrollmentCode.findOne({
        where: { 
          code: enrollment_code.toUpperCase(),
          is_active: true
        }
      });
      
      if (!code) {
        req.session.error = 'Código de matrícula inválido';
        return res.redirect('/courses');
      }
      
      // Verificar si el código puede ser usado
      if (code.used_count >= code.max_uses) {
        req.session.error = 'Código de matrícula agotado';
        return res.redirect('/courses');
      }
      
      if (code.expires_at && new Date() > code.expires_at) {
        req.session.error = 'Código de matrícula expirado';
        return res.redirect('/courses');
      }
      
      // Verificar si ya está matriculado
      const existingEnrollment = await Enrollment.findOne({
        where: { user_id: user.id, course_id: code.course_id }
      });
      
      if (existingEnrollment) {
        req.session.error = 'Ya estás matriculado en este curso';
        return res.redirect(`/courses/${code.course_id}`);
      }
      
      // Usar código
      await code.increment('used_count');
      
      // Crear matrícula
      await Enrollment.create({
        user_id: user.id,
        course_id: code.course_id
      });
      
      req.session.message = '¡Te has matriculado exitosamente con el código!';
      res.redirect(`/courses/${code.course_id}`);
      
    } catch (error) {
      console.error('Error al matricularse con código:', error);
      req.session.error = 'Error al procesar el código de matrícula';
      res.redirect('/courses');
    }
  }
  
  // Mis cursos
  static async myCourses(req, res) {
    try {
      const user = req.user;
      
      const enrollments = await Enrollment.findAll({
        where: { user_id: user.id, is_active: true },
        include: [
          {
            model: Course,
            as: 'course',
            include: [
              {
                model: User,
                as: 'creator',
                attributes: ['id', 'first_name', 'last_name']
              }
            ]
          }
        ],
        order: [['enrolled_at', 'DESC']]
      });
      
      res.render('courses/my-courses', {
        title: 'Mis Cursos',
        enrollments,
        user
      });
      
    } catch (error) {
      console.error('Error al mostrar mis cursos:', error);
      res.status(500).render('error', {
        title: 'Error',
        error: 'Error al cargar tus cursos',
        code: 500
      });
    }
  }
}

module.exports = CourseController;
EOF

# 2. ACTUALIZAR RUTAS DE CURSOS
print_status "Actualizando rutas de cursos..."
cat > routes/courses.js << 'EOF'
const express = require('express');
const { body } = require('express-validator');
const CourseController = require('../controllers/courseController');
const { requireRole } = require('../middleware/auth');

const router = express.Router();

// Validaciones
const enrollCodeValidation = [
  body('enrollment_code')
    .isLength({ min: 6, max: 20 })
    .withMessage('El código debe tener entre 6 y 20 caracteres')
    .isAlphanumeric()
    .withMessage('El código solo puede contener letras y números')
];

// Rutas públicas para estudiantes
router.get('/', CourseController.index);
router.get('/my-courses', requireRole(['student', 'instructor', 'admin']), CourseController.myCourses);
router.get('/:id', CourseController.show);
router.get('/:courseId/unit/:unitId', CourseController.showUnit);

// Rutas de matrícula (solo estudiantes)
router.post('/:id/enroll', requireRole('student'), CourseController.enroll);
router.post('/enroll-with-code', requireRole('student'), enrollCodeValidation, CourseController.enrollWithCode);

module.exports = router;
EOF

# 3. CREAR VISTAS COMPLETAS DE CURSOS
print_status "Creando vista de lista de cursos..."
cat > views/courses/index.ejs << 'EOF'
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><%= title %></title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css" rel="stylesheet" integrity="sha384-1BmE4kWBq78iYhFldvKuhfTAU6auU8tT94WrHftjDbrCEXSU1oBoqyl2QvZ6jIW3" crossorigin="anonymous">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css" rel="stylesheet" integrity="sha512-9usAa10IRO0HhonpyAIVpjrylPvoDwiPUiKdWk5t3PyolY1cOd4DSE0Ga+ri4AuTroPR5aQvXU9xC6qOPnzFeg==" crossorigin="anonymous">
    <link href="/css/style.css" rel="stylesheet">
</head>
<body>
    <%- include('../partials/navbar') %>
    
    <div class="container mt-4">
        <% if (typeof message !== 'undefined' && message) { %>
            <div class="alert alert-success alert-dismissible fade show" role="alert">
                <%= message %>
                <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
            </div>
        <% } %>
        
        <% if (typeof error !== 'undefined' && error) { %>
            <div class="alert alert-danger alert-dismissible fade show" role="alert">
                <%= error %>
                <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
            </div>
        <% } %>
        
        <div class="row">
            <div class="col-12">
                <div class="d-flex justify-content-between align-items-center mb-4">
                    <h1><i class="fas fa-book"></i> Cursos Disponibles</h1>
                    <% if (user.role === 'student') { %>
                        <button class="btn btn-primary" data-bs-toggle="modal" data-bs-target="#enrollCodeModal">
                            <i class="fas fa-key"></i> Usar Código
                        </button>
                    <% } %>
                </div>
                
                <!-- Filtros -->
                <div class="card mb-4">
                    <div class="card-body">
                        <form method="GET" action="/courses" class="row g-3">
                            <div class="col-md-6">
                                <label for="search" class="form-label">Buscar cursos:</label>
                                <input type="text" class="form-control" id="search" name="search" value="<%= search %>" placeholder="Buscar por título o descripción...">
                            </div>
                            <div class="col-md-4">
                                <label for="category" class="form-label">Categoría:</label>
                                <select class="form-select" id="category" name="category">
                                    <option value="">Todas las categorías</option>
                                    <option value="networks" <%= category === 'networks' ? 'selected' : '' %>>Redes</option>
                                    <option value="security" <%= category === 'security' ? 'selected' : '' %>>Seguridad</option>
                                    <option value="both" <%= category === 'both' ? 'selected' : '' %>>Redes y Seguridad</option>
                                </select>
                            </div>
                            <div class="col-md-2">
                                <label class="form-label">&nbsp;</label>
                                <div class="d-grid">
                                    <button type="submit" class="btn btn-outline-primary">
                                        <i class="fas fa-search"></i> Filtrar
                                    </button>
                                </div>
                            </div>
                        </form>
                    </div>
                </div>
                
                <!-- Lista de cursos -->
                <div class="row">
                    <% if (courses.length > 0) { %>
                        <% courses.forEach(course => { %>
                            <div class="col-md-6 col-lg-4 mb-4">
                                <div class="card h-100">
                                    <% if (course.thumbnail) { %>
                                        <img src="<%= course.thumbnail %>" class="card-img-top" alt="<%= course.title %>" style="height: 200px; object-fit: cover;">
                                    <% } else { %>
                                        <div class="card-img-top bg-primary d-flex align-items-center justify-content-center" style="height: 200px;">
                                            <i class="fas fa-graduation-cap fa-3x text-white"></i>
                                        </div>
                                    <% } %>
                                    
                                    <div class="card-body d-flex flex-column">
                                        <h5 class="card-title"><%= course.title %></h5>
                                        <p class="card-text flex-grow-1"><%= course.short_description || course.description.substring(0, 100) + '...' %></p>
                                        
                                        <div class="mb-3">
                                            <small class="text-muted">
                                                <i class="fas fa-clock"></i> <%= course.duration_hours %> horas
                                                <i class="fas fa-signal ms-2"></i> <%= course.difficulty_level.charAt(0).toUpperCase() + course.difficulty_level.slice(1) %>
                                                <i class="fas fa-tag ms-2"></i> <%= course.category.charAt(0).toUpperCase() + course.category.slice(1) %>
                                            </small>
                                        </div>
                                        
                                        <% if (enrollmentMap[course.id] !== undefined) { %>
                                            <div class="mb-2">
                                                <div class="progress">
                                                    <div class="progress-bar" role="progressbar" style="width: <%= enrollmentMap[course.id] %>%" aria-valuenow="<%= enrollmentMap[course.id] %>" aria-valuemin="0" aria-valuemax="100">
                                                        <%= enrollmentMap[course.id] %>%
                                                    </div>
                                                </div>
                                                <small class="text-success">
                                                    <i class="fas fa-check-circle"></i> Matriculado
                                                </small>
                                            </div>
                                        <% } %>
                                        
                                        <div class="mt-auto">
                                            <a href="/courses/<%= course.id %>" class="btn btn-primary w-100">
                                                <i class="fas fa-eye"></i> Ver Curso
                                            </a>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        <% }); %>
                    <% } else { %>
                        <div class="col-12">
                            <div class="card">
                                <div class="card-body text-center">
                                    <i class="fas fa-search fa-5x text-muted mb-3"></i>
                                    <h5 class="card-title">No se encontraron cursos</h5>
                                    <p class="card-text">No hay cursos disponibles con los filtros seleccionados.</p>
                                    <a href="/courses" class="btn btn-primary">Ver todos los cursos</a>
                                </div>
                            </div>
                        </div>
                    <% } %>
                </div>
            </div>
        </div>
    </div>
    
    <!-- Modal para código de matrícula -->
    <% if (user.role === 'student') { %>
    <div class="modal fade" id="enrollCodeModal" tabindex="-1" aria-labelledby="enrollCodeModalLabel" aria-hidden="true">
        <div class="modal-dialog">
            <div class="modal-content">
                <form method="POST" action="/courses/enroll-with-code">
                    <div class="modal-header">
                        <h5 class="modal-title" id="enrollCodeModalLabel">
                            <i class="fas fa-key"></i> Matricularse con Código
                        </h5>
                        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                    </div>
                    <div class="modal-body">
                        <div class="mb-3">
                            <label for="enrollment_code" class="form-label">Código de Matrícula:</label>
                            <input type="text" class="form-control" id="enrollment_code" name="enrollment_code" required placeholder="Ingresa tu código...">
                            <div class="form-text">Solicita el código a tu instructor o administrador.</div>
                        </div>
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancelar</button>
                        <button type="submit" class="btn btn-primary">
                            <i class="fas fa-check"></i> Matricularse
                        </button>
                    </div>
                </form>
            </div>
        </div>
    </div>
    <% } %>
    
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/js/bootstrap.bundle.min.js" integrity="sha384-ka7Sk0Gln4gmtz2MlQnikT1wXgYsOg+OMhuP+IlRH9sENBO0LRn5q+8nbTov4+1p" crossorigin="anonymous"></script>
    <script src="/js/main.js"></script>
</body>
</html>
EOF

# 4. CREAR VISTA DE DETALLE DE CURSO
print_status "Creando vista de detalle de curso..."
cat > views/courses/show.ejs << 'EOF'
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><%= title %></title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css" rel="stylesheet" integrity="sha384-1BmE4kWBq78iYhFldvKuhfTAU6auU8tT94WrHftjDbrCEXSU1oBoqyl2QvZ6jIW3" crossorigin="anonymous">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css" rel="stylesheet" integrity="sha512-9usAa10IRO0HhonpyAIVpjrylPvoDwiPUiKdWk5t3PyolY1cOd4DSE0Ga+ri4AuTroPR5aQvXU9xC6qOPnzFeg==" crossorigin="anonymous">
    <link href="/css/style.css" rel="stylesheet">
</head>
<body>
    <%- include('../partials/navbar') %>
    
    <div class="container mt-4">
        <% if (typeof message !== 'undefined' && message) { %>
            <div class="alert alert-success alert-dismissible fade show" role="alert">
                <%= message %>
                <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
            </div>
        <% } %>
        
        <% if (typeof error !== 'undefined' && error) { %>
            <div class="alert alert-danger alert-dismissible fade show" role="alert">
                <%= error %>
                <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
            </div>
        <% } %>
        
        <div class="row">
            <div class="col-12">
                <nav aria-label="breadcrumb">
                    <ol class="breadcrumb">
                        <li class="breadcrumb-item"><a href="/courses">Cursos</a></li>
                        <li class="breadcrumb-item active" aria-current="page"><%= course.title %></li>
                    </ol>
                </nav>
            </div>
        </div>
        
        <div class="row">
            <!-- Información del curso -->
            <div class="col-lg-8">
                <div class="card">
                    <% if (course.thumbnail) { %>
                        <img src="<%= course.thumbnail %>" class="card-img-top" alt="<%= course.title %>" style="height: 300px; object-fit: cover;">
                    <% } else { %>
                        <div class="card-img-top bg-primary d-flex align-items-center justify-content-center" style="height: 300px;">
                            <i class="fas fa-graduation-cap fa-5x text-white"></i>
                        </div>
                    <% } %>
                    
                    <div class="card-body">
                        <h1 class="card-title"><%= course.title %></h1>
                        <p class="lead"><%= course.short_description %></p>
                        
                        <div class="row mb-3">
                            <div class="col-md-3">
                                <small class="text-muted">Duración:</small><br>
                                <strong><i class="fas fa-clock"></i> <%= course.duration_hours %> horas</strong>
                            </div>
                            <div class="col-md-3">
                                <small class="text-muted">Nivel:</small><br>
                                <strong><i class="fas fa-signal"></i> <%= course.difficulty_level.charAt(0).toUpperCase() + course.difficulty_level.slice(1) %></strong>
                            </div>
                            <div class="col-md-3">
                                <small class="text-muted">Categoría:</small><br>
                                <strong><i class="fas fa-tag"></i> <%= course.category.charAt(0).toUpperCase() + course.category.slice(1) %></strong>
                            </div>
                            <div class="col-md-3">
                                <small class="text-muted">Estudiantes:</small><br>
                                <strong><i class="fas fa-users"></i> <%= enrollmentCount %></strong>
                            </div>
                        </div>
                        
                        <% if (isEnrolled && enrollment) { %>
                            <div class="alert alert-success" role="alert">
                                <h6 class="alert-heading">
                                    <i class="fas fa-check-circle"></i> ¡Estás matriculado en este curso!
                                </h6>
                                <div class="progress mb-2">
                                    <div class="progress-bar" role="progressbar" style="width: <%= enrollment.progress %>%" aria-valuenow="<%= enrollment.progress %>" aria-valuemin="0" aria-valuemax="100">
                                        <%= enrollment.progress %>%
                                    </div>
                                </div>
                                <small>Progreso del curso: <%= enrollment.progress %>% completado</small>
                            </div>
                        <% } %>
                        
                        <h3>Descripción</h3>
                        <p><%= course.description %></p>
                        
                        <h3>Instructor</h3>
                        <p><i class="fas fa-user"></i> <%= course.creator.first_name %> <%= course.creator.last_name %></p>
                    </div>
                </div>
            </div>
            
            <!-- Sidebar -->
            <div class="col-lg-4">
                <!-- Acción principal -->
                <div class="card mb-4">
                    <div class="card-body text-center">
                        <% if (isEnrolled) { %>
                            <h5 class="text-success">
                                <i class="fas fa-check-circle"></i> Matriculado
                            </h5>
                            <% if (course.units && course.units.length > 0) { %>
                                <a href="/courses/<%= course.id %>/unit/<%= course.units[0].id %>" class="btn btn-success btn-lg w-100 mb-2">
                                    <i class="fas fa-play"></i> Continuar Curso
                                </a>
                            <% } %>
                            <a href="/forum/<%= course.id %>" class="btn btn-outline-primary w-100">
                                <i class="fas fa-comments"></i> Ir al Foro
                            </a>
                        <% } else if (user.role === 'student') { %>
                            <form method="POST" action="/courses/<%= course.id %>/enroll">
                                <button type="submit" class="btn btn-primary btn-lg w-100">
                                    <i class="fas fa-user-plus"></i> Matricularse
                                </button>
                            </form>
                            <small class="text-muted">Matrícula gratuita</small>
                        <% } else { %>
                            <p class="text-muted">Solo los estudiantes pueden matricularse en cursos.</p>
                        <% } %>
                    </div>
                </div>
                
                <!-- Contenido del curso -->
                <div class="card">
                    <div class="card-header">
                        <h5><i class="fas fa-list"></i> Contenido del Curso</h5>
                        <small class="text-muted"><%= unitsCount %> unidades</small>
                    </div>
                    <div class="card-body p-0">
                        <% if (course.units && course.units.length > 0) { %>
                            <div class="list-group list-group-flush">
                                <% course.units.forEach((unit, index) => { %>
                                    <div class="list-group-item">
                                        <div class="d-flex w-100 justify-content-between align-items-center">
                                            <div>
                                                <h6 class="mb-1">
                                                    <%= index + 1 %>. <%= unit.title %>
                                                </h6>
                                                <% if (unit.content_type === 'video') { %>
                                                    <small class="text-muted">
                                                        <i class="fas fa-play-circle"></i> Video - <%= unit.duration_minutes %> min
                                                    </small>
                                                <% } else if (unit.content_type === 'pdf') { %>
                                                    <small class="text-muted">
                                                        <i class="fas fa-file-pdf"></i> PDF
                                                    </small>
                                                <% } else if (unit.content_type === 'lab') { %>
                                                    <small class="text-muted">
                                                        <i class="fas fa-flask"></i> Laboratorio
                                                    </small>
                                                <% } else { %>
                                                    <small class="text-muted">
                                                        <i class="fas fa-file-text"></i> Contenido
                                                    </small>
                                                <% } %>
                                            </div>
                                            <% if (isEnrolled) { %>
                                                <a href="/courses/<%= course.id %>/unit/<%= unit.id %>" class="btn btn-sm btn-outline-primary">
                                                    <i class="fas fa-eye"></i>
                                                </a>
                                            <% } else { %>
                                                <i class="fas fa-lock text-muted"></i>
                                            <% } %>
                                        </div>
                                    </div>
                                <% }); %>
                            </div>
                        <% } else { %>
                            <div class="p-3 text-center text-muted">
                                <i class="fas fa-inbox fa-2x mb-2"></i>
                                <p>Este curso aún no tiene contenido.</p>
                            </div>
                        <% } %>
                    </div>
                </div>
            </div>
        </div>
    </div>
    
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/js/bootstrap.bundle.min.js" integrity="sha384-ka7Sk0Gln4gmtz2MlQnikT1wXgYsOg+OMhuP+IlRH9sENBO0LRn5q+8nbTov4+1p" crossorigin="anonymous"></script>
    <script src="/js/main.js"></script>
</body>
</html>
EOF

print_status "✅ Gestión de cursos desarrollada completamente!"
echo ""
echo "🎯 Funcionalidades implementadas:"
echo "   ✓ Lista de cursos con filtros"
echo "   ✓ Detalle completo de cursos"
echo "   ✓ Sistema de matrícula"
echo "   ✓ Matrícula con códigos"
echo "   ✓ Navegación de unidades"
echo "   ✓ Progreso visual"
echo "   ✓ Roles y permisos"
echo ""
echo "📋 Rutas disponibles:"
echo "   GET  /courses - Lista de cursos"
echo "   GET  /courses/:id - Detalle del curso"
echo "   POST /courses/:id/enroll - Matricularse"
echo "   POST /courses/enroll-with-code - Matrícula con código"
echo "   GET  /courses/my-courses - Mis cursos"
echo "   GET  /courses/:courseId/unit/:unitId - Ver unidad"
echo ""
echo "🚀 Para probar:"
echo "   1. Reiniciar la aplicación: npm run dev"
echo "   2. Ir a: http://tu-ip:3000/courses"
echo "   3. Probar matrícula con código: REDES2024"
echo ""
print_warning "⚠️  Próximo paso: Crear vista de unidades y sistema de exámenes"
