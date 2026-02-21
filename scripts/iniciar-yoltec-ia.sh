#!/bin/bash

# Script completo para iniciar Yoltec con IA y ngrok
# Uso: ./scripts/iniciar-yoltec-ia.sh

echo "🚀 Iniciando Yoltec con IA para acceso móvil..."

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para verificar si un proceso está corriendo
check_process() {
    if pgrep -f "$1" > /dev/null; then
        return 0
    else
        return 1
    fi
}

# Función para iniciar proceso en background
start_background() {
    local name=$1
    local command=$2
    local log_file=$3
    
    echo -e "${BLUE}📡 Iniciando $name...${NC}"
    
    if check_process "$command"; then
        echo -e "${YELLOW}⚠️  $name ya está corriendo${NC}"
        return
    fi
    
    nohup $command > "$log_file" 2>&1 &
    sleep 2
    
    if check_process "$command"; then
        echo -e "${GREEN}✅ $name iniciado correctamente${NC}"
        echo -e "${BLUE}📋 Logs: $log_file${NC}"
    else
        echo -e "${RED}❌ Error al iniciar $name${NC}"
        echo -e "${RED}📋 Revisa los logs: $log_file${NC}"
    fi
}

# Verificar requisitos
echo -e "${BLUE}🔍 Verificando requisitos...${NC}"

# Verificar PHP
if ! command -v php &> /dev/null; then
    echo -e "${RED}❌ PHP no está instalado${NC}"
    exit 1
fi

# Verificar Node.js
if ! command -v npm &> /dev/null; then
    echo -e "${RED}❌ Node.js/npm no está instalado${NC}"
    exit 1
fi

# Verificar ngrok
if ! command -v ngrok &> /dev/null; then
    echo -e "${RED}❌ ngrok no está instalado${NC}"
    echo -e "${YELLOW}💡 Instálalo con: npm install -g ngrok${NC}"
    exit 1
fi

# Verificar archivo .env
if [ ! -f "backend/.env" ]; then
    echo -e "${YELLOW}⚠️  Creando archivo .env desde ejemplo...${NC}"
    cp backend/.env.example backend/.env
    echo -e "${YELLOW}📝 No olvides agregar tus API keys en backend/.env:${NC}"
    echo -e "${YELLOW}   OPENAI_API_KEY=tu_api_key${NC}"
    echo -e "${YELLOW}   ANTHROPIC_API_KEY=tu_api_key${NC}"
fi

# Crear directorios de logs si no existen
mkdir -p logs

echo -e "${GREEN}✅ Requisitos verificados${NC}"
echo ""

# Iniciar Backend Laravel
echo -e "${BLUE}🔧 Iniciando Backend Laravel...${NC}"
cd backend
start_background "Backend Laravel" "php artisan serve --host=0.0.0.0 --port=8000" "../logs/backend.log"
cd ..

# Esperar a que el backend inicie
echo -e "${BLUE}⏳ Esperando a que el backend inicie...${NC}"
sleep 5

# Iniciar ngrok
echo -e "${BLUE}🌐 Iniciando ngrok...${NC}"
start_background "ngrok" "ngrok http 8000 --domain=shara-isospondylous-capitally.ngrok-free.dev --authtoken=39R1yRAJWSHk7thy5d4Gwa9NvAy_6Do8fjFRSq5HR4oMadpSg --log=stdout" "logs/ngrok.log"

# Esperar a que ngrok inicie
echo -e "${BLUE}⏳ Esperando a que ngrok inicie...${NC}"
sleep 10

# Iniciar Frontend Angular
echo -e "${BLUE}🎨 Iniciando Frontend Angular...${NC}"
cd frontend
start_background "Frontend Angular" "npm start" "../logs/frontend.log"
cd ..

echo ""
echo -e "${GREEN}🎉 Todos los servicios han sido iniciados${NC}"
echo ""

# Estado de los servicios
echo -e "${BLUE}📊 Estado de los servicios:${NC}"
echo ""

# Backend
if check_process "php artisan serve"; then
    echo -e "${GREEN}✅ Backend Laravel: Corriendo en http://localhost:8000${NC}"
else
    echo -e "${RED}❌ Backend Laravel: No está corriendo${NC}"
fi

# ngrok
if check_process "ngrok"; then
    echo -e "${GREEN}✅ ngrok: Corriendo en https://shara-isospondylous-capitally.ngrok-free.dev${NC}"
else
    echo -e "${RED}❌ ngrok: No está corriendo${NC}"
fi

# Frontend
if check_process "npm start"; then
    echo -e "${GREEN}✅ Frontend Angular: Corriendo en http://localhost:4200${NC}"
else
    echo -e "${RED}❌ Frontend Angular: No está corriendo${NC}"
fi

echo ""
echo -e "${BLUE}📱 Para acceder desde tu celular:${NC}"
echo -e "${YELLOW}1. Conecta tu celular a la misma red WiFi${NC}"
echo -e "${YELLOW}2. Abre http://localhost:4200 en tu computadora${NC}"
echo -e "${YELLOW}3. O usa la URL de ngrok directamente en el celular${NC}"
echo ""

echo -e "${BLUE}🔍 Logs disponibles:${NC}"
echo -e "${YELLOW}• Backend: logs/backend.log${NC}"
echo -e "${YELLOW}• Frontend: logs/frontend.log${NC}"
echo -e "${YELLOW}• ngrok: logs/ngrok.log${NC}"
echo ""

echo -e "${BLUE}🛑 Para detener todos los servicios:${NC}"
echo -e "${YELLOW}• Presiona Ctrl+C en esta terminal${NC}"
echo -e "${YELLOW}• O ejecuta: pkill -f 'php artisan serve' && pkill -f 'npm start' && pkill -f 'ngrok'${NC}"
echo ""

# Monitoreo
echo -e "${BLUE}👀 Monitoreando servicios (presiona Ctrl+C para detener)...${NC}"

# Función de limpieza
cleanup() {
    echo ""
    echo -e "${YELLOW}🛑 Deteniendo todos los servicios...${NC}"
    pkill -f "php artisan serve"
    pkill -f "npm start"
    pkill -f "ngrok"
    echo -e "${GREEN}✅ Todos los servicios detenidos${NC}"
    exit 0
}

# Capturar señal de interrupción
trap cleanup SIGINT SIGTERM

# Mantener el script corriendo
while true; do
    sleep 5
    
    # Verificar si los servicios siguen corriendo
    if ! check_process "php artisan serve"; then
        echo -e "${RED}⚠️  Backend se detuvo, reiniciando...${NC}"
        cd backend
        start_background "Backend Laravel" "php artisan serve --host=0.0.0.0 --port=8000" "../logs/backend.log"
        cd ..
    fi
    
    if ! check_process "npm start"; then
        echo -e "${RED}⚠️  Frontend se detuvo, reiniciando...${NC}"
        cd frontend
        start_background "Frontend Angular" "npm start" "../logs/frontend.log"
        cd ..
    fi
    
    if ! check_process "ngrok"; then
        echo -e "${RED}⚠️  ngrok se detuvo, reiniciando...${NC}"
        start_background "ngrok" "ngrok http 8000 --domain=shara-isospondylous-capitally.ngrok-free.dev --authtoken=39R1yRAJWSHk7thy5d4Gwa9NvAy_6Do8fjFRSq5HR4oMadpSg --log=stdout" "logs/ngrok.log"
    fi
done
