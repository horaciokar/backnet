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
