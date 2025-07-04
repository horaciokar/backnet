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
