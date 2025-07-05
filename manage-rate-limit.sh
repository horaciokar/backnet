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
