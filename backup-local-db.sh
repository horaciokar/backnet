#!/bin/bash
# Script para hacer backup de BD local
echo "💾 Creando backup de base de datos local..."
mysqldump -u appuser -p'apppassword123' learning_platform > backup_$(date +%Y%m%d_%H%M%S).sql
echo "✅ Backup creado: backup_$(date +%Y%m%d_%H%M%S).sql"
