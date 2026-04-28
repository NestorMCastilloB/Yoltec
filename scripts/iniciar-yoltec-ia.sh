#!/bin/bash

# Script completo para iniciar Yoltec con IA y ngrok
# Uso: NGROK_TOKEN=tu_token NGROK_DOMAIN=tu_dominio ./scripts/iniciar-yoltec-ia.sh

echo "Iniciando Yoltec con IA para acceso movil..."

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

check_process() {
    pgrep -f "$1" > /dev/null
}

start_background() {
    local name=$1
    local command=$2
    local log_file=$3

    echo -e "${BLUE}Iniciando $name...${NC}"

    if check_process "$command"; then
        echo -e "${YELLOW}$name ya esta corriendo${NC}"
        return
    fi

    nohup $command > "$log_file" 2>&1 &
    sleep 2

    if check_process "$command"; then
        echo -e "${GREEN}$name iniciado correctamente${NC}"
    else
        echo -e "${RED}Error al iniciar $name — revisa: $log_file${NC}"
    fi
}

# Verificar requisitos
echo -e "${BLUE}Verificando requisitos...${NC}"

for cmd in php npm; do
    if ! command -v $cmd &> /dev/null; then
        echo -e "${RED}$cmd no esta instalado${NC}"
        exit 1
    fi
done

if [ ! -f "backend/.env" ]; then
    echo -e "${YELLOW}Creando archivo .env desde ejemplo...${NC}"
    cp backend/.env.example backend/.env
    echo -e "${YELLOW}Agrega tus credenciales en backend/.env${NC}"
fi

mkdir -p logs

echo -e "${GREEN}Requisitos verificados${NC}"
echo ""

# Backend
cd backend
start_background "Backend Laravel" "php artisan serve --host=0.0.0.0 --port=8000" "../logs/backend.log"
cd ..

sleep 5

# ngrok (solo si las variables estan configuradas)
if [ -n "$NGROK_TOKEN" ] && [ -n "$NGROK_DOMAIN" ]; then
    if command -v ngrok &> /dev/null; then
        start_background "ngrok" "ngrok http 8000 --domain=$NGROK_DOMAIN --authtoken=$NGROK_TOKEN --log=stdout" "logs/ngrok.log"
        sleep 10
    else
        echo -e "${YELLOW}ngrok no instalado, omitiendo...${NC}"
    fi
else
    echo -e "${YELLOW}NGROK_TOKEN/NGROK_DOMAIN no configurados, omitiendo ngrok...${NC}"
fi

# Frontend
cd frontend
start_background "Frontend Angular" "npm start" "../logs/frontend.log"
cd ..

echo ""
echo -e "${GREEN}Servicios iniciados${NC}"
echo ""

# Estado
echo -e "${BLUE}Estado de los servicios:${NC}"
check_process "php artisan serve" && echo -e "${GREEN}Backend: http://localhost:8000${NC}" || echo -e "${RED}Backend: no corriendo${NC}"
check_process "ngrok" && echo -e "${GREEN}ngrok: https://$NGROK_DOMAIN${NC}" || echo -e "${YELLOW}ngrok: no activo${NC}"
check_process "npm start" && echo -e "${GREEN}Frontend: http://localhost:4200${NC}" || echo -e "${RED}Frontend: no corriendo${NC}"

echo ""
echo -e "${BLUE}Logs: logs/backend.log | logs/frontend.log | logs/ngrok.log${NC}"
echo -e "${BLUE}Detener: Ctrl+C${NC}"

cleanup() {
    echo ""
    echo -e "${YELLOW}Deteniendo servicios...${NC}"
    pkill -f "php artisan serve"
    pkill -f "npm start"
    pkill -f "ngrok"
    echo -e "${GREEN}Servicios detenidos${NC}"
    exit 0
}

trap cleanup SIGINT SIGTERM

while true; do
    sleep 5
    check_process "php artisan serve" || {
        echo -e "${RED}Backend se detuvo, reiniciando...${NC}"
        cd backend && start_background "Backend" "php artisan serve --host=0.0.0.0 --port=8000" "../logs/backend.log" && cd ..
    }
done
