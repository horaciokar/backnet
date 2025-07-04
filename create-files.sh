#!/bin/bash

# Script para crear todos los archivos del proyecto Learning Platform
# Ejecutar desde la raíz del proyecto: bash create-files.sh

echo "🚀 Creando todos los archivos del proyecto Learning Platform..."

# Crear estructura de directorios
mkdir -p config controllers middleware models routes views/{layouts,partials,auth,dashboard,courses,exams,forum,admin} public/{css,js,images} uploads/{courses,videos,profiles} database/{migrations,seeders} tests

# ===========================================
# 1. PACKAGE.JSON
# ===========================================
echo "📦 Creando package.json..."
cat > package.json << 'EOF'
{
  "name": "learning-platform",
  "version": "1.0.0",
  "description": "Plataforma educativa para cursos de redes y seguridad informática",
  "main": "server.js",
  "scripts": {
    "start": "node server.js",
    "dev": "nodemon server.js",
    "test": "jest"
  },
  "dependencies": {
    "express": "^4.18.2",
    "mysql2": "^3.6.5",
    "sequelize": "^6.35.2",
    "bcryptjs": "^2.4.3",
    "jsonwebtoken": "^9.0.2",
    "express-session": "^1.17.3",
    "express-validator": "^7.0.1",
    "multer": "^1.4.5-lts.1",
    "ejs": "^3.1.9",
    "dotenv": "^16.3.1",
    "helmet": "^7.1.0",
    "cors": "^2.8.5",
    "morgan": "^1.10.0",
    "compression": "^1.7.4",
    "express-rate-limit": "^7.1.5"
  },
  "devDependencies": {
    "nodemon": "^3.0.2",
    "jest": "^29.7.0"
  },
  "keywords": ["education", "learning", "platform", "courses"],
  "author": "Horacio Kar",
  "license": "MIT"
}
EOF

# ===========================================
# 2. SERVER.JS
# ===========================================
echo "⚙️ Creando server.js..."
cat > server.js << 'EOF'
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

// Importar middleware
const { authenticateToken } = require('./middleware/auth');
const { setupAssociations } = require('./models/associations');

const app = express();
const PORT = process.env.PORT || 3000;

// Configurar rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutos
  max: 100, // máximo 100 requests por IP
  message: 'Demasiadas solicitudes, intenta de nuevo más tarde.'
});

// Middleware de seguridad
app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'", "https://cdn.jsdelivr.net"],
      scriptSrc: ["'self'", "https://cdn.jsdelivr.net"],
      imgSrc: ["'self'", "data:", "https:"],
      frameSrc: ["https://www.youtube.com", "https://youtube.com"]
    }
  }
}));

app.use(compression());
app.use(morgan('combined'));
app.use(limiter);

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
    maxAge: 24 * 60 * 60 * 1000 // 24 horas
  }
}));

// Middleware global para variables de vista
app.use((req, res, next) => {
  res.locals.user = req.session.user || null;
  res.locals.message = req.session.message || null;
  res.locals.error = req.session.error || null;
  
  // Limpiar mensajes después de mostrarlos
  delete req.session.message;
  delete req.session.error;
  
  next();
});

// Rutas
app.use('/auth', authRoutes);
app.use('/dashboard', authenticateToken, dashboardRoutes);
app.use('/courses', authenticateToken, courseRoutes);
app.use('/exams', authenticateToken, examRoutes);
app.use('/forum', authenticateToken, forumRoutes);
app.use('/admin', authenticateToken, adminRoutes);

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
  console.error(err.stack);
  res.status(500).render('error', { 
    title: 'Error del servidor',
    error: 'Algo salió mal en el servidor.',
    code: 500
  });
});

// Configurar asociaciones de modelos
setupAssociations();

// Iniciar servidor
app.listen(PORT, () => {
  console.log(`Servidor corriendo en puerto ${PORT}`);
  console.log(`Modo: ${process.env.NODE_ENV || 'development'}`);
});

module.exports = app;
EOF

# ===========================================
# 3. .ENV.EXAMPLE
# ===========================================
echo "🔐 Creando .env.example..."
cat > .env.example << 'EOF'
# Configuración del servidor
NODE_ENV=development
PORT=3000

# Base de datos MySQL/Aurora
DB_HOST=localhost
DB_PORT=3306
DB_NAME=learning_platform
DB_USER=root
DB_PASSWORD=tu_password

# Seguridad
JWT_SECRET=tu-jwt-secret-muy-largo-y-seguro
SESSION_SECRET=tu-session-secret-muy-largo-y-seguro

# AWS (para producción)
AWS_REGION=us-east-1
AWS_ACCESS_KEY_ID=tu_access_key
AWS_SECRET_ACCESS_KEY=tu_secret_key

# Upload limits
MAX_FILE_SIZE=10485760
UPLOAD_PATH=./uploads

# Rate limiting
RATE_LIMIT_WINDOW=900000
RATE_LIMIT_MAX=100
EOF

# ===========================================
# 4. CONFIG/DATABASE.JS
# ===========================================
echo "🗄️ Creando config/database.js..."
cat > config/database.js << 'EOF'
const { Sequelize } = require('sequelize');
require('dotenv').config();

const sequelize = new Sequelize(
  process.env.DB_NAME,
  process.env.DB_USER,
  process.env.DB_PASSWORD,
  {
    host: process.env.DB_HOST,
    port: process.env.DB_PORT || 3306,
    dialect: 'mysql',
    
    // Configuración de pool de conexiones optimizada para free tier
    pool: {
      max: 5,        // Máximo 5 conexiones simultáneas
      min: 0,        // Mínimo 0 conexiones
      acquire: 30000, // Tiempo máximo para obtener conexión
      idle: 10000    // Tiempo máximo inactivo antes de cerrar
    },
    
    // Configuración de logging
    logging: process.env.NODE_ENV === 'development' ? console.log : false,
    
    // Configuración de zona horaria
    timezone: '-05:00', // Colombia timezone
    
    // Configuración adicional
    define: {
      timestamps: true,
      underscored: true,
      freezeTableName: true,
      charset: 'utf8mb4',
      collate: 'utf8mb4_unicode_ci'
    },
    
    // Configuración de dialecto MySQL
    dialectOptions: {
      charset: 'utf8mb4',
      dateStrings: true,
      typeCast: true
    }
  }
);

// Función para probar la conexión
async function testConnection() {
  try {
    await sequelize.authenticate();
    console.log('✅ Conexión a la base de datos establecida correctamente.');
    return true;
  } catch (error) {
    console.error('❌ Error al conectar con la base de datos:', error.message);
    return false;
  }
}

// Función para sincronizar modelos
async function syncDatabase(force = false) {
  try {
    await sequelize.sync({ force });
    console.log('✅ Modelos sincronizados con la base de datos.');
  } catch (error) {
    console.error('❌ Error al sincronizar modelos:', error.message);
    throw error;
  }
}

// Función para cerrar conexión
async function closeConnection() {
  try {
    await sequelize.close();
    console.log('✅ Conexión a la base de datos cerrada.');
  } catch (error) {
    console.error('❌ Error al cerrar la conexión:', error.message);
  }
}

module.exports = {
  sequelize,
  testConnection,
  syncDatabase,
  closeConnection
};
EOF

# ===========================================
# 5. MODELS/USER.JS
# ===========================================
echo "👤 Creando models/User.js..."
cat > models/User.js << 'EOF'
const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');
const bcrypt = require('bcryptjs');

const User = sequelize.define('User', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true
  },
  
  email: {
    type: DataTypes.STRING(100),
    allowNull: false,
    unique: true,
    validate: {
      isEmail: true,
      len: [5, 100]
    }
  },
  
  password: {
    type: DataTypes.STRING(255),
    allowNull: false,
    validate: {
      len: [6, 255]
    }
  },
  
  first_name: {
    type: DataTypes.STRING(50),
    allowNull: false,
    validate: {
      len: [2, 50]
    }
  },
  
  last_name: {
    type: DataTypes.STRING(50),
    allowNull: false,
    validate: {
      len: [2, 50]
    }
  },
  
  role: {
    type: DataTypes.ENUM('admin', 'instructor', 'student'),
    allowNull: false,
    defaultValue: 'student'
  },
  
  is_active: {
    type: DataTypes.BOOLEAN,
    defaultValue: true
  },
  
  profile_picture: {
    type: DataTypes.STRING(255),
    allowNull: true
  },
  
  last_login: {
    type: DataTypes.DATE,
    allowNull: true
  }
}, {
  tableName: 'users',
  
  hooks: {
    beforeCreate: async (user) => {
      if (user.password) {
        user.password = await bcrypt.hash(user.password, 10);
      }
    },
    
    beforeUpdate: async (user) => {
      if (user.changed('password')) {
        user.password = await bcrypt.hash(user.password, 10);
      }
    }
  }
});

// Métodos de instancia
User.prototype.validatePassword = async function(password) {
  return await bcrypt.compare(password, this.password);
};

User.prototype.getFullName = function() {
  return `${this.first_name} ${this.last_name}`;
};

User.prototype.toJSON = function() {
  const values = Object.assign({}, this.get());
  delete values.password;
  return values;
};

// Métodos de clase
User.findByEmail = async function(email) {
  return await this.findOne({ where: { email } });
};

User.findActiveUsers = async function() {
  return await this.findAll({ 
    where: { is_active: true },
    order: [['created_at', 'DESC']]
  });
};

User.findByRole = async function(role) {
  return await this.findAll({ 
    where: { role, is_active: true },
    order: [['first_name', 'ASC']]
  });
};

module.exports = User;
EOF

# ===========================================
# 6. MODELS/COURSE.JS
# ===========================================
echo "📚 Creando models/Course.js..."
cat > models/Course.js << 'EOF'
const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');

const Course = sequelize.define('Course', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true
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
    allowNull: false,
    validate: {
      len: [10, 2000]
    }
  },
  
  short_description: {
    type: DataTypes.STRING(255),
    allowNull: true,
    validate: {
      len: [0, 255]
    }
  },
  
  duration_hours: {
    type: DataTypes.INTEGER,
    allowNull: false,
    defaultValue: 0,
    validate: {
      min: 0,
      max: 1000
    }
  },
  
  difficulty_level: {
    type: DataTypes.ENUM('beginner', 'intermediate', 'advanced'),
    allowNull: false,
    defaultValue: 'beginner'
  },
  
  category: {
    type: DataTypes.ENUM('networks', 'security', 'both'),
    allowNull: false,
    defaultValue: 'both'
  },
  
  thumbnail: {
    type: DataTypes.STRING(255),
    allowNull: true
  },
  
  is_active: {
    type: DataTypes.BOOLEAN,
    defaultValue: true
  },
  
  is_public: {
    type: DataTypes.BOOLEAN,
    defaultValue: false
  },
  
  max_students: {
    type: DataTypes.INTEGER,
    allowNull: true,
    validate: {
      min: 1
    }
  },
  
  created_by: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: {
      model: 'users',
      key: 'id'
    }
  }
}, {
  tableName: 'courses',
  
  indexes: [
    {
      fields: ['title']
    },
    {
      fields: ['category']
    },
    {
      fields: ['is_active']
    },
    {
      fields: ['created_by']
    }
  ]
});

// Métodos de instancia
Course.prototype.getEnrollmentCount = async function() {
  const { Enrollment } = require('./Enrollment');
  return await Enrollment.count({
    where: { course_id: this.id }
  });
};

Course.prototype.getUnitsCount = async function() {
  const CourseUnit = require('./CourseUnit');
  return await CourseUnit.count({
    where: { course_id: this.id }
  });
};

// Métodos de clase
Course.findActive = async function() {
  return await this.findAll({
    where: { is_active: true },
    order: [['created_at', 'DESC']]
  });
};

Course.findByCategory = async function(category) {
  return await this.findAll({
    where: { 
      category,
      is_active: true 
    },
    order: [['title', 'ASC']]
  });
};

module.exports = Course;
EOF

# ===========================================
# 7. CONTROLLERS/AUTHCONTROLLER.JS
# ===========================================
echo "🔐 Creando controllers/authController.js..."
cat > controllers/authController.js << 'EOF'
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
EOF

# ===========================================
# 8. MIDDLEWARE/AUTH.JS
# ===========================================
echo "🔒 Creando middleware/auth.js..."
cat > middleware/auth.js << 'EOF'
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
EOF

# ===========================================
# 9. DATABASE/INIT.SQL
# ===========================================
echo "🗄️ Creando database/init.sql..."
cat > database/init.sql << 'EOF'
-- Script de inicialización para la base de datos de la plataforma educativa

-- Crear base de datos
CREATE DATABASE IF NOT EXISTS learning_platform 
CHARACTER SET utf8mb4 
COLLATE utf8mb4_unicode_ci;

USE learning_platform;

-- Configurar zona horaria para Colombia
SET time_zone = '-05:00';

-- Crear usuario administrador inicial
INSERT IGNORE INTO users (
    email, 
    password, 
    first_name, 
    last_name, 
    role, 
    is_active,
    created_at,
    updated_at
) VALUES (
    'admin@plataforma.edu',
    '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', -- password: password
    'Administrador',
    'Sistema',
    'admin',
    true,
    NOW(),
    NOW()
);

-- Crear instructor de ejemplo
INSERT IGNORE INTO users (
    email, 
    password, 
    first_name, 
    last_name, 
    role, 
    is_active,
    created_at,
    updated_at
) VALUES (
    'instructor@plataforma.edu',
    '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', -- password: password
    'Juan',
    'Pérez',
    'instructor',
    true,
    NOW(),
    NOW()
);

-- Crear estudiante de ejemplo
INSERT IGNORE INTO users (
    email, 
    password, 
    first_name, 
    last_name, 
    role, 
    is_active,
    created_at,
    updated_at
) VALUES (
    'estudiante@plataforma.edu',
    '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', -- password: password
    'María',
    'González',
    'student',
    true,
    NOW(),
    NOW()
);

COMMIT;
EOF

# ===========================================
# 10. ROUTES BÁSICAS
# ===========================================
echo "🛣️ Creando routes/auth.js..."
cat > routes/auth.js << 'EOF'
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
EOF

echo "🛣️ Creando routes/dashboard.js..."
cat > routes/dashboard.js << 'EOF'
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
EOF

echo "🛣️ Creando routes/courses.js..."
cat > routes/courses.js << 'EOF'
const express = require('express');
const router = express.Router();

// Rutas temporales - implementar controllers después
router.get('/', (req, res) => {
  res.render('courses/index', {
    title: 'Cursos',
    courses: []
  });
});

router.get('/:id', (req, res) => {
  res.render('courses/show', {
    title: 'Detalle del Curso',
    course: { id: req.params.id, title: 'Curso de Ejemplo' }
  });
});

module.exports = router;
EOF

echo "🛣️ Creando routes/exams.js..."
cat > routes/exams.js << 'EOF'
const express = require('express');
const router = express.Router();

// Rutas temporales
router.get('/', (req, res) => {
  res.render('exams/index', {
    title: 'Exámenes',
    exams: []
  });
});

module.exports = router;
EOF

echo "🛣️ Creando routes/forum.js..."
cat > routes/forum.js << 'EOF'
const express = require('express');
const router = express.Router();

// Rutas temporales
router.get('/:courseId', (req, res) => {
  res.render('forum/index', {
    title: 'Foro',
    topics: []
  });
});

module.exports = router;
EOF

echo "🛣️ Creando routes/admin.js..."
cat > routes/admin.js << 'EOF'
const express = require('express');
const { requireAdmin } = require('../middleware/auth');
const router = express.Router();

// Aplicar middleware de admin a todas las rutas
router.use(requireAdmin);

// Dashboard admin
router.get('/dashboard', (req, res) => {
  res.render('admin/dashboard', {
    title: 'Panel de Administración',
    stats: {}
  });
});

module.exports = router;
EOF

# ===========================================
# 11. VISTAS BÁSICAS
# ===========================================
echo "👁️ Creando vistas básicas..."

# Layout principal
cat > views/layouts/main.ejs << 'EOF'
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><%= title %> | Learning Platform</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css" rel="stylesheet">
    <link href="/css/style.css" rel="stylesheet">
</head>
<body>
    <% if (user) { %>
        <%- include('../partials/navbar') %>
    <% } %>
    
    <main class="<%= user ? 'container mt-4' : 'container-fluid' %>">
        <% if (message) { %>
            <div class="alert alert-success alert-dismissible fade show" role="alert">
                <%= message %>
                <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
            </div>
        <% } %>
        
        <% if (error) { %>
            <div class="alert alert-danger alert-dismissible fade show" role="alert">
                <%= error %>
                <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
            </div>
        <% } %>
        
        <%- body %>
    </main>
    
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/js/bootstrap.bundle.min.js"></script>
    <script src="/js/main.js"></script>
</body>
</html>
EOF

# Navbar
cat > views/partials/navbar.ejs << 'EOF'
<nav class="navbar navbar-expand-lg navbar-dark bg-dark">
    <div class="container">
        <a class="navbar-brand" href="/dashboard">
            <i class="fas fa-graduation-cap"></i> Learning Platform
        </a>
        
        <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#navbarNav">
            <span class="navbar-toggler-icon"></span>
        </button>
        
        <div class="collapse navbar-collapse" id="navbarNav">
            <ul class="navbar-nav me-auto">
                <li class="nav-item">
                    <a class="nav-link" href="/dashboard">Dashboard</a>
                </li>
                <li class="nav-item">
                    <a class="nav-link" href="/courses">Cursos</a>
                </li>
                <% if (user.role === 'admin') { %>
                    <li class="nav-item">
                        <a class="nav-link" href="/admin/dashboard">Administración</a>
                    </li>
                <% } %>
            </ul>
            
            <ul class="navbar-nav">
                <li class="nav-item dropdown">
                    <a class="nav-link dropdown-toggle" href="#" id="navbarDropdown" role="button" data-bs-toggle="dropdown">
                        <i class="fas fa-user"></i> <%= user.first_name %>
                    </a>
                    <ul class="dropdown-menu">
                        <li><a class="dropdown-item" href="/auth/profile">Mi Perfil</a></li>
                        <li><hr class="dropdown-divider"></li>
                        <li><a class="dropdown-item" href="/auth/logout">Cerrar Sesión</a></li>
                    </ul>
                </li>
            </ul>
        </div>
    </div>
</nav>
EOF

# Página de inicio
cat > views/index.ejs << 'EOF'
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><%= title %></title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css" rel="stylesheet">
</head>
<body class="bg-light">
    <div class="container-fluid vh-100 d-flex align-items-center justify-content-center">
        <div class="row w-100">
            <div class="col-md-6 offset-md-3">
                <div class="card shadow">
                    <div class="card-body text-center p-5">
                        <h1 class="display-4 text-primary mb-4">
                            <i class="fas fa-graduation-cap"></i> Learning Platform
                        </h1>
                        <p class="lead mb-4">Plataforma educativa para cursos de redes y seguridad informática</p>
                        <div class="d-grid gap-2 d-md-flex justify-content-md-center">
                            <a href="/auth/login" class="btn btn-primary btn-lg me-md-2">
                                <i class="fas fa-sign-in-alt"></i> Iniciar Sesión
                            </a>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</body>
</html>
EOF

# Login
cat > views/auth/login.ejs << 'EOF'
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><%= title %></title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css" rel="stylesheet">
</head>
<body class="bg-light">
    <div class="container-fluid vh-100 d-flex align-items-center justify-content-center">
        <div class="row w-100">
            <div class="col-md-4 offset-md-4">
                <div class="card shadow">
                    <div class="card-body p-5">
                        <h2 class="text-center mb-4">
                            <i class="fas fa-sign-in-alt"></i> Iniciar Sesión
                        </h2>
                        
                        <% if (error) { %>
                            <div class="alert alert-danger" role="alert">
                                <%= error %>
                            </div>
                        <% } %>
                        
                        <form method="POST" action="/auth/login">
                            <div class="mb-3">
                                <label for="email" class="form-label">Email:</label>
                                <input type="email" class="form-control" id="email" name="email" value="<%= email %>" required>
                            </div>
                            
                            <div class="mb-3">
                                <label for="password" class="form-label">Contraseña:</label>
                                <input type="password" class="form-control" id="password" name="password" required>
                            </div>
                            
                            <div class="d-grid">
                                <button type="submit" class="btn btn-primary">
                                    <i class="fas fa-sign-in-alt"></i> Iniciar Sesión
                                </button>
                            </div>
                        </form>
                        
                        <div class="text-center mt-3">
                            <a href="/" class="text-decoration-none">
                                <i class="fas fa-arrow-left"></i> Volver al inicio
                            </a>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</body>
</html>
EOF

# Error page
cat > views/error.ejs << 'EOF'
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><%= title %></title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css" rel="stylesheet">
</head>
<body class="bg-light">
    <div class="container-fluid vh-100 d-flex align-items-center justify-content-center">
        <div class="row w-100">
            <div class="col-md-6 offset-md-3">
                <div class="card shadow">
                    <div class="card-body text-center p-5">
                        <h1 class="display-1 text-danger"><%= code %></h1>
                        <h2 class="mb-4"><%= title %></h2>
                        <p class="lead mb-4"><%= error %></p>
                        <div class="d-grid gap-2 d-md-flex justify-content-md-center">
                            <a href="/" class="btn btn-primary btn-lg me-md-2">
                                <i class="fas fa-home"></i> Volver al inicio
                            </a>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</body>
</html>
EOF

# Dashboard básico
cat > views/dashboard/student.ejs << 'EOF'
<% layout('layouts/main') -%>

<div class="row">
    <div class="col-12">
        <h1>Bienvenido, <%= user.first_name %>!</h1>
        <p class="lead">Dashboard del estudiante</p>
        
        <div class="row">
            <div class="col-md-6">
                <div class="card">
                    <div class="card-body">
                        <h5 class="card-title">Mis Cursos</h5>
                        <p class="card-text">Accede a tus cursos matriculados</p>
                        <a href="/courses" class="btn btn-primary">Ver Cursos</a>
                    </div>
                </div>
            </div>
            
            <div class="col-md-6">
                <div class="card">
                    <div class="card-body">
                        <h5 class="card-title">Progreso</h5>
                        <p class="card-text">Revisa tu progreso académico</p>
                        <a href="/progress" class="btn btn-info">Ver Progreso</a>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>
EOF

# CSS básico
cat > public/css/style.css << 'EOF'
body {
    font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
}

.navbar-brand {
    font-weight: bold;
}

.card {
    border: none;
    box-shadow: 0 0.125rem 0.25rem rgba(0, 0, 0, 0.075);
    transition: box-shadow 0.15s ease-in-out;
}

.card:hover {
    box-shadow: 0 0.5rem 1rem rgba(0, 0, 0, 0.15);
}

.btn {
    border-radius: 0.375rem;
}

.alert {
    border-radius: 0.375rem;
}

.form-control {
    border-radius: 0.375rem;
}

.bg-primary {
    background-color: #0d6efd !important;
}

.text-primary {
    color: #0d6efd !important;
}
EOF

# JS básico
cat > public/js/main.js << 'EOF'
// JavaScript principal de la aplicación
document.addEventListener('DOMContentLoaded', function() {
    // Auto-hide alerts después de 5 segundos
    const alerts = document.querySelectorAll('.alert');
    alerts.forEach(alert => {
        setTimeout(() => {
            const bsAlert = new bootstrap.Alert(alert);
            bsAlert.close();
        }, 5000);
    });
});
EOF

# Crear archivos .gitkeep para directorios vacíos
touch uploads/.gitkeep
touch uploads/courses/.gitkeep
touch uploads/videos/.gitkeep
touch uploads/profiles/.gitkeep
touch public/images/.gitkeep
touch tests/.gitkeep

echo "✅ ¡Todos los archivos creados exitosamente!"
echo ""
echo "📋 Archivos creados:"
echo "   ✓ package.json"
echo "   ✓ server.js"
echo "   ✓ .env.example"
echo "   ✓ config/database.js"
echo "   ✓ models/User.js"
echo "   ✓ models/Course.js"
echo "   ✓ controllers/authController.js"
echo "   ✓ middleware/auth.js"
echo "   ✓ routes/ (todas las rutas básicas)"
echo "   ✓ views/ (vistas básicas con Bootstrap)"
echo "   ✓ database/init.sql"
echo "   ✓ public/css/style.css"
echo "   ✓ public/js/main.js"
echo ""
echo "🚀 Próximos pasos:"
echo "1. cp .env.example .env"
echo "2. npm install"
echo "3. Configurar tu base de datos en .env"
echo "4. Crear la BD: mysql -u root -p -e 'CREATE DATABASE learning_platform'"
echo "5. npm run dev"
echo ""
echo "👤 Usuarios por defecto:"
echo "   Admin: admin@plataforma.edu / password"
echo "   Instructor: instructor@plataforma.edu / password"
echo "   Estudiante: estudiante@plataforma.edu / password"
EOF

echo "🎯 ¡Script create-files.sh creado exitosamente!"
echo ""
echo "📋 Para usar el script:"
echo "1. git clone https://github.com/horaciokar/backnet.git"
echo "2. cd backnet"
echo "3. bash create-files.sh"
echo "4. cp .env.example .env"
echo "5. npm install"
echo "6. npm run dev"
echo ""
echo "🚀 El script creará automáticamente TODOS los archivos del proyecto!"