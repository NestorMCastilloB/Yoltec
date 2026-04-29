# CLAUDE.md — Instrucciones del proyecto Yoltec

Este archivo se carga automáticamente en cada conversación con Claude Code.
Contiene el contexto completo del proyecto para no repetir explicaciones.

---

## Qué es este proyecto

Sistema de consultorio médico universitario con IA integrada.
Desarrollado por equipo de 3 personas (proyecto del Tec).
**Deadline: mediados de junio 2026.**

Repo: https://github.com/elnemito001/Yoltec.git

---

## Stack tecnológico (NO cambiar sin consultar)

| Capa | Tecnología |
|------|-----------|
| Backend | Laravel 12 |
| Frontend web | Angular 20 |
| App móvil | Flutter / Dart |
| Base de datos | PostgreSQL en Neon (cloud) |
| IA | Python + FastAPI + scikit-learn + Groq (API gratuita) |

**IMPORTANTE**: Groq es 100% gratuito para el volumen que usamos. No usar OpenAI, Anthropic ni otras APIs de pago.

---

## Credenciales de prueba

| Rol | Usuario | Contraseña |
|-----|---------|-----------|
| Alumno | `22690495` (número de control) | NIP: `740270` |
| Doctor | `doctorOmar` | `doctor123` |
| Doctor 2 | `doctorCarlos` | `doctor123` |
| Admin | `admin` | `admin123` |

> En local el 2FA está **desactivado** (`APP_ENV=local`). En producción solo los doctores reciben código por email.

---

## Archivos .env necesarios

### `backend/.env`

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

# Base de datos — Neon PostgreSQL (compartida, misma que producción)
# IMPORTANTE: usar endpoint "direct" (sin -pooler), el pooler rompe migrations
# Si el endpoint cambia (Neon lo rota al despertar el compute), copiar el nuevo desde Neon → Connect → Direct
DB_CONNECTION=pgsql
DB_HOST=ep-noisy-darkness-a49s74zs.us-east-1.aws.neon.tech
DB_PORT=5432
DB_DATABASE=neondb
DB_USERNAME=neondb_owner
DB_PASSWORD=<ver backend/.env — rotado 2026-04-25>
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

# Email (Gmail app password — solo para desarrollo local)
MAIL_MAILER=smtp
MAIL_HOST=smtp.gmail.com
MAIL_PORT=587
MAIL_USERNAME=nespiolin05@gmail.com
MAIL_PASSWORD=<ver backend/.env — rotado 2026-04-25>
MAIL_FROM_ADDRESS="nespiolin05@gmail.com"
MAIL_FROM_NAME="Yoltec"

# Microservicio IA (local)
IA_SERVICE_URL=http://127.0.0.1:5000
FRONTEND_URL=http://localhost:4200
```

### `IA/.env`

```env
# Groq — genera tu propia key gratis en https://console.groq.com
GROQ_API_KEY=<ver IA/.env — rotado 2026-04-25>
GROQ_MODEL=llama-3.1-8b-instant
LLM_PROVIDER=groq
```

---

## Cómo correr el proyecto (desarrollo local)

> La base de datos ya está en Neon (cloud). **No instalar PostgreSQL local.**

### Backend — Laravel

```bash
cd backend
composer install
php artisan migrate        # solo la primera vez; la DB ya tiene datos
php artisan serve --host=127.0.0.1 --port=8000
```

### Frontend — Angular

```bash
cd frontend
npm install
ng serve --host=0.0.0.0 --port=4200
```

Abre http://localhost:4200

### IA — Python/FastAPI

```bash
cd IA
python3 -m venv venv
source venv/bin/activate        # Windows: venv\Scripts\activate
pip install -r requirements.txt
python train_model_light.py     # entrena el modelo (~30s), genera model.pkl
uvicorn app:app --host=0.0.0.0 --port=5000
```

### App móvil — Flutter

```bash
cd mobile
flutter pub get
flutter run                     # conecta un dispositivo/emulador primero
```

### Con Docker (alternativa)

```bash
docker compose up -d
```

### Windows — scripts de arranque rápido

```bat
start-yoltec.bat   # arranca los 3 servicios nativos en ventanas separadas
stop-yoltec.bat    # detiene los procesos en puertos 8000, 4200 y 5000
```

> No mezclar Docker y nativos al mismo tiempo — chocan en los puertos.

---

## Estructura de carpetas

```
Yoltec/
├── backend/          # Laravel 12 (API REST)
├── frontend/         # Angular 20 (web)
├── mobile/           # Flutter (Android/iOS/desktop)
├── IA/               # Python + FastAPI + scikit-learn + Groq
├── docs/             # Documentación
└── docker-compose.yml
```

---

## URLs de producción

| Servicio | URL |
|----------|-----|
| Frontend (Vercel) | https://frontend-nu-weld-77.vercel.app |
| Backend (Render) | https://yoltec-backend.onrender.com |
| IA (Render) | https://yoltec-ia.onrender.com |

---

## Módulos del sistema

### 1. Login
- **Alumno**: número_control + NIP
- **Doctor**: username + password + 2FA email (solo en producción)
- **Admin**: username + password, ruta `/admin-dashboard`
- 2FA desactivado en local (`APP_ENV=local`)

### 2. Calendario de citas (alumno y doctor)
- Lunes a sábado (domingos SIEMPRE inhabilitados)
- Horario: 8:00am - 5:00pm, intervalos de 15 minutos
- Colores: verde (mucha disponibilidad), amarillo (poca), rojo (no disponible/festivo)
- Tiempo pasado: inhabilitado automáticamente
- Slots exclusivos: si alguien aparta un horario, nadie más puede tomarlo
- Cancelaciones liberan el slot
- Motivo obligatorio al agendar
- Doctor puede agendar Y cancelar citas a nombre de alumnos

### 3. Dashboard Doctor
- Citas del día actual, cita más próxima, totales
- Gráficas Chart.js: barras por mes + donut por estado
- Se actualiza dinámicamente

### 4. IA Pre-evaluación de síntomas
- Chat con Groq (lenguaje natural) + modelo sklearn (diagnóstico con % confianza)
- Visible para alumno y doctor
- Doctor puede validar o descartar
- Disponible en web y móvil

### 5. IA Clasificación de prioridad (solo visible al doctor)
- Clasifica alumnos por historial (asistencia, cancelaciones)
- Alta prioridad: asiste siempre, puntual
- Baja prioridad: cancela frecuentemente o no asiste
- Solo etiqueta, NO cancela citas automáticamente
- Stack: reglas + modelo sklearn simple

### 6. Recetas
- ~~PDF~~ **ELIMINADO**
- Doctor crea receta, alumno la ve en pantalla (web y móvil)

### 7. Bitácora
- Historial de citas: atendidas, canceladas, no asistidas
- Filtros por fecha y alumno, paginación, exportar CSV
- Doctor ve todo; alumno ve solo sus propias citas

### 8. App móvil (Flutter)
- Login, citas, IA chat, bitácora, pre-evaluaciones, recetas, agendar por doctor
- `baseUrl` en `mobile/lib/services/api_service.dart` — en release apunta a Railway
- Para desarrollo local cambiar a `http://TU_IP:8000`

---

## Plan de sprints (abr–jun 2026)

| Sprint | Fechas | Objetivo | Estado |
|--------|--------|----------|--------|
| Sprint 1 | 25 abr – 5 may | Limpieza setup, rate limiting login | ✅ Completado |
| Sprint 2 | 6–16 may | Días especiales admin UI, página admin separada | ✅ Completado |
| Sprint 3 | 17–27 may | Formulario consulta HU-06, historial médico HU-11 | ✅ Completado |
| Sprint 4 | 28 may – 7 jun | IA prioridad, mobile sync, push notifications | ✅ Completado |
| Sprint 5 | 8–15 jun | Pulido, tests, demo — CERO features nuevas | ✅ Completado |

> **Todos los sprints fueron completados anticipadamente al 2026-04-28** (~6 semanas antes del deadline).

Jira: https://yoltec.atlassian.net — Proyecto **Yoltec 2.0 IA** (key `Y20I`, con cero)
Convención de ramas: `feature/Y20I-XX-descripcion-corta`

---

## Estado al 2026-04-28

### ✅ Ya implementado

1. Login — alumno, doctor (+ 2FA), admin
2. Calendario de citas — web + móvil
3. Dashboard doctor — citas del día, próxima cita, gráficas
4. IA pre-evaluación — chat Groq + diagnóstico sklearn — web + móvil
5. Recetas médicas — doctor crea, alumno ve — web + móvil
6. Bitácora — filtros, paginación, exportar CSV
7. Marcar "no asistió" — manual por doctor
8. Email recordatorio 24h antes — `citas:notificar-proximas`, scheduler hourly
9. 2FA — solo doctores en producción, dispositivo de confianza 30 días
10. Panel admin — CRUD alumnos y doctores
11. Recuperación de contraseña — email con Resend
12. Búsqueda en citas — client-side
13. App móvil Flutter — funcional completa
14. APK release — apuntando a Railway producción
15. Días especiales en UI admin — `CalendarioAdminController` + tabla `dias_especiales` + UI panel admin
16. IA clasificación de prioridad — `IAPriorityController`, `PriorityClassifier`, solo visible al doctor
17. Rate limiting en login — `ThrottleRequests` de Laravel
18. Expiración tokens Sanctum — 24h (`config/sanctum.php`)
19. Notificaciones push móvil — Firebase Cloud Messaging
20. Formulario de consulta (HU-06) — `ConsultaController`, doctor llena diagnóstico + tratamiento + observaciones
21. Historial médico alumno (HU-11) — `PerfilMedicoController`, tipo de sangre, alergias, enfermedades crónicas
22. Foto de perfil — `PerfilController`, opcional para alumnos y doctores

### ❌ Fuera de scope

- Auto-registro de alumnos
- PDFs / justificantes con firma digital
- Resultados de laboratorio
- Inventario de medicamentos
- Encuestas de satisfacción
- Integración con sistema escolar

---

## Notas técnicas importantes

- **model.pkl** no está en git — regenerar con `python train_model_light.py` (~30s)
- **DB compartida**: todos usan la misma Neon (dev + producción). **NUNCA ejecutar `migrate:fresh`**
- **Neon endpoint**: puede cambiar cuando el compute se suspende y despierta. Si el backend falla con `password authentication failed`, ir a Neon → Connect → copiar el nuevo DB_HOST **direct** (sin `-pooler`). El pooler rompe migrations.
- **Credenciales rotadas 2026-04-25**: DB_PASSWORD, MAIL_PASSWORD, GROQ_API_KEY — leer directamente desde los `.env` locales, nunca pegar en chat ni commits.
- **Resend en producción**: sin dominio verificado, solo puede enviar a `nespiolin05@gmail.com`
- **Android cleartext**: `AndroidManifest.xml` tiene `usesCleartextTraffic="true"` para HTTP en desarrollo local
- **Bug conocido**: `IADummyDataSeeder.php` usa columna `name` pero el schema tiene `nombre`+`apellido` — falla al correr. Pendiente arreglar.
- **Encoding .env en Windows**: usar `[System.IO.File]::WriteAllText` con UTF8 sin BOM. `Set-Content -Encoding UTF8` agrega BOM que rompe Python dotenv en Docker.

---

## Decisiones de arquitectura

1. **Sin 2FA en local** — solo en producción, solo para doctores
2. **Sin PDFs** — eliminados
3. **Groq para IA chat** — gratuito, sin tarjeta. sklearn para diagnóstico
4. **DB en Neon** — cloud, compartida entre dev y producción
5. **No lenguaje natural en IA de diagnóstico** — preguntas con opciones, sklearn

---

## Flujo de trabajo

```bash
git checkout main && git pull
git checkout -b feature/Y20I-XX-descripcion-corta
# desarrollar y probar
git add archivo1 archivo2
git commit -m "feat: descripción breve (Y20I-XX)"
git push origin feature/Y20I-XX-descripcion-corta
# abrir PR en GitHub hacia main
```

**Convención de commits:** `feat:` / `fix:` / `refactor:` / `docs:` / `chore:`

**NUNCA** push directo a `main`. Cada rama debe enlazar con un issue de Jira (`Y20I-XX`).

---

## Preferencias de trabajo

- Comunicación siempre en español
- Priorizar que funcione sobre que sea perfecto
- Eliminar código que no sirve, no acumular deuda técnica
- Siempre verificar que el backend esté corriendo antes de probar el frontend
