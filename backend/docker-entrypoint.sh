#!/bin/sh
set -e

# Crear SQLite si no existe
touch /var/www/html/database/database.sqlite
chown www-data:www-data /var/www/html/database/database.sqlite

# Migraciones y seeder automáticos
php artisan migrate --force
php artisan db:seed --force

# Limpiar caches
php artisan config:clear
php artisan route:clear

# Arrancar servidor
exec php artisan serve --host=0.0.0.0 --port=8000
