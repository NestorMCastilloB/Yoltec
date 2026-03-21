#!/bin/bash
# Script de desarrollo Yoltec
# Uso:
#   ./start.sh            → inicia backend + frontend web
#   ./start.sh emulator   → inicia el emulador Android
#   ./start.sh mobile     → inicia backend + emulador (para probar Flutter)
#   ./start.sh stop       → detiene todo

BASE="$(dirname "$0")"

start_backend() {
  echo "Iniciando backend Laravel..."
  cd "$BASE/backend"
  php artisan serve --host=127.0.0.1 --port=8000 &
  BACKEND_PID=$!
  echo "Backend corriendo en http://127.0.0.1:8000 (PID $BACKEND_PID)"
}

start_frontend() {
  echo "Iniciando frontend Angular..."
  cd "$BASE/frontend"
  ng serve --host=0.0.0.0 --port=4200 &
  FRONTEND_PID=$!
  echo "Frontend corriendo en http://localhost:4200 (PID $FRONTEND_PID)"
}

start_emulator() {
  echo "Iniciando emulador Android (Medium Phone API 33)..."
  ~/Android/Sdk/emulator/emulator -avd Medium_Phone_API_33 -gpu swiftshader_indirect &
  echo "Esperando a que ADB detecte el emulador..."
  until adb devices | grep -q "emulator"; do sleep 2; done
  echo "Emulador listo. Ahora corre: cd mobile && flutter run"
}

case "$1" in
  emulator)
    start_emulator
    ;;
  mobile)
    start_backend
    start_emulator
    echo ""
    echo "Cuando el emulador cargue: cd mobile && flutter run"
    trap "pkill -f 'artisan serve' 2>/dev/null" EXIT
    wait
    ;;
  stop)
    echo "Deteniendo servidores..."
    pkill -f "artisan serve" 2>/dev/null && echo "Backend detenido." || echo "Backend no corria."
    pkill -f "ng serve" 2>/dev/null && echo "Frontend detenido." || echo "Frontend no corria."
    adb emu kill 2>/dev/null && echo "Emulador cerrado." || echo "Emulador no corria."
    ;;
  *)
    start_backend
    start_frontend
    echo ""
    echo "Presiona Ctrl+C para detener todo."
    echo "Tip: ./start.sh mobile  → para probar la app Flutter"
    trap "kill $BACKEND_PID $FRONTEND_PID 2>/dev/null; echo 'Servidores detenidos'" EXIT
    wait
    ;;
esac
