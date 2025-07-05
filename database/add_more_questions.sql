-- Agregar más preguntas para tener exámenes más completos
USE learning_platform;

-- Más preguntas para el examen de Introducción a Redes
INSERT IGNORE INTO questions (exam_id, question_text, option_a, option_b, option_c, option_d, correct_answer, explanation, order_number, difficulty) VALUES 
(1, '¿Cuál es la principal diferencia entre un switch y un hub?', 'El switch es más barato', 'El switch opera en la capa de enlace', 'El hub es más rápido', 'No hay diferencia', 'B', 'Un switch opera en la capa 2 (enlace de datos) mientras que un hub opera en la capa 1 (física).', 4, 'medium'),
(1, '¿Qué significa IP en redes?', 'Internal Protocol', 'Internet Protocol', 'Information Protocol', 'Interface Protocol', 'B', 'IP significa Internet Protocol, el protocolo fundamental de Internet.', 5, 'easy'),
(1, '¿Cuál es el rango de direcciones IP privadas de clase A?', '10.0.0.0 - 10.255.255.255', '172.16.0.0 - 172.31.255.255', '192.168.0.0 - 192.168.255.255', '127.0.0.0 - 127.255.255.255', 'A', 'El rango 10.0.0.0/8 es para direcciones privadas de clase A.', 6, 'medium'),
(1, '¿Qué protocolo se utiliza para resolución de nombres de dominio?', 'HTTP', 'FTP', 'DNS', 'SMTP', 'C', 'DNS (Domain Name System) se utiliza para resolver nombres de dominio a direcciones IP.', 7, 'easy'),
(1, '¿Cuál es la máscara de subred por defecto para una red clase C?', '255.0.0.0', '255.255.0.0', '255.255.255.0', '255.255.255.255', 'C', 'La máscara por defecto para clase C es 255.255.255.0 o /24.', 8, 'medium'),
(1, '¿Qué puerto utiliza por defecto el protocolo HTTP?', '21', '23', '80', '443', 'C', 'HTTP utiliza el puerto 80 por defecto.', 9, 'easy'),
(1, '¿Cuál es la función principal de un firewall?', 'Amplificar señales', 'Controlar el tráfico de red', 'Convertir protocolos', 'Almacenar datos', 'B', 'Un firewall controla el tráfico de red basándose en reglas de seguridad.', 10, 'medium');

-- Más preguntas para el examen del Modelo OSI
INSERT IGNORE INTO questions (exam_id, question_text, option_a, option_b, option_c, option_d, correct_answer, explanation, order_number, difficulty) VALUES 
(2, '¿Cuántas capas tiene el modelo OSI?', '5', '6', '7', '8', 'C', 'El modelo OSI tiene 7 capas: Física, Enlace, Red, Transporte, Sesión, Presentación y Aplicación.', 1, 'easy'),
(2, '¿En qué capa del modelo OSI operan los switches?', 'Capa 1', 'Capa 2', 'Capa 3', 'Capa 4', 'B', 'Los switches operan en la capa 2 (Enlace de datos) del modelo OSI.', 2, 'medium'),
(2, '¿Cuál es la capa más alta del modelo OSI?', 'Transporte', 'Sesión', 'Presentación', 'Aplicación', 'D', 'La capa de Aplicación (capa 7) es la más alta del modelo OSI.', 3, 'easy'),
(2, '¿Qué capa se encarga del ruteo de paquetes?', 'Capa 2', 'Capa 3', 'Capa 4', 'Capa 5', 'B', 'La capa de Red (capa 3) se encarga del ruteo de paquetes.', 4, 'medium'),
(2, '¿En qué capa operan los routers?', 'Capa 1', 'Capa 2', 'Capa 3', 'Capa 4', 'C', 'Los routers operan en la capa 3 (Red) del modelo OSI.', 5, 'medium'),
(2, '¿Cuál es la función principal de la capa de Transporte?', 'Ruteo', 'Control de flujo', 'Encriptación', 'Presentación', 'B', 'La capa de Transporte se encarga del control de flujo y la entrega confiable de datos.', 6, 'medium'),
(2, '¿Qué protocolo opera en la capa de Transporte?', 'IP', 'TCP', 'ARP', 'DNS', 'B', 'TCP (Transmission Control Protocol) opera en la capa de Transporte.', 7, 'medium'),
(2, '¿Cuál es la capa más baja del modelo OSI?', 'Enlace', 'Física', 'Red', 'Aplicación', 'B', 'La capa Física (capa 1) es la más baja del modelo OSI.', 8, 'easy'),
(2, '¿Qué capa se encarga de la compresión de datos?', 'Aplicación', 'Presentación', 'Sesión', 'Transporte', 'B', 'La capa de Presentación se encarga de la compresión y encriptación de datos.', 9, 'medium'),
(2, '¿En qué capa se establecen las sesiones?', 'Capa 4', 'Capa 5', 'Capa 6', 'Capa 7', 'B', 'La capa de Sesión (capa 5) se encarga de establecer, mantener y terminar sesiones.', 10, 'medium');

-- Más preguntas para el examen de TCP/IP
INSERT IGNORE INTO questions (exam_id, question_text, option_a, option_b, option_c, option_d, correct_answer, explanation, order_number, difficulty) VALUES 
(3, '¿Cuál es la principal diferencia entre TCP y UDP?', 'TCP es más rápido', 'UDP es confiable', 'TCP es confiable', 'No hay diferencia', 'C', 'TCP es un protocolo confiable que garantiza la entrega, mientras que UDP es no confiable pero más rápido.', 1, 'medium'),
(3, '¿Qué significa TCP?', 'Transfer Control Protocol', 'Transmission Control Protocol', 'Transport Control Protocol', 'Terminal Control Protocol', 'B', 'TCP significa Transmission Control Protocol.', 2, 'easy'),
(3, '¿En qué capa del modelo OSI opera TCP?', 'Capa 3', 'Capa 4', 'Capa 5', 'Capa 6', 'B', 'TCP opera en la capa 4 (Transporte) del modelo OSI.', 3, 'medium'),
(3, '¿Cuál es el tamaño máximo de una dirección IPv4?', '16 bits', '32 bits', '64 bits', '128 bits', 'B', 'Una dirección IPv4 tiene un tamaño de 32 bits.', 4, 'medium'),
(3, '¿Qué protocolo se utiliza para obtener direcciones IP automáticamente?', 'ARP', 'DHCP', 'DNS', 'NAT', 'B', 'DHCP (Dynamic Host Configuration Protocol) asigna direcciones IP automáticamente.', 5, 'medium'),
(3, '¿Cuál es el protocolo de la capa de red en TCP/IP?', 'TCP', 'UDP', 'IP', 'HTTP', 'C', 'IP (Internet Protocol) es el protocolo de la capa de red en la suite TCP/IP.', 6, 'easy'),
(3, '¿Qué puerto utiliza por defecto HTTPS?', '80', '443', '21', '23', 'B', 'HTTPS utiliza el puerto 443 por defecto.', 7, 'easy'),
(3, '¿Cuál es la función del protocolo ARP?', 'Ruteo', 'Resolución de direcciones', 'Control de flujo', 'Encriptación', 'B', 'ARP (Address Resolution Protocol) resuelve direcciones IP a direcciones MAC.', 8, 'medium'),
(3, '¿Qué significa UDP?', 'User Datagram Protocol', 'Universal Data Protocol', 'Unified Datagram Protocol', 'User Data Protocol', 'A', 'UDP significa User Datagram Protocol.', 9, 'easy'),
(3, '¿Cuál es la ventaja principal de UDP sobre TCP?', 'Mayor confiabilidad', 'Mayor velocidad', 'Mejor seguridad', 'Menor complejidad', 'B', 'UDP es más rápido que TCP porque no tiene mecanismos de control de flujo ni retransmisión.', 10, 'medium');

COMMIT;
