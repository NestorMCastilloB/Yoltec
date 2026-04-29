# Yoltec — Sistema de Consultorio Médico con IA

Sistema integral de gestión de consultorio médico universitario con inteligencia artificial integrada.

---

## Stack tecnológico

| Capa | Tecnología |
|------|-----------|
| Backend | Laravel 12 + Sanctum |
| Frontend web | Angular 20 |
| App móvil | Flutter / Dart (Android, iOS, Linux, Windows) |
| Base de datos | PostgreSQL en **Neon** (cloud, compartida) |
| IA | Python 3 + FastAPI + scikit-learn + Groq (gratuito) |
| Contenedores | Docker + Docker Compose |

---

## Levantar el proyecto (nuevo colaborador)

### Opción A — Docker (recomendado, todo en un comando)

**Requisitos:** Docker Desktop o Docker Engine instalado.

**1. Crear `backend/.env.docker`** con este contenido:

```env
APP_NAME=Yoltec
APP_ENV=local
APP_KEY=base64:zfLaLYOFnln8BDLkBVSDBxXKdDggX2RZhFBVlXXUeKo=
APP_DEBUG=true
APP_URL=http://localhost:8000
BCRYPT_ROUNDS=12
LOG_CHANNEL=stack
LOG_STACK=single
LOG_LEVEL=debug
DB_CONNECTION=pgsql
DB_HOST=<pedir a Nestor — endpoint de Neon>
DB_PORT=5432
DB_DATABASE=neondb
DB_USERNAME=neondb_owner
DB_PASSWORD=<pedir a Nestor>
DB_SSLMODE=require
SESSION_DRIVER=file
SESSION_LIFETIME=120
SESSION_ENCRYPT=false
SESSION_PATH=/
SESSION_DOMAIN=null
BROADCAST_CONNECTION=log
FILESYSTEM_DISK=local
QUEUE_CONNECTION=database
CACHE_STORE=file
MAIL_MAILER=smtp
MAIL_HOST=smtp.gmail.com
MAIL_PORT=587
MAIL_USERNAME=nespiolin05@gmail.com
MAIL_PASSWORD=<pedir a Nestor>
MAIL_FROM_ADDRESS="nespiolin05@gmail.com"
MAIL_FROM_NAME="Yoltec"
IA_SERVICE_URL=http://ia:5000
FRONTEND_URL=http://localhost:4200
```

**2. Crear `IA/.env`** con este contenido:

```env
GROQ_API_KEY=<pedir a Nestor o generar gratis en https://console.groq.com>
GROQ_MODEL=llama-3.1-8b-instant
LLM_PROVIDER=groq
```

**3. Levantar:**

```bash
docker compose up -d --build
```

| Servicio | URL |
|----------|-----|
| Frontend | http://localhost:4200 |
| Backend | http://localhost:8000 |
| IA | http://localhost:5000 |

Para detener: `docker compose down`

---

### Opción B — Sin Docker (4 terminales)

**Requisitos mínimos:**

| Herramienta | Versión |
|-------------|---------|
| PHP | 8.4+ |
| Composer | 2.8+ |
| Node.js | 20+ |
| Angular CLI | `npm install -g @angular/cli@20` |
| Python | 3.11+ |
| Flutter | 3.x (solo para app móvil) |

**Terminal 1 — Backend:**

```bash
cd backend
composer install
php artisan migrate
php artisan serve --host=127.0.0.1 --port=8000
```

> Crear `backend/.env` con el mismo contenido del bloque de arriba, cambiando `IA_SERVICE_URL=http://127.0.0.1:5000`.

**Terminal 2 — Frontend:**

```bash
cd frontend
npm install
ng serve --host=0.0.0.0 --port=4200
```

**Terminal 3 — IA:**

```bash
cd IA
python3 -m venv venv
source venv/bin/activate        # Windows: venv\Scripts\activate
pip install -r requirements.txt
python train_model_light.py     # genera model.pkl (~30 segundos)
uvicorn app:app --host=0.0.0.0 --port=5000
```

**Terminal 4 — App móvil (opcional):**

```bash
cd mobile
flutter pub get
flutter run
```

---

## Notas importantes

- **La base de datos está en Neon (cloud).** No hay que instalar PostgreSQL local. La misma DB es compartida entre desarrollo y producción — **nunca ejecutar `php artisan migrate:fresh`**.
- **`model.pkl` no está en el repo.** Se genera ejecutando `python train_model_light.py` (~30 segundos). Es normal que no exista al clonar.
- **2FA desactivado en local** (`APP_ENV=local`). En producción solo los doctores reciben código por correo.
- **App móvil en desarrollo local:** cambiar `baseUrl` en `mobile/lib/services/api_service.dart` a `http://TU_IP:8000`.

---

## Credenciales de prueba

| Rol | Usuario | Contraseña |
|-----|---------|-----------|
| Alumno | `22690495` (número de control) | NIP: `740270` |
| Doctor | `doctorOmar` | `doctor123` |
| Doctor 2 | `doctorCarlos` | `doctor123` |
| Admin | `admin` | `admin123` |

---

## URLs de producción

| Servicio | URL |
|----------|-----|
| Frontend | https://frontend-nu-weld-77.vercel.app |
| Backend | https://yoltec-backend.onrender.com |
| IA | https://yoltec-ia.onrender.com |

---

## Funcionalidades implementadas

### Alumno
- Login con número de control + NIP
- Calendario de citas (Lun–Sáb, 8:00–17:00, intervalos de 15 min)
- Pre-evaluación de síntomas con IA (chat Groq + diagnóstico sklearn con % de confianza)
- Historial de citas, bitácoras y recetas

### Doctor
- Login con usuario + contraseña + 2FA por email (producción)
- Dashboard con citas del día, próxima cita, gráficas Chart.js
- Validar o descartar diagnósticos de pre-evaluación
- Crear bitácoras y recetas por consulta
- Agendar y cancelar citas a nombre de alumnos
- Exportar bitácora en CSV

### Admin
- CRUD de alumnos y doctores
- Panel en `/admin-dashboard`

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

**Convención de commits:** `feat:` / `fix:` / `refactor:`

---

Proyecto académico — Instituto Tecnológico, 2026
