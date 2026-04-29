# Yoltec — Sistema de Consultorio Médico con IA

Sistema integral de gestión de consultorio médico universitario con inteligencia artificial integrada.

---

## Stack tecnológico

| Capa | Tecnología |
|------|-----------|
| Backend | Laravel 12 + Sanctum |
| Frontend web | Angular 20 |
| App móvil | Flutter / Dart |
| Base de datos | PostgreSQL en Neon (cloud) |
| IA | Python 3 + FastAPI + scikit-learn + Groq |
| Contenedores | Docker + Docker Compose |

---

## Levantar el proyecto

### Opción A — Docker (recomendado)

1. Copiar los archivos de ejemplo y completar las credenciales:
   ```bash
   cp backend/.env.docker.example backend/.env.docker
   cp IA/.env.example IA/.env
   ```
2. Editar ambos archivos con las credenciales reales (pedir a Nestor).
3. Levantar:
   ```bash
   docker compose up -d --build
   ```

| Servicio | URL |
|----------|-----|
| Frontend | http://localhost:4200 |
| Backend | http://localhost:8000 |
| IA | http://localhost:5000 |

Para detener: `docker compose down`

### Opción B — Sin Docker (4 terminales)

**Requisitos:** PHP 8.4+, Composer, Node.js 20+, Python 3.11+, Flutter 3.x (opcional).

1. Copiar y editar los `.env`:
   ```bash
   cp backend/.env.example backend/.env    # editar con credenciales reales
   cp IA/.env.example IA/.env              # agregar GROQ_API_KEY
   ```

2. Levantar cada servicio en su terminal:

   ```bash
   # Terminal 1 — Backend
   cd backend && composer install && php artisan migrate && php artisan serve --host=127.0.0.1 --port=8000

   # Terminal 2 — Frontend
   cd frontend && npm install && ng serve --host=0.0.0.0 --port=4200

   # Terminal 3 — IA
   cd IA && python3 -m venv venv && source venv/bin/activate && pip install -r requirements.txt
   python train_model_light.py     # genera model.pkl (~30s, solo la primera vez)
   uvicorn app:app --host=0.0.0.0 --port=5000

   # Terminal 4 — App móvil (opcional)
   cd mobile && flutter pub get && flutter run
   ```

---

## Notas importantes

- **La BD está en Neon (cloud)** — no instalar PostgreSQL local. **Nunca ejecutar `migrate:fresh`**.
- **`model.pkl` no está en el repo** — se genera con `python train_model_light.py` (~30s).
- **2FA desactivado en local** (`APP_ENV=local`). En producción solo los doctores reciben código por correo.
- **App móvil en local:** cambiar `baseUrl` en `mobile/lib/services/api_service.dart` a `http://TU_IP:8000`.

---

## Credenciales de prueba

| Rol | Usuario | Contraseña |
|-----|---------|-----------|
| Alumno | `22690495` | NIP: `740270` |
| Doctor | `doctorOmar` | `doctor123` |
| Doctor 2 | `doctorCarlos` | `doctor123` |
| Admin | `admin` | `admin123` |

---

## URLs de producción

| Servicio | URL |
|----------|-----|
| Frontend (Vercel) | https://frontend-nu-weld-77.vercel.app |
| Backend (Render) | https://yoltec-backend.onrender.com |
| IA (Render) | https://yoltec-ia.onrender.com |

---

## Funcionalidades

### Alumno
- Login con número de control + NIP
- Calendario de citas (Lun–Sáb, 8:00–17:00, intervalos de 15 min)
- Pre-evaluación de síntomas con IA (chat + diagnóstico con % de confianza)
- Historial de citas, bitácoras y recetas

### Doctor
- Login con usuario + contraseña + 2FA por email (producción)
- Dashboard con citas del día, próxima cita, gráficas
- Validar o descartar diagnósticos de pre-evaluación
- Crear bitácoras y recetas por consulta
- Agendar y cancelar citas a nombre de alumnos
- Clasificación de prioridad de pacientes con IA
- Exportar bitácora en CSV

### Admin
- CRUD de alumnos y doctores
- Gestión de días especiales del calendario

---

## Estructura del proyecto

```
Yoltec/
├── backend/          # Laravel 12 — API REST
├── frontend/         # Angular 20 — SPA web
├── mobile/           # Flutter — Android / iOS / Desktop
├── IA/               # Python + FastAPI + scikit-learn + Groq
├── docs/             # Documentación técnica
└── docker-compose.yml
```

---

## Flujo de trabajo

```bash
git checkout main && git pull
git checkout -b feature/nombre-feature
# desarrollar y probar localmente
git add archivo1 archivo2
git commit -m "feat: descripción breve"
git push origin feature/nombre-feature
# abrir PR en GitHub hacia main
```

**Convención de commits:** `feat:` / `fix:` / `refactor:` / `docs:` / `chore:`

---

Proyecto académico — Instituto Tecnológico, 2026
