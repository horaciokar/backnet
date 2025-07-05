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
