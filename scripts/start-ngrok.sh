#!/bin/bash

# Script para iniciar ngrok y exponer el backend Laravel
# Uso: NGROK_TOKEN=tu_token NGROK_DOMAIN=tu_dominio ./scripts/start-ngrok.sh

echo "Iniciando ngrok para Yoltec Backend..."

if ! command -v ngrok &> /dev/null; then
    echo "ngrok no esta instalado. Descargalo desde https://ngrok.com/download"
    exit 1
fi

NGROK_DOMAIN="${NGROK_DOMAIN:?Configura NGROK_DOMAIN como variable de entorno}"
NGROK_TOKEN="${NGROK_TOKEN:?Configura NGROK_TOKEN como variable de entorno}"
BACKEND_PORT="${BACKEND_PORT:-8000}"

echo "Dominio: $NGROK_DOMAIN"
echo "Puerto Backend: $BACKEND_PORT"

ngrok http "$BACKEND_PORT" \
    --domain="$NGROK_DOMAIN" \
    --authtoken="$NGROK_TOKEN" \
    --log=stdout
