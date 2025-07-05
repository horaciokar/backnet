#!/bin/bash

# Script para desactivar rate limiting en desarrollo
echo "🚀 Desactivando rate limiting para desarrollo..."

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

# 1. ACTUALIZAR SERVER.JS PARA DESACTIVAR RATE LIMITING EN DESARROLLO
print_status "Actualizando server.js para desactivar rate limiting..."
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

console.log(`🌍 Entorno: ${process.env.NODE_ENV || 'development'}`);

// Rate limiting SOLO EN PRODUCCIÓN
if (process.env.NODE_ENV === 'production') {
    const limiter = rateLimit({
        windowMs: 15 * 60 * 1000, // 15 minutos
        max: 100, // máximo 100 requests por IP
        message: 'Demasiadas solicitudes, intenta de nuevo más tarde.'
    });
    app.use(limiter);
    console.log('🔒 Rate limiting habilitado para producción');
} else {
    console.log('🔓 Rate limiting DESHABILITADO para desarrollo');
}

// Middleware de seguridad - relajado para desarrollo
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
    // Configuración muy permisiva para desarrollo
    app.use(helmet({
        contentSecurityPolicy: false,
        crossOriginEmbedderPolicy: false
    }));
    console.log('🔓 Políticas de seguridad relajadas para desarrollo');
}

app.use(compression());

// Logging diferente según entorno
if (process.env.NODE_ENV === 'production') {
    app.use(morgan('combined'));
} else {
    app.use(morgan('dev'));
}

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

// Ruta de status para desarrollo
app.get('/status', (req, res) => {
    res.json({
        status: 'OK',
        environment: process.env.NODE_ENV || 'development',
        rateLimiting: process.env.NODE_ENV === 'production',
        timestamp: new Date().toISOString(),
        uptime: process.uptime()
    });
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
    console.log(`📊 Status: http://0.0.0.0:${PORT}/status`);
    console.log(`🔧 Modo: ${process.env.NODE_ENV || 'development'}`);
});

module.exports = app;
EOF

# 2. ASEGURAR QUE NODE_ENV ESTÉ EN DEVELOPMENT
print_status "Configurando variables de entorno..."
if grep -q "NODE_ENV=" .env; then
    sed -i 's/NODE_ENV=.*/NODE_ENV=development/' .env
else
    echo "NODE_ENV=development" >> .env
fi

# 3. CREAR SCRIPT PARA LIMPIAR RATE LIMITING
print_status "Creando script para gestionar rate limiting..."
cat > manage-rate-limit.sh << 'EOF'
#!/bin/bash

# Script para gestionar rate limiting
case "$1" in
    "off"|"disable")
        echo "🔓 Deshabilitando rate limiting..."
        sed -i 's/NODE_ENV=.*/NODE_ENV=development/' .env
        echo "✅ Rate limiting deshabilitado"
        echo "🔄 Reinicia la aplicación: npm run dev"
        ;;
    "on"|"enable")
        echo "🔒 Habilitando rate limiting..."
        sed -i 's/NODE_ENV=.*/NODE_ENV=production/' .env
        echo "✅ Rate limiting habilitado"
        echo "🔄 Reinicia la aplicación: npm run dev"
        ;;
    "status")
        NODE_ENV=$(grep NODE_ENV .env | cut -d '=' -f2)
        if [ "$NODE_ENV" = "production" ]; then
            echo "🔒 Rate limiting: HABILITADO"
        else
            echo "🔓 Rate limiting: DESHABILITADO"
        fi
        ;;
    *)
        echo "Uso: $0 {on|off|status}"
        echo ""
        echo "Comandos:"
        echo "  on/enable  - Habilitar rate limiting"
        echo "  off/disable - Deshabilitar rate limiting"
        echo "  status     - Ver estado actual"
        exit 1
        ;;
esac
EOF
chmod +x manage-rate-limit.sh

# 4. CREAR SCRIPT DE RESTART RÁPIDO
print_status "Creando script de restart rápido..."
cat > quick-restart.sh << 'EOF'
#!/bin/bash
echo "🔄 Reinicio rápido de la aplicación..."

# Matar procesos de Node.js relacionados con el proyecto
pkill -f "node.*server.js" 2>/dev/null || true
pkill -f "nodemon.*server.js" 2>/dev/null || true

# Esperar un momento
sleep 2

# Verificar que NODE_ENV esté en development
if ! grep -q "NODE_ENV=development" .env; then
    echo "NODE_ENV=development" >> .env
fi

echo "🚀 Iniciando aplicación sin rate limiting..."
npm run dev
EOF
chmod +x quick-restart.sh

# 5. VERIFICAR CONFIGURACIÓN ACTUAL
print_status "Verificando configuración actual..."
echo "📋 Variables de entorno:"
grep NODE_ENV .env || echo "NODE_ENV no configurado - se usará 'development'"

echo ""
echo "🔧 Estado del rate limiting:"
NODE_ENV=$(grep NODE_ENV .env 2>/dev/null | cut -d '=' -f2 || echo "development")
if [ "$NODE_ENV" = "production" ]; then
    echo "🔒 Rate limiting: HABILITADO"
else
    echo "🔓 Rate limiting: DESHABILITADO"
fi

print_status "✅ Rate limiting configurado para desarrollo!"
echo ""
echo "🎯 Cambios realizados:"
echo "   ✓ Rate limiting DESHABILITADO en desarrollo"
echo "   ✓ Políticas de seguridad relajadas"
echo "   ✓ Logging mejorado para debug"
echo "   ✓ Ruta /status para monitoreo"
echo ""
echo "🚀 Para aplicar cambios:"
echo "   ./quick-restart.sh"
echo ""
echo "🔧 Scripts disponibles:"
echo "   ./manage-rate-limit.sh off  - Deshabilitar rate limiting"
echo "   ./manage-rate-limit.sh on   - Habilitar rate limiting"
echo "   ./manage-rate-limit.sh status - Ver estado"
echo "   ./quick-restart.sh          - Reinicio rápido"
echo ""
echo "📊 Monitoreo:"
echo "   http://tu-ip:3000/status - Estado de la aplicación"
echo ""
print_warning "⚠️  Ahora puedes probar todas las rutas sin límites"