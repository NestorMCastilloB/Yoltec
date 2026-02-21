#!/bin/bash

# Script para iniciar ngrok y exponer el backend Laravel
# Autor: Asistente IA para Yoltec

echo "🚀 Iniciando ngrok para Yoltec Backend..."

# Verificar si ngrok está instalado
if ! command -v ngrok &> /dev/null; then
    echo "❌ ngrok no está instalado. Por favor instálalo primero:"
    echo "   npm install -g ngrok"
    echo "   o descárgalo desde https://ngrok.com/download"
    exit 1
fi

# Configuración de ngrok
NGROK_DOMAIN="shara-isospondylous-capitally.ngrok-free.dev"
NGROK_TOKEN="39R1yRAJWSHk7thy5d4Gwa9NvAy_6Do8fjFRSq5HR4oMadpSg"
BACKEND_PORT="8000"

echo "📡 Configurando ngrok con dominio personalizado..."
echo "   Dominio: $NGROK_DOMAIN"
echo "   Puerto Backend: $BACKEND_PORT"

# Iniciar ngrok con dominio personalizado
ngrok http $BACKEND_PORT \
    --domain=$NGROK_DOMAIN \
    --authtoken=$NGROK_TOKEN \
    --log=stdout

echo "✅ ngrok iniciado. Tu backend está accesible en:"
echo "   🌐 https://$NGROK_DOMAIN"
echo ""
echo "📱 Para probar en tu celular:"
echo "   1. Asegúrate de que tu celular y computadora estén en la misma red"
echo "   2. Inicia el frontend Angular con: cd frontend && npm start"
echo "   3. Abre http://localhost:4200 en tu navegador"
echo "   4. Escanea el código QR o usa la URL que ngrok muestre"
echo ""
echo "🔄 Para detener: Presiona Ctrl+C"
