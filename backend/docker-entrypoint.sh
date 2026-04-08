#!/bin/sh
set -e

# Generar .env desde las variables de entorno de Railway
cat > /var/www/html/.env << EOF
APP_NAME=Yoltec
APP_ENV=${APP_ENV:-production}
APP_KEY=${APP_KEY}
APP_DEBUG=${APP_DEBUG:-false}
APP_URL=${APP_URL:-http://localhost}

LOG_CHANNEL=stack
LOG_LEVEL=error

DB_CONNECTION=${DB_CONNECTION:-pgsql}
DB_HOST=${DB_HOST}
DB_PORT=${DB_PORT:-5432}
DB_DATABASE=${DB_DATABASE}
DB_USERNAME=${DB_USERNAME}
DB_PASSWORD=${DB_PASSWORD}
DB_SSLMODE=${DB_SSLMODE:-require}

SESSION_DRIVER=file
SESSION_LIFETIME=120

CACHE_STORE=file
QUEUE_CONNECTION=database

FILESYSTEM_DISK=local

IA_SERVICE_URL=${IA_SERVICE_URL:-http://localhost:5000}
EOF

# Limpiar caches para que tome el nuevo .env
php artisan config:clear
php artisan cache:clear
php artisan route:clear

# Migraciones y seeder automáticos
php artisan migrate --force
php artisan db:seed --force

# Arrancar servidor (Railway inyecta $PORT, default 8080)
PORT=${PORT:-8080}
exec php artisan serve --host=0.0.0.0 --port=${PORT}
