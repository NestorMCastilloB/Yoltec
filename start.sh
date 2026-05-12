#!/bin/bash
# ============================================================
#  Yoltec — Arranque rapido de los 3 servicios
#  Uso: ./start.sh  (desde la raiz del proyecto)
# ============================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PROJECT_ROOT="$(cd "$(dirname "$0")" && pwd)"

echo ""
echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}  Yoltec — Arrancando servicios${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""

# ── Verificar dependencias ───────────────────────────────
for cmd in php composer npm python3; do
    if ! command -v $cmd &> /dev/null; then
        echo -e "${RED}  $cmd no esta instalado. Instalalo primero.${NC}"
        exit 1
    fi
done

# ── Backend ──────────────────────────────────────────────
echo -e "${BLUE}[1/3] Backend (Laravel :8000)...${NC}"
cd "$PROJECT_ROOT/backend"
if [ ! -d "vendor" ]; then
    composer install --no-interaction --quiet
fi
php artisan serve --host=127.0.0.1 --port=8000 &
BACKEND_PID=$!
sleep 1

# ── IA ───────────────────────────────────────────────────
echo -e "${BLUE}[2/3] IA (FastAPI :5000)...${NC}"
cd "$PROJECT_ROOT/IA"
if [ ! -d "venv" ]; then
    python3 -m venv venv
fi
source venv/bin/activate
if [ ! -f "model.pkl" ]; then
    echo -e "${YELLOW}  Entrenando modelo (~30s)...${NC}"
    python train_model_light.py
fi
uvicorn app:app --host=0.0.0.0 --port=5000 &
IA_PID=$!
deactivate
sleep 1

# ── Frontend ─────────────────────────────────────────────
echo -e "${BLUE}[3/3] Frontend (Angular :4200)...${NC}"
cd "$PROJECT_ROOT/frontend"
if [ ! -d "node_modules" ]; then
    npm install --silent 2>/dev/null
fi
npx ng serve --host=0.0.0.0 --port=4200 &
FRONTEND_PID=$!

echo ""
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}  Los 3 servicios estan corriendo${NC}"
echo -e "${GREEN}============================================${NC}"
echo -e "  Backend:  ${BLUE}http://localhost:8000${NC}"
echo -e "  Frontend: ${BLUE}http://localhost:4200${NC}"
echo -e "  IA:       ${BLUE}http://localhost:5000${NC}"
echo ""
echo -e "  ${RED}Ctrl+C${NC} para detener todo."
echo ""

cleanup() {
    echo ""
    echo -e "${YELLOW}Deteniendo servicios...${NC}"
    kill $BACKEND_PID $IA_PID $FRONTEND_PID 2>/dev/null
    wait $BACKEND_PID $IA_PID $FRONTEND_PID 2>/dev/null
    echo -e "${GREEN}Listo.${NC}"
    exit 0
}

trap cleanup SIGINT SIGTERM
wait
