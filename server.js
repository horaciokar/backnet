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
