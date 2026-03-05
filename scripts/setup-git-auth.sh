#!/bin/bash

# Script para configurar autenticación GitHub con Token
# Uso: ./scripts/setup-git-auth.sh

echo "🔧 Configuración de Autenticación GitHub"
echo ""
echo "GitHub ya no permite contraseñas. Necesitas un Token de Acceso Personal."
echo ""
echo "Pasos:"
echo "1. Ve a: https://github.com/settings/tokens"
echo "2. Click 'Generate new token (classic)'"
echo "3. Selecciona scope: 'repo' (acceso completo a repositorios)"
echo "4. Genera y COPIA el token (empieza con ghp_)"
echo ""
echo "Luego ejecuta:"
echo "git remote set-url origin https://TOKEN@github.com/elnemito001/Yoltec.git"
echo ""
echo "Reemplaza TOKEN con tu token real."
echo ""
echo "Finalmente:"
echo "git push origin main"
