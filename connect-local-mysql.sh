#!/bin/bash
# Script para conectar a MySQL local
echo "🔗 Conectando a MySQL local..."
echo "Base de datos: learning_platform"
echo "Usuario: appuser"
echo ""
mysql -u appuser -p'apppassword123' learning_platform
