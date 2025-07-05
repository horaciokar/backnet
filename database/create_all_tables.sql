-- Script completo para crear todas las tablas

-- Usar la base de datos
USE learning_platform;

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

-- Crear tabla de códigos de matrícula
CREATE TABLE IF NOT EXISTS enrollment_codes (
    id INT PRIMARY KEY AUTO_INCREMENT,
    course_id INT NOT NULL,
    code VARCHAR(20) UNIQUE NOT NULL,
    max_uses INT DEFAULT 50,
    used_count INT DEFAULT 0,
    expires_at TIMESTAMP NULL,
    created_by INT NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_course_id (course_id),
    INDEX idx_code (code)
);

-- Crear tabla de instructores de curso
CREATE TABLE IF NOT EXISTS course_instructors (
    id INT PRIMARY KEY AUTO_INCREMENT,
    course_id INT NOT NULL,
    user_id INT NOT NULL,
    assigned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    assigned_by INT NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_course_id (course_id),
    INDEX idx_user_id (user_id),
    UNIQUE KEY unique_instructor (course_id, user_id)
);

-- Crear tabla de exámenes
CREATE TABLE IF NOT EXISTS exams (
    id INT PRIMARY KEY AUTO_INCREMENT,
    unit_id INT NOT NULL,
    title VARCHAR(100) NOT NULL,
    description TEXT,
    questions_count INT DEFAULT 10,
    passing_score INT DEFAULT 70,
    time_limit_minutes INT DEFAULT 30,
    max_attempts INT DEFAULT 3,
    shuffle_questions BOOLEAN DEFAULT TRUE,
    shuffle_options BOOLEAN DEFAULT TRUE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_unit_id (unit_id)
);

-- Crear tabla de preguntas
CREATE TABLE IF NOT EXISTS questions (
    id INT PRIMARY KEY AUTO_INCREMENT,
    exam_id INT NOT NULL,
    question_text TEXT NOT NULL,
    option_a VARCHAR(255) NOT NULL,
    option_b VARCHAR(255) NOT NULL,
    option_c VARCHAR(255) NOT NULL,
    option_d VARCHAR(255) NOT NULL,
    correct_answer ENUM('A', 'B', 'C', 'D') NOT NULL,
    explanation TEXT,
    order_number INT NOT NULL,
    difficulty ENUM('easy', 'medium', 'hard') DEFAULT 'medium',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_exam_id (exam_id),
    INDEX idx_order (exam_id, order_number)
);

-- Crear tabla de intentos de examen
CREATE TABLE IF NOT EXISTS exam_attempts (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    exam_id INT NOT NULL,
    started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP NULL,
    answers JSON,
    score INT,
    correct_answers INT DEFAULT 0,
    total_questions INT NOT NULL,
    passed BOOLEAN,
    time_taken_minutes INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_user_exam (user_id, exam_id),
    INDEX idx_completed (completed_at)
);

-- Crear tabla de tópicos del foro
CREATE TABLE IF NOT EXISTS forum_topics (
    id INT PRIMARY KEY AUTO_INCREMENT,
    course_id INT NOT NULL,
    user_id INT NOT NULL,
    title VARCHAR(150) NOT NULL,
    content TEXT NOT NULL,
    is_pinned BOOLEAN DEFAULT FALSE,
    is_solved BOOLEAN DEFAULT FALSE,
    is_closed BOOLEAN DEFAULT FALSE,
    views_count INT DEFAULT 0,
    replies_count INT DEFAULT 0,
    last_reply_at TIMESTAMP NULL,
    last_reply_by INT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_course_id (course_id),
    INDEX idx_user_id (user_id),
    INDEX idx_last_reply (last_reply_at)
);

-- Crear tabla de respuestas del foro
CREATE TABLE IF NOT EXISTS forum_replies (
    id INT PRIMARY KEY AUTO_INCREMENT,
    topic_id INT NOT NULL,
    user_id INT NOT NULL,
    content TEXT NOT NULL,
    reply_to INT NULL,
    is_solution BOOLEAN DEFAULT FALSE,
    likes_count INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_topic_id (topic_id),
    INDEX idx_user_id (user_id),
    INDEX idx_reply_to (reply_to)
);

-- Insertar usuarios por defecto
INSERT IGNORE INTO users (email, password, first_name, last_name, role) VALUES 
('admin@plataforma.edu', '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'Admin', 'Sistema', 'admin'),
('instructor@plataforma.edu', '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'Juan', 'Pérez', 'instructor'),
('estudiante@plataforma.edu', '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'María', 'González', 'student');

-- Insertar curso de ejemplo
INSERT IGNORE INTO courses (title, description, short_description, duration_hours, difficulty_level, category, is_active, is_public, created_by) VALUES 
('Fundamentos de Redes', 'Curso completo sobre fundamentos de redes de computadoras, incluyendo protocolos TCP/IP, routing, switching y conceptos básicos de seguridad en redes.', 'Aprende los conceptos básicos de redes de computadoras desde cero', 40, 'beginner', 'networks', TRUE, TRUE, 1);

-- Insertar unidades del curso
INSERT IGNORE INTO course_units (course_id, title, description, content, order_number, content_type, video_url, duration_minutes) VALUES 
(1, 'Introducción a las Redes', 'Conceptos básicos de redes de computadoras', 'En esta unidad aprenderás qué es una red de computadoras, los tipos de redes que existen y los componentes básicos que las conforman.', 1, 'video', 'https://www.youtube.com/watch?v=3QhU9jd03a0', 45),
(1, 'Modelo OSI', 'El modelo de interconexión de sistemas abiertos', 'El modelo OSI es fundamental para entender cómo funcionan las redes. Aprenderás las 7 capas y sus funciones.', 2, 'video', 'https://www.youtube.com/watch?v=vv4y_uOneC0', 60),
(1, 'Protocolo TCP/IP', 'Suite de protocolos TCP/IP', 'TCP/IP es la base de Internet. Aprenderás cómo funcionan estos protocolos y su importancia.', 3, 'video', 'https://www.youtube.com/watch?v=PpsEaqJV_A0', 50);

-- Insertar exámenes
INSERT IGNORE INTO exams (unit_id, title, description, questions_count, passing_score, time_limit_minutes, max_attempts) VALUES 
(1, 'Examen: Introducción a las Redes', 'Evalúa tus conocimientos sobre los conceptos básicos de redes', 10, 70, 30, 3),
(2, 'Examen: Modelo OSI', 'Evalúa tu comprensión del modelo OSI', 10, 70, 30, 3),
(3, 'Examen: Protocolo TCP/IP', 'Evalúa tus conocimientos sobre TCP/IP', 10, 70, 30, 3);

-- Insertar preguntas de ejemplo
INSERT IGNORE INTO questions (exam_id, question_text, option_a, option_b, option_c, option_d, correct_answer, explanation, order_number, difficulty) VALUES 
(1, '¿Qué significa la sigla LAN?', 'Local Area Network', 'Large Area Network', 'Limited Access Network', 'Linear Access Network', 'A', 'LAN significa Local Area Network, que es una red que conecta dispositivos en un área geográfica limitada.', 1, 'easy'),
(1, '¿Cuál es la función principal de un router?', 'Amplificar señales', 'Conectar diferentes redes', 'Almacenar datos', 'Crear copias de seguridad', 'B', 'Un router conecta diferentes redes y dirige el tráfico de datos entre ellas.', 2, 'medium'),
(1, '¿Qué protocolo se utiliza para enviar correos electrónicos?', 'HTTP', 'FTP', 'SMTP', 'DNS', 'C', 'SMTP (Simple Mail Transfer Protocol) es el protocolo estándar para enviar correos electrónicos.', 3, 'medium');

-- Asignar instructor al curso
INSERT IGNORE INTO course_instructors (course_id, user_id, assigned_by) VALUES 
(1, 2, 1);

-- Crear código de matrícula
INSERT IGNORE INTO enrollment_codes (course_id, code, max_uses, expires_at, created_by) VALUES 
(1, 'REDES2024', 100, DATE_ADD(NOW(), INTERVAL 6 MONTH), 1);

-- Matricular estudiante de ejemplo
INSERT IGNORE INTO enrollments (user_id, course_id, progress) VALUES 
(3, 1, 0);

-- Crear tópico de ejemplo en el foro
INSERT IGNORE INTO forum_topics (course_id, user_id, title, content) VALUES 
(1, 3, '¿Cuál es la diferencia entre hub y switch?', 'Hola a todos, estoy empezando con el curso y me surge esta duda. ¿Podrían explicarme cuál es la diferencia entre un hub y un switch? Gracias.');

-- Crear respuesta de ejemplo
INSERT IGNORE INTO forum_replies (topic_id, user_id, content, is_solution) VALUES 
(1, 2, 'Excelente pregunta. La principal diferencia es que un hub opera en la capa física y simplemente repite la señal a todos los puertos, mientras que un switch opera en la capa de enlace de datos y puede enviar datos específicamente al puerto de destino. Esto hace que el switch sea más eficiente y seguro.', TRUE);

-- Actualizar contadores del tópico
UPDATE forum_topics 
SET replies_count = 1, 
    last_reply_at = NOW(), 
    last_reply_by = 2,
    is_solved = TRUE
WHERE id = 1;

COMMIT;
