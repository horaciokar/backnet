#!/bin/bash

# Script para crear los archivos faltantes del proyecto
echo "🔧 Creando archivos faltantes..."

# ===========================================
# MODELS/ASSOCIATIONS.JS
# ===========================================
echo "🔗 Creando models/associations.js..."
cat > models/associations.js << 'EOF'
// models/associations.js
const User = require('./User');
const Course = require('./Course');

function setupAssociations() {
  // Usuario crea cursos
  User.hasMany(Course, { 
    foreignKey: 'created_by', 
    as: 'createdCourses' 
  });
  Course.belongsTo(User, { 
    foreignKey: 'created_by', 
    as: 'creator' 
  });
  
  console.log('✅ Asociaciones de modelos configuradas correctamente');
}

module.exports = { setupAssociations };
EOF

# ===========================================
# MODELS/COURSEUNIT.JS
# ===========================================
echo "📖 Creando models/CourseUnit.js..."
cat > models/CourseUnit.js << 'EOF'
const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');

const CourseUnit = sequelize.define('CourseUnit', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true
  },
  
  course_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: {
      model: 'courses',
      key: 'id'
    }
  },
  
  title: {
    type: DataTypes.STRING(100),
    allowNull: false,
    validate: {
      len: [3, 100]
    }
  },
  
  description: {
    type: DataTypes.TEXT,
    allowNull: true
  },
  
  content: {
    type: DataTypes.TEXT,
    allowNull: true
  },
  
  order_number: {
    type: DataTypes.INTEGER,
    allowNull: false,
    validate: {
      min: 1
    }
  },
  
  content_type: {
    type: DataTypes.ENUM('text', 'video', 'pdf', 'lab', 'mixed'),
    allowNull: false,
    defaultValue: 'text'
  },
  
  video_url: {
    type: DataTypes.STRING(255),
    allowNull: true,
    validate: {
      isUrl: true
    }
  },
  
  duration_minutes: {
    type: DataTypes.INTEGER,
    allowNull: false,
    defaultValue: 0,
    validate: {
      min: 0
    }
  },
  
  is_active: {
    type: DataTypes.BOOLEAN,
    defaultValue: true
  }
}, {
  tableName: 'course_units'
});

module.exports = CourseUnit;
EOF

# ===========================================
# MODELS/ENROLLMENT.JS
# ===========================================
echo "📝 Creando models/Enrollment.js..."
cat > models/Enrollment.js << 'EOF'
const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');

const Enrollment = sequelize.define('Enrollment', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true
  },
  
  user_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: {
      model: 'users',
      key: 'id'
    }
  },
  
  course_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: {
      model: 'courses',
      key: 'id'
    }
  },
  
  enrolled_at: {
    type: DataTypes.DATE,
    allowNull: false,
    defaultValue: DataTypes.NOW
  },
  
  progress: {
    type: DataTypes.INTEGER,
    allowNull: false,
    defaultValue: 0,
    validate: {
      min: 0,
      max: 100
    }
  },
  
  is_active: {
    type: DataTypes.BOOLEAN,
    defaultValue: true
  }
}, {
  tableName: 'enrollments'
});

const EnrollmentCode = sequelize.define('EnrollmentCode', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true
  },
  
  course_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: {
      model: 'courses',
      key: 'id'
    }
  },
  
  code: {
    type: DataTypes.STRING(20),
    allowNull: false,
    unique: true,
    validate: {
      len: [6, 20]
    }
  },
  
  max_uses: {
    type: DataTypes.INTEGER,
    allowNull: false,
    defaultValue: 50
  },
  
  used_count: {
    type: DataTypes.INTEGER,
    allowNull: false,
    defaultValue: 0
  },
  
  is_active: {
    type: DataTypes.BOOLEAN,
    defaultValue: true
  }
}, {
  tableName: 'enrollment_codes'
});

module.exports = { Enrollment, EnrollmentCode };
EOF

# ===========================================
# ACTUALIZAR VIEWS/DASHBOARD/STUDENT.EJS
# ===========================================
echo "👁️ Actualizando views/dashboard/student.ejs..."
cat > views/dashboard/student.ejs << 'EOF'
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
                <h1>¡Bienvenido, <%= user.first_name %>!</h1>
                <p class="lead">Dashboard del estudiante</p>
                
                <div class="row">
                    <div class="col-md-6 mb-4">
                        <div class="card">
                            <div class="card-body">
                                <h5 class="card-title">
                                    <i class="fas fa-book text-primary"></i> Mis Cursos
                                </h5>
                                <p class="card-text">Accede a tus cursos matriculados</p>
                                <a href="/courses" class="btn btn-primary">
                                    <i class="fas fa-arrow-right"></i> Ver Cursos
                                </a>
                            </div>
                        </div>
                    </div>
                    
                    <div class="col-md-6 mb-4">
                        <div class="card">
                            <div class="card-body">
                                <h5 class="card-title">
                                    <i class="fas fa-chart-line text-success"></i> Progreso
                                </h5>
                                <p class="card-text">Revisa tu progreso académico</p>
                                <a href="/dashboard/progress" class="btn btn-success">
                                    <i class="fas fa-chart-bar"></i> Ver Progreso
                                </a>
                            </div>
                        </div>
                    </div>
                </div>
                
                <div class="row">
                    <div class="col-md-6 mb-4">
                        <div class="card">
                            <div class="card-body">
                                <h5 class="card-title">
                                    <i class="fas fa-clipboard-check text-warning"></i> Exámenes
                                </h5>
                                <p class="card-text">Revisa tus exámenes y calificaciones</p>
                                <a href="/exams" class="btn btn-warning">
                                    <i class="fas fa-list-check"></i> Ver Exámenes
                                </a>
                            </div>
                        </div>
                    </div>
                    
                    <div class="col-md-6 mb-4">
                        <div class="card">
                            <div class="card-body">
                                <h5 class="card-title">
                                    <i class="fas fa-comments text-info"></i> Foros
                                </h5>
                                <p class="card-text">Participa en las discusiones</p>
                                <a href="/forum" class="btn btn-info">
                                    <i class="fas fa-comment-dots"></i> Ver Foros
                                </a>
                            </div>
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
EOF

# ===========================================
# VIEWS/DASHBOARD/INSTRUCTOR.EJS
# ===========================================
echo "👁️ Creando views/dashboard/instructor.ejs..."
cat > views/dashboard/instructor.ejs << 'EOF'
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
    
    <div class="container mt-4">
        <% if (typeof message !== 'undefined' && message) { %>
            <div class="alert alert-success alert-dismissible fade show" role="alert">
                <%= message %>
                <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
            </div>
        <% } %>
        
        <div class="row">
            <div class="col-12">
                <h1>¡Bienvenido, <%= user.first_name %>!</h1>
                <p class="lead">Dashboard del instructor</p>
                
                <div class="row">
                    <div class="col-md-6 mb-4">
                        <div class="card">
                            <div class="card-body">
                                <h5 class="card-title">
                                    <i class="fas fa-chalkboard-teacher text-primary"></i> Mis Cursos
                                </h5>
                                <p class="card-text">Gestiona tus cursos asignados</p>
                                <a href="/courses" class="btn btn-primary">
                                    <i class="fas fa-arrow-right"></i> Ver Cursos
                                </a>
                            </div>
                        </div>
                    </div>
                    
                    <div class="col-md-6 mb-4">
                        <div class="card">
                            <div class="card-body">
                                <h5 class="card-title">
                                    <i class="fas fa-users text-success"></i> Estudiantes
                                </h5>
                                <p class="card-text">Monitorea el progreso de tus estudiantes</p>
                                <a href="/instructor/students" class="btn btn-success">
                                    <i class="fas fa-user-graduate"></i> Ver Estudiantes
                                </a>
                            </div>
                        </div>
                    </div>
                </div>
                
                <div class="row">
                    <div class="col-md-6 mb-4">
                        <div class="card">
                            <div class="card-body">
                                <h5 class="card-title">
                                    <i class="fas fa-chart-bar text-warning"></i> Reportes
                                </h5>
                                <p class="card-text">Revisa estadísticas y reportes</p>
                                <a href="/instructor/reports" class="btn btn-warning">
                                    <i class="fas fa-chart-line"></i> Ver Reportes
                                </a>
                            </div>
                        </div>
                    </div>
                    
                    <div class="col-md-6 mb-4">
                        <div class="card">
                            <div class="card-body">
                                <h5 class="card-title">
                                    <i class="fas fa-comments text-info"></i> Foros
                                </h5>
                                <p class="card-text">Modera las discusiones</p>
                                <a href="/forum" class="btn btn-info">
                                    <i class="fas fa-comment-dots"></i> Ver Foros
                                </a>
                            </div>
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
EOF

# ===========================================
# VIEWS/ADMIN/DASHBOARD.EJS
# ===========================================
echo "👁️ Creando views/admin/dashboard.ejs..."
cat > views/admin/dashboard.ejs << 'EOF'
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
    
    <div class="container mt-4">
        <% if (typeof message !== 'undefined' && message) { %>
            <div class="alert alert-success alert-dismissible fade show" role="alert">
                <%= message %>
                <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
            </div>
        <% } %>
        
        <div class="row">
            <div class="col-12">
                <h1>Panel de Administración</h1>
                <p class="lead">Gestiona toda la plataforma educativa</p>
                
                <div class="row">
                    <div class="col-md-3 mb-4">
                        <div class="card bg-primary text-white">
                            <div class="card-body">
                                <div class="d-flex justify-content-between">
                                    <div>
                                        <h5 class="card-title">Usuarios</h5>
                                        <h3>0</h3>
                                    </div>
                                    <div>
                                        <i class="fas fa-users fa-2x"></i>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                    
                    <div class="col-md-3 mb-4">
                        <div class="card bg-success text-white">
                            <div class="card-body">
                                <div class="d-flex justify-content-between">
                                    <div>
                                        <h5 class="card-title">Cursos</h5>
                                        <h3>0</h3>
                                    </div>
                                    <div>
                                        <i class="fas fa-book fa-2x"></i>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                    
                    <div class="col-md-3 mb-4">
                        <div class="card bg-warning text-white">
                            <div class="card-body">
                                <div class="d-flex justify-content-between">
                                    <div>
                                        <h5 class="card-title">Matrículas</h5>
                                        <h3>0</h3>
                                    </div>
                                    <div>
                                        <i class="fas fa-user-graduate fa-2x"></i>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                    
                    <div class="col-md-3 mb-4">
                        <div class="card bg-info text-white">
                            <div class="card-body">
                                <div class="d-flex justify-content-between">
                                    <div>
                                        <h5 class="card-title">Exámenes</h5>
                                        <h3>0</h3>
                                    </div>
                                    <div>
                                        <i class="fas fa-clipboard-check fa-2x"></i>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
                
                <div class="row">
                    <div class="col-md-4 mb-4">
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
                    
                    <div class="col-md-4 mb-4">
                        <div class="card">
                            <div class="card-body">
                                <h5 class="card-title">
                                    <i class="fas fa-book text-success"></i> Gestión de Cursos
                                </h5>
                                <p class="card-text">Crea y administra cursos</p>
                                <a href="/admin/courses" class="btn btn-success">
                                    <i class="fas fa-plus-circle"></i> Gestionar Cursos
                                </a>
                            </div>
                        </div>
                    </div>
                    
                    <div class="col-md-4 mb-4">
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
        </div>
    </div>
    
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/js/bootstrap.bundle.min.js"></script>
    <script src="/js/main.js"></script>
</body>
</html>
EOF

# ===========================================
# VIEWS/COURSES/INDEX.EJS
# ===========================================
echo "👁️ Creando views/courses/index.ejs..."
cat > views/courses/index.ejs << 'EOF'
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
    
    <div class="container mt-4">
        <% if (typeof message !== 'undefined' && message) { %>
            <div class="alert alert-success alert-dismissible fade show" role="alert">
                <%= message %>
                <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
            </div>
        <% } %>
        
        <div class="row">
            <div class="col-12">
                <h1><i class="fas fa-book"></i> Cursos Disponibles</h1>
                <p class="lead">Explora y matricúlate en nuestros cursos</p>
                
                <div class="row">
                    <div class="col-md-12">
                        <div class="card">
                            <div class="card-body text-center">
                                <i class="fas fa-graduation-cap fa-5x text-muted mb-3"></i>
                                <h5 class="card-title">No hay cursos disponibles</h5>
                                <p class="card-text">Próximamente estarán disponibles cursos de redes y seguridad informática.</p>
                                <% if (user.role === 'admin') { %>
                                    <a href="/admin/courses" class="btn btn-primary">
                                        <i class="fas fa-plus"></i> Crear Curso
                                    </a>
                                <% } %>
                            </div>
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
EOF

# ===========================================
# VIEWS/COURSES/SHOW.EJS
# ===========================================
echo "👁️ Creando views/courses/show.ejs..."
cat > views/courses/show.ejs << 'EOF'
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
    
    <div class="container mt-4">
        <div class="row">
            <div class="col-12">
                <nav aria-label="breadcrumb">
                    <ol class="breadcrumb">
                        <li class="breadcrumb-item"><a href="/courses">Cursos</a></li>
                        <li class="breadcrumb-item active" aria-current="page"><%= course.title %></li>
                    </ol>
                </nav>
                
                <div class="card">
                    <div class="card-body">
                        <h1 class="card-title"><%= course.title %></h1>
                        <p class="card-text">Detalles del curso seleccionado</p>
                        
                        <div class="mt-4">
                            <a href="/courses" class="btn btn-secondary">
                                <i class="fas fa-arrow-left"></i> Volver a Cursos
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
EOF

# ===========================================
# VIEWS/EXAMS/INDEX.EJS
# ===========================================
echo "👁️ Creando views/exams/index.ejs..."
cat > views/exams/index.ejs << 'EOF'
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
    
    <div class="container mt-4">
        <div class="row">
            <div class="col-12">
                <h1><i class="fas fa-clipboard-check"></i> Exámenes</h1>
                <p class="lead">Revisa tus exámenes y calificaciones</p>
                
                <div class="card">
                    <div class="card-body text-center">
                        <i class="fas fa-file-alt fa-5x text-muted mb-3"></i>
                        <h5 class="card-title">No hay exámenes disponibles</h5>
                        <p class="card-text">Los exámenes aparecerán aquí cuando estés matriculado en cursos.</p>
                        <a href="/courses" class="btn btn-primary">
                            <i class="fas fa-book"></i> Ver Cursos
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
EOF

# ===========================================
# VIEWS/FORUM/INDEX.EJS
# ===========================================
echo "👁️ Creando views/forum/index.ejs..."
cat > views/forum/index.ejs << 'EOF'
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
    
    <div class="container mt-4">
        <div class="row">
            <div class="col-12">
                <h1><i class="fas fa-comments"></i> Foro</h1>
                <p class="lead">Participa en las discusiones</p>
                
                <div class="card">
                    <div class="card-body text-center">
                        <i class="fas fa-comment-dots fa-5x text-muted mb-3"></i>
                        <h5 class="card-title">No hay discusiones disponibles</h5>
                        <p class="card-text">Los foros aparecerán aquí cuando estés matriculado en cursos.</p>
                        <a href="/courses" class="btn btn-primary">
                            <i class="fas fa-book"></i> Ver Cursos
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
EOF

echo "✅ ¡Archivos faltantes creados exitosamente!"
echo ""
echo "🔧 Archivos creados:"
echo "   ✓ models/associations.js"
echo "   ✓ models/CourseUnit.js"
echo "   ✓ models/Enrollment.js"
echo "   ✓ views/dashboard/instructor.ejs"
echo "   ✓ views/admin/dashboard.ejs"
echo "   ✓ views/courses/index.ejs"
echo "   ✓ views/courses/show.ejs"
echo "   ✓ views/exams/index.ejs"
echo "   ✓ views/forum/index.ejs"
echo "   ✓ Actualizado views/dashboard/student.ejs"
echo ""
echo "🚀 Ahora puedes ejecutar: npm run dev"
echo ""
echo "⚠️  Recuerda configurar tu base de datos en .env antes de ejecutar"