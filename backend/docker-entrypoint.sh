#!/bin/sh
set -e

# Debug: mostrar variables DB en logs
echo "=== DEBUG ENV ===" >&2
echo "NEON_URL_SET=${NEON_URL:+YES}" >&2
echo "DB_HOST_raw=${DB_HOST:-empty}" >&2
echo "IA_SERVICE_URL_raw=${IA_SERVICE_URL:-empty}" >&2
echo "=================" >&2

# Generar .env desde las variables de entorno de Railway
cat > /var/www/html/.env << EOF
APP_NAME=Yoltec
APP_ENV=${APP_ENV:-production}
APP_KEY=${APP_KEY}
APP_DEBUG=${APP_DEBUG:-false}
APP_URL=${APP_URL:-http://localhost}

LOG_CHANNEL=stderr
LOG_LEVEL=debug

DB_CONNECTION=pgsql
DB_URL=${NEON_URL}

SESSION_DRIVER=file
SESSION_LIFETIME=120

CACHE_STORE=file
QUEUE_CONNECTION=database

FILESYSTEM_DISK=local

MAIL_MAILER=resend
MAIL_FROM_ADDRESS=${MAIL_FROM_ADDRESS:-onboarding@resend.dev}
MAIL_FROM_NAME=${MAIL_FROM_NAME:-Yoltec}
RESEND_KEY=${RESEND_KEY}

IA_SERVICE_URL=${IA_SERVICE_URL:-https://yoltec-production.up.railway.app}
EOF

# Limpiar caches para que tome el nuevo .env
php artisan config:clear
php artisan cache:clear
php artisan route:clear

# Migraciones y seeder (sin set -e para no crashear en loop)
php artisan migrate --force || echo "WARN: migrate falló, continuando..." >&2
php artisan db:seed --force || echo "WARN: seed falló, continuando..." >&2

# Arrancar servidor (Railway inyecta $PORT, default 8080)
PORT=${PORT:-8080}
exec php artisan serve --host=0.0.0.0 --port=${PORT}
