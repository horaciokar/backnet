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
