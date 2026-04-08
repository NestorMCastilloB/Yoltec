#!/bin/sh
set -e

# Migraciones y seeder automáticos
php artisan migrate --force
php artisan db:seed --force

# Limpiar caches
php artisan config:clear
php artisan route:clear

# Arrancar servidor (Railway inyecta $PORT, default 8080)
PORT=${PORT:-8080}
exec php artisan serve --host=0.0.0.0 --port=${PORT}
