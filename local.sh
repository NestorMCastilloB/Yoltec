#!/usr/bin/env bash
# Gestiona exclusivamente el entorno local, sin leer los .env heredados de Neon.
set -Eeuo pipefail
cd "$(dirname "$0")"

command -v docker >/dev/null || { echo "Falta Docker Engine con Compose." >&2; exit 1; }

if [ ! -f .env.local ]; then
    command -v openssl >/dev/null || { echo "Falta openssl para generar claves locales." >&2; exit 1; }
    (
        umask 077
        set -o noclobber
        {
            printf 'LOCAL_APP_KEY=base64:%s\n' "$(openssl rand -base64 32)"
            printf 'LOCAL_DB_PASSWORD=%s\n' "$(openssl rand -hex 32)"
            printf 'LOCAL_GROQ_API_KEY=\nLOCAL_GROQ_MODEL=llama-3.1-8b-instant\n'
        } > .env.local
    )
    echo "Creado .env.local con claves nuevas, exclusivas de este entorno."
fi

compose=(docker compose --project-name yoltec-local --env-file .env.local -f docker-compose.yml)

case "${1:-up}" in
    init) "${compose[@]}" config --quiet ;;
    up)
        "${compose[@]}" up -d --build --wait --wait-timeout 180
        "${compose[@]}" exec -T backend php artisan migrate --force
        echo "Web: http://localhost:4200 | Correo de prueba: http://localhost:8025"
        echo "Crea las cuentas ficticias con: ./local.sh seed"
        ;;
    seed)
        "${compose[@]}" exec -T backend php artisan db:seed --class=LocalDevelopmentSeeder
        ;;
    test)
        "${compose[@]}" exec -T postgres psql -U yoltec -d postgres -v ON_ERROR_STOP=1 <<'SQL'
SELECT 'CREATE DATABASE yoltec_test' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'yoltec_test')\gexec
SQL
        "${compose[@]}" exec -T backend php artisan test
        "${compose[@]}" run --rm --no-deps -v "$PWD/IA/tests:/app/tests:ro" ia python -m unittest discover -s tests -v
        ;;
    status) "${compose[@]}" ps ;;
    logs) "${compose[@]}" logs --tail=80 "${2:-backend}" ;;
    down) "${compose[@]}" down ;;
    *) echo "Uso: ./local.sh {init|up|seed|test|status|logs [servicio]|down}" >&2; exit 2 ;;
esac
