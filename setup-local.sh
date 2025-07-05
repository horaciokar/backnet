#!/bin/bash

# Script para configurar MySQL local en EC2 Ubuntu
echo "🗄️ Configurando MySQL local en EC2..."

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

# Verificar si se ejecuta con privilegios de sudo
if [ "$EUID" -eq 0 ]; then
    print_error "No ejecutes este script como root. Usa tu usuario ubuntu."
    exit 1
fi

# 1. ACTUALIZAR SISTEMA
print_status "Actualizando sistema..."
sudo apt update

# 2. INSTALAR MYSQL SERVER
print_status "Instalando MySQL Server..."
sudo apt install -y mysql-server

# 3. VERIFICAR QUE MYSQL ESTÉ CORRIENDO
print_status "Verificando estado de MySQL..."
sudo systemctl start mysql
sudo systemctl enable mysql

# Esperar un momento para que MySQL arranque completamente
sleep 5

# 4. CONFIGURAR MYSQL DE FORMA SEGURA
print_status "Configurando MySQL..."

# Configurar contraseña root y seguridad básica
sudo mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'rootpassword123';"
sudo mysql -e "DELETE FROM mysql.user WHERE User='';"
sudo mysql -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
sudo mysql -e "DROP DATABASE IF EXISTS test;"
sudo mysql -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';"
sudo mysql -e "FLUSH PRIVILEGES;"

print_status "✅ MySQL configurado con contraseña: rootpassword123"

# 5. CREAR BASE DE DATOS Y USUARIO PARA LA APLICACIÓN
print_status "Creando base de datos y usuario para la aplicación..."

mysql -u root -p'rootpassword123' << 'EOF'
-- Crear base de datos
CREATE DATABASE IF NOT EXISTS learning_platform CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Crear usuario específico para la aplicación
CREATE USER IF NOT EXISTS 'appuser'@'localhost' IDENTIFIED BY 'apppassword123';

-- Dar permisos completos al usuario en la base de datos
GRANT ALL PRIVILEGES ON learning_platform.* TO 'appuser'@'localhost';

-- Aplicar cambios
FLUSH PRIVILEGES;

-- Mostrar bases de datos creadas
SHOW DATABASES;

-- Mostrar usuarios creados
SELECT User, Host FROM mysql.user WHERE User IN ('root', 'appuser');
EOF

if [ $? -eq 0 ]; then
    print_status "✅ Base de datos y usuario creados exitosamente"
else
    print_error "❌ Error creando base de datos"
    exit 1
fi

# 6. ACTUALIZAR ARCHIVO .env
print_status "Actualizando archivo .env para MySQL local..."

# Hacer backup del .env actual
cp .env .env.rds.backup

# Crear nuevo .env para MySQL local
cat > .env << 'EOF'
# Configuración del servidor
NODE_ENV=development
PORT=3000

# Base de datos MySQL LOCAL
DB_HOST=localhost
DB_PORT=3306
DB_NAME=learning_platform
DB_USER=appuser
DB_PASSWORD=apppassword123

# Seguridad
JWT_SECRET=tu-jwt-secret-muy-largo-y-seguro-para-desarrollo-12345
SESSION_SECRET=tu-session-secret-muy-largo-y-seguro-para-desarrollo-12345

# Upload limits
MAX_FILE_SIZE=10485760
UPLOAD_PATH=./uploads

# Rate limiting
RATE_LIMIT_WINDOW=900000
RATE_LIMIT_MAX=100
EOF

print_status "✅ Archivo .env actualizado para MySQL local"

# 7. PROBAR CONEXIÓN
print_status "Probando conexión a MySQL local..."
mysql -u appuser -p'apppassword123' learning_platform -e "SELECT 'Conexión exitosa' as status, NOW() as timestamp;"

if [ $? -eq 0 ]; then
    print_status "✅ Conexión a MySQL local exitosa"
else
    print_error "❌ Error en conexión a MySQL local"
    exit 1
fi

# 8. IMPORTAR ESTRUCTURA DE BASE DE DATOS
print_status "Importando estructura de base de datos..."

# Verificar si existe el script de inicialización
if [ -f "database/init_fixed.sql" ]; then
    DB_SCRIPT="database/init_fixed.sql"
elif [ -f "database/init.sql" ]; then
    DB_SCRIPT="database/init.sql"
else
    print_warning "Script de BD no encontrado. Creando uno básico..."
    
    mkdir -p database
    cat > database/init_local.sql << 'EOF'
-- Script de inicialización para Learning Platform LOCAL

-- Crear tabla de usuarios
CREATE TABLE IF NOT EXISTS users (
    id INT PRIMARY KEY AUTO_INCREMENT,
    email VARCHAR(100) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    role ENUM('admin', 'instructor', 'student') DEFAULT 'student',
    is_active BOOLEAN DEFAULT TRUE,
    profile_picture VARCHAR(255),
    last_login TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Crear tabla de cursos
CREATE TABLE IF NOT EXISTS courses (
    id INT PRIMARY KEY AUTO_INCREMENT,
    title VARCHAR(100) NOT NULL,
    description TEXT NOT NULL,
    short_description VARCHAR(255),
    duration_hours INT DEFAULT 0,
    difficulty_level ENUM('beginner', 'intermediate', 'advanced') DEFAULT 'beginner',
    category ENUM('networks', 'security', 'both') DEFAULT 'both',
    thumbnail VARCHAR(255),
    is_active BOOLEAN DEFAULT TRUE,
    is_public BOOLEAN DEFAULT FALSE,
    max_students INT,
    created_by INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_created_by (created_by),
    INDEX idx_active (is_active),
    INDEX idx_category (category)
);

-- Crear tabla de unidades de curso
CREATE TABLE IF NOT EXISTS course_units (
    id INT PRIMARY KEY AUTO_INCREMENT,
    course_id INT NOT NULL,
    title VARCHAR(100) NOT NULL,
    description TEXT,
    content TEXT,
    order_number INT NOT NULL,
    content_type ENUM('text', 'video', 'pdf', 'lab', 'mixed') DEFAULT 'text',
    video_url VARCHAR(255),
    duration_minutes INT DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_course_id (course_id),
    INDEX idx_order (course_id, order_number)
);

-- Crear tabla de matrículas
CREATE TABLE IF NOT EXISTS enrollments (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    course_id INT NOT NULL,
    enrolled_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    progress INT DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_user_id (user_id),
    INDEX idx_course_id (course_id),
    UNIQUE KEY unique_enrollment (user_id, course_id)
);

-- Insertar usuarios por defecto
INSERT IGNORE INTO users (email, password, first_name, last_name, role) VALUES 
('admin@plataforma.edu', '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'Admin', 'Sistema', 'admin'),
('instructor@plataforma.edu', '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'Juan', 'Pérez', 'instructor'),
('estudiante@plataforma.edu', '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'María', 'González', 'student');

-- Insertar curso de ejemplo
INSERT IGNORE INTO courses (title, description, short_description, duration_hours, difficulty_level, category, is_active, is_public, created_by) VALUES 
('Fundamentos de Redes', 'Curso completo sobre fundamentos de redes de computadoras', 'Aprende redes desde cero', 40, 'beginner', 'networks', TRUE, TRUE, 1);

-- Insertar unidad de ejemplo
INSERT IGNORE INTO course_units (course_id, title, description, order_number, content_type, video_url, duration_minutes) VALUES 
(1, 'Introducción a las Redes', 'Conceptos básicos de redes', 1, 'video', 'https://www.youtube.com/watch?v=3QhU9jd03a0', 45);

COMMIT;
EOF
    
    DB_SCRIPT="database/init_local.sql"
fi

# Importar script
print_status "Importando $DB_SCRIPT..."
mysql -u appuser -p'apppassword123' learning_platform < $DB_SCRIPT

if [ $? -eq 0 ]; then
    print_status "✅ Estructura de BD importada exitosamente"
else
    print_error "❌ Error importando estructura de BD"
fi

# 9. VERIFICAR DATOS IMPORTADOS
print_status "Verificando datos importados..."
echo "📋 Tablas en la base de datos:"
mysql -u appuser -p'apppassword123' learning_platform -e "SHOW TABLES;"

echo ""
echo "👤 Usuarios creados:"
mysql -u appuser -p'apppassword123' learning_platform -e "SELECT id, email, first_name, last_name, role FROM users;"

echo ""
echo "📚 Cursos creados:"
mysql -u appuser -p'apppassword123' learning_platform -e "SELECT id, title, category FROM courses;"

# 10. CREAR SCRIPTS DE UTILIDAD
print_status "Creando scripts de utilidad..."

cat > connect-local-mysql.sh << 'EOF'
#!/bin/bash
# Script para conectar a MySQL local
echo "🔗 Conectando a MySQL local..."
echo "Base de datos: learning_platform"
echo "Usuario: appuser"
echo ""
mysql -u appuser -p'apppassword123' learning_platform
EOF
chmod +x connect-local-mysql.sh

cat > backup-local-db.sh << 'EOF'
#!/bin/bash
# Script para hacer backup de BD local
echo "💾 Creando backup de base de datos local..."
mysqldump -u appuser -p'apppassword123' learning_platform > backup_$(date +%Y%m%d_%H%M%S).sql
echo "✅ Backup creado: backup_$(date +%Y%m%d_%H%M%S).sql"
EOF
chmod +x backup-local-db.sh

cat > restore-to-rds.sh << 'EOF'
#!/bin/bash
# Script para migrar BD local a RDS (para el futuro)
echo "🔄 Script para migrar a RDS (configurar variables primero)"
echo ""
echo "1. Hacer backup local:"
echo "   ./backup-local-db.sh"
echo ""
echo "2. Configurar variables RDS:"
echo "   RDS_HOST=tu-rds-endpoint"
echo "   RDS_USER=admin"
echo "   RDS_PASS=tu-password"
echo ""
echo "3. Restaurar en RDS:"
echo "   mysql -h \$RDS_HOST -u \$RDS_USER -p\$RDS_PASS learning_platform < backup_file.sql"
EOF
chmod +x restore-to-rds.sh

# 11. PROBAR APLICACIÓN
print_status "Probando aplicación con MySQL local..."

# Crear script de test
cat > test-local-app.sh << 'EOF'
#!/bin/bash
echo "�� Probando aplicación con MySQL local..."
echo ""
echo "🔍 Verificando conexión a BD..."
mysql -u appuser -p'apppassword123' learning_platform -e "SELECT 'BD Local Funciona' as status;"
echo ""
echo "🚀 Iniciando aplicación..."
echo "👤 Usuarios disponibles:"
echo "   admin@plataforma.edu / password"
echo "   instructor@plataforma.edu / password"
echo "   estudiante@plataforma.edu / password"
echo ""
echo "🌐 Aplicación disponible en: http://$(curl -s ifconfig.me):3000"
echo ""
npm run dev
EOF
chmod +x test-local-app.sh

print_status "✅ MySQL local configurado completamente!"
echo ""
echo "🎯 Resumen de configuración:"
echo "   Base de datos: learning_platform"
echo "   Usuario: appuser"
echo "   Contraseña: apppassword123"
echo "   Host: localhost"
echo ""
echo "📋 Archivos de configuración:"
echo "   ✓ .env - Actualizado para MySQL local"
echo "   ✓ .env.rds.backup - Backup de configuración RDS"
echo ""
echo "🔧 Scripts disponibles:"
echo "   ./connect-local-mysql.sh - Conectar a BD local"
echo "   ./backup-local-db.sh - Hacer backup"
echo "   ./test-local-app.sh - Probar aplicación"
echo "   ./restore-to-rds.sh - Migrar a RDS (futuro)"
echo ""
echo "🚀 Para probar la aplicación:"
echo "   ./test-local-app.sh"
echo ""
echo "👤 Usuarios por defecto:"
echo "   Admin: admin@plataforma.edu / password"
echo "   Instructor: instructor@plataforma.edu / password"
echo "   Estudiante: estudiante@plataforma.edu / password"
echo ""
print_warning "⚠️  Contraseña root MySQL: rootpassword123"
print_warning "⚠️  Para volver a RDS: cp .env.rds.backup .env"
