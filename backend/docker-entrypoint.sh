#!/bin/sh
set -eu

# Compatibilidad con despliegues antiguos; Laravel recibe DB_URL directamente.
if [ -z "${DB_URL:-}" ] && [ -n "${NEON_URL:-}" ]; then
  export DB_URL="$NEON_URL"
fi

# Permite ejecutar tareas explícitas con `docker compose run --rm backend ...`.
if [ "$#" -gt 0 ]; then
  exec "$@"
fi

if [ -z "${APP_KEY:-}" ]; then
  echo "ERROR: falta APP_KEY en el entorno del backend. Recupera la clave existente o configura una para una instalación nueva." >&2
  exit 1
fi

# Descarta configuración de builds anteriores sin tocar datos ni caché compartida.
php artisan config:clear
php artisan route:clear

# Las migraciones y los seeders son operaciones explícitas, separadas del arranque.
exec php artisan serve --host=0.0.0.0 --port="${PORT:-8080}"
