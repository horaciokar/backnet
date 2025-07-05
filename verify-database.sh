#!/bin/bash
echo "🔍 Verificando estado de la base de datos..."
echo ""
echo "📊 Estadísticas:"
mysql -u appuser -p'apppassword123' learning_platform -e "
SELECT 
    'users' as tabla, COUNT(*) as registros FROM users
UNION ALL SELECT 
    'courses' as tabla, COUNT(*) as registros FROM courses
UNION ALL SELECT 
    'course_units' as tabla, COUNT(*) as registros FROM course_units
UNION ALL SELECT 
    'enrollments' as tabla, COUNT(*) as registros FROM enrollments
UNION ALL SELECT 
    'questions' as tabla, COUNT(*) as registros FROM questions;
"
echo ""
echo "✅ Base de datos verificada"
