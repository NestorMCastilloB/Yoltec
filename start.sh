#!/usr/bin/env bash
# Arranque local; instala dependencias sin modificar la base de datos ni los .env.
set -Eeuo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")" && pwd)"
PYTHON_BIN="${PYTHON_BIN:-python3.12}"
PIDS=()

fail() {
    echo "ERROR: $*" >&2
    exit 1
}

cleanup() {
    local pid
    for pid in "${PIDS[@]}"; do
        kill -- "-$pid" 2>/dev/null || true
    done
    for pid in "${PIDS[@]}"; do
        wait "$pid" 2>/dev/null || true
    done
}

trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

for cmd in php composer npm "$PYTHON_BIN" setsid; do
    command -v "$cmd" >/dev/null || fail "Falta $cmd. Consulta docs/recuperacion.md."
done

for file in backend/.env IA/.env; do
    [ -f "$PROJECT_ROOT/$file" ] || fail "Falta $file. Configúralo a partir de su .example."
done

php -r 'exit(extension_loaded("pdo_pgsql") ? 0 : 1);' || fail "PHP requiere pdo_pgsql para PostgreSQL."
"$PYTHON_BIN" -c 'import sys; sys.exit(0 if sys.version_info[:2] == (3, 12) else 1)' || fail "Las dependencias de IA requieren el entorno Python 3.12 del proyecto."

cd "$PROJECT_ROOT/backend"
composer check-platform-reqs --lock --no-dev
if [ ! -f vendor/autoload.php ]; then
    composer install --no-interaction --prefer-dist
fi

cd "$PROJECT_ROOT/IA"
if [ ! -d venv ]; then
    "$PYTHON_BIN" -m venv venv
fi
venv/bin/python -c 'import sys; sys.exit(0 if sys.version_info[:2] == (3, 12) else 1)' || fail "IA/venv debe usar Python 3.12. Crea un entorno compatible."
venv/bin/python -m pip install -r requirements.txt
# Detecta errores de configuración antes de iniciar procesos en segundo plano.
venv/bin/python -c 'import app'
for file in model.pkl label_encoder.pkl feature_names.json; do
    [ -f "$file" ] || fail "Falta IA/$file. Consulta docs/recuperacion.md para recuperar el modelo."
done

cd "$PROJECT_ROOT/frontend"
if [ ! -d node_modules ]; then
    npm ci
fi

cd "$PROJECT_ROOT/backend"
setsid php artisan serve --host=127.0.0.1 --port=8000 &
PIDS+=("$!")

cd "$PROJECT_ROOT/IA"
setsid venv/bin/python -m uvicorn app:app --host=127.0.0.1 --port=5000 &
PIDS+=("$!")

cd "$PROJECT_ROOT/frontend"
setsid npm start -- --host=127.0.0.1 --port=4200 &
PIDS+=("$!")

echo "Iniciando backend :8000, IA :5000 y frontend :4200. Revisa los mensajes de cada servicio."
echo "Ctrl+C detiene los tres servicios."

# Si un servicio termina, detiene los demás y conserva el error de salida.
status=0
wait -n "${PIDS[@]}" || status=$?
echo "Un servicio terminó; deteniendo los demás." >&2
if [ "$status" -eq 0 ]; then
    status=1
fi
exit "$status"
