# Onboarding — Proyecto Yoltec
**Sistema de consultorio médico universitario con IA integrada**

---

## 1. Repositorio

```
https://github.com/elnemito001/Yoltec.git
```

```bash
git clone https://github.com/elnemito001/Yoltec.git
cd Yoltec
```

---

## 2. Herramientas que necesitas instalar

| Herramienta | Versión mínima | Cómo instalar |
|-------------|---------------|---------------|
| PHP | 8.3+ | https://herd.laravel.com (recomendado en Linux/Mac) o `apt install php8.3` |
| Composer | 2.8+ | https://getcomposer.org |
| Node.js | 20+ | https://nodejs.org (recomendado via nvm) |
| Angular CLI | 20.x | `npm install -g @angular/cli@20` |
| Python | 3.11+ | Ya viene en Ubuntu; o https://python.org |
| Flutter | 3.x | https://flutter.dev/docs/get-started/install |
| Docker | 28+ | https://docs.docker.com/get-docker/ (opcional pero recomendado) |
| Git | 2.x | `apt install git` |

### Cuentas necesarias

| Servicio | Para qué | URL |
|----------|----------|-----|
| **GitHub** | Acceso al repo | https://github.com — pedirle a Nestor que te agregue al repo |
| **Neon** (PostgreSQL cloud) | Base de datos producción | https://neon.tech — Nestor te comparte acceso |
| **Railway** | Hosting backend + IA | https://railway.app — Nestor te agrega al proyecto |
| **Vercel** | Hosting frontend | https://vercel.com — Nestor te agrega al proyecto |
| **Groq** | API de IA (gratis) | https://console.groq.com — crear cuenta, generar API key gratuita |
| **Resend** | Envío de emails | https://resend.com — Nestor te comparte la API key o creas una cuenta |

> **Nota:** Groq es 100% gratuito para el volumen que usamos. No requiere tarjeta.

---

## 3. Estructura del proyecto

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

## 4. Archivos .env (copiar y pegar)

### 4.1 `backend/.env`

Crea el archivo `backend/.env` con este contenido:

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
DB_CONNECTION=pgsql
DB_HOST=ep-shy-dawn-amz6fidi.c-5.us-east-1.aws.neon.tech
DB_PORT=5432
DB_DATABASE=neondb
DB_USERNAME=neondb_owner
DB_PASSWORD=npg_I4KN9YFMXiuQ
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
MAIL_PASSWORD=khwbnhycpopjpurq
MAIL_FROM_ADDRESS="nespiolin05@gmail.com"
MAIL_FROM_NAME="Yoltec"

# Microservicio IA (local)
IA_SERVICE_URL=http://127.0.0.1:5000
FRONTEND_URL=http://localhost:4200
```

### 4.2 `IA/.env`

Crea el archivo `IA/.env` con este contenido:

```env
# Groq — genera tu propia key gratis en https://console.groq.com
GROQ_API_KEY=<GENERA_TU_KEY_GRATIS_EN_console.groq.com>
GROQ_MODEL=llama-3.1-8b-instant
LLM_PROVIDER=groq
```

> Si prefieres usar tu propia key de Groq, reemplaza el valor de `GROQ_API_KEY`.

---

## 5. Levantar el proyecto (sin Docker)

### Backend — Laravel

```bash
cd backend
composer install
php artisan migrate        # solo la primera vez; la DB ya tiene datos
php artisan serve --host=127.0.0.1 --port=8000
```

> La base de datos ya está en Neon (cloud). No necesitas instalar PostgreSQL local.

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
source venv/bin/activate        # en Windows: venv\Scripts\activate
pip install -r requirements.txt
python train_model_light.py     # entrena el modelo (~30 segundos), genera model.pkl
uvicorn app:app --host=0.0.0.0 --port=5000
```

### App móvil — Flutter

```bash
cd mobile
flutter pub get
flutter run                     # conecta un dispositivo/emulador primero
```

Para compilar APK:
```bash
flutter build apk --release
```

---

## 6. Levantar con Docker (alternativa)

```bash
# Desde la raíz del proyecto
docker compose up -d
```

---

## 7. Credenciales de prueba

| Rol | Usuario | Contraseña |
|-----|---------|-----------|
| Alumno | `22690495` (número de control) | NIP: `740270` |
| Doctor | `doctorOmar` | `doctor123` |
| Doctor 2 | `doctorCarlos` | `doctor123` |
| Admin | `admin` | `admin123` |

> En local el 2FA está **desactivado** — entra directo. En producción solo los doctores reciben código por email.

---

## 8. URLs de producción (ya desplegado)

| Servicio | URL |
|----------|-----|
| Frontend (Vercel) | https://frontend-nu-weld-77.vercel.app |
| Backend (Railway) | https://lucid-motivation-production.up.railway.app |
| IA (Railway) | https://yoltec-production.up.railway.app |

---

## 9. Plan de trabajo

### ✅ Ya implementado (al 2026-04-16)

1. **Login** — alumno (numero_control + NIP), doctor (username + password + 2FA email), admin
2. **Calendario de citas** — web + móvil, lunes–sábado, 8am–5pm, slots exclusivos, colores disponibilidad
3. **Dashboard doctor** — citas del día, próxima cita, totales, gráficas Chart.js (barras por mes + donut por estado)
4. **IA pre-evaluación de síntomas** — chat con Groq (lenguaje natural) + modelo sklearn (diagnóstico con % confianza) — web + móvil
5. **Recetas médicas** — doctor crea, alumno ve — web + móvil
6. **Bitácora de citas** — filtros por fecha y alumno, paginación, exportar CSV
7. **Marcar "no asistió"** — manual por doctor
8. **Email recordatorio 24h antes** — comando `citas:notificar-proximas`, scheduler hourly
9. **2FA** — solo doctores en producción, dispositivo de confianza 30 días
10. **Panel admin** — CRUD alumnos y doctores, ruta `/admin-dashboard`
11. **Recuperación de contraseña** — flujo `/forgot-password` + `/reset-password?token=`, email con Resend
12. **Búsqueda en citas** — client-side por nombre/número de control/motivo
13. **App móvil Flutter** — login, citas, IA chat, bitácora, pre-evaluaciones, recetas, agendar por doctor
14. **APK release** — apuntando a Railway producción

---

### ⏳ Pendientes (por prioridad)

| # | Feature | Dificultad | Descripción |
|---|---------|-----------|-------------|
| 1 | **Días especiales en UI admin** | Baja | El backend ya existe (`CalendarioAdminController` + tabla `dias_especiales`). Solo falta conectar en el panel admin para que el admin pueda marcar festivos/días inhabilitados desde la UI |
| 2 | **IA clasificación de prioridad de alumnos** | Media | Clasifica alumnos según su historial (asistencia, cancelaciones). Visible solo para el doctor. No cancela citas automáticamente — solo etiqueta alta/baja prioridad. Stack: reglas + modelo sklearn simple |
| 3 | **Rate limiting en login** | Baja | Bloquear fuerza bruta. Usar `ThrottleRequests` de Laravel. Max 5 intentos fallidos → bloqueo temporal |
| 4 | **Expiración tokens Sanctum** | Baja | Los tokens actualmente no expiran. Agregar expiración de 24h en `config/sanctum.php` |
| 5 | **Notificaciones push móvil** | Media | Avisos en Flutter cuando se confirma/cancela una cita o llega recordatorio. Requiere Firebase Cloud Messaging |
| 6 | **Formulario de consulta (HU-06)** | Media | Formulario que el doctor llena al atender: diagnóstico, tratamiento, observaciones. Actualmente solo se marca la cita como "atendida" pero no queda registro del contenido de la consulta |
| 7 | **Historial médico del alumno (HU-11)** | Media | Tipo de sangre, alergias, enfermedades crónicas. Perfil médico visible para doctor y alumno |
| 8 | **Foto de perfil** | Baja | Opcional, para alumnos y doctores |

---

### ❌ Fuera de scope (descartado)

- Auto-registro de alumnos (ya existen en el sistema escolar)
- PDFs/justificantes con firma digital
- Resultados de laboratorio
- Inventario de medicamentos
- Encuestas de satisfacción
- Integración con sistema escolar (demasiado complejo)
- Directorio de médicos por especialidad

---

## 10. Notas técnicas importantes

- **model.pkl** no está en git — se regenera con `python train_model_light.py` (~30s). Es normal que no exista al clonar.
- **2FA**: en `APP_ENV=local` está desactivado. Solo se activa en producción.
- **DB compartida**: todos usan la misma Neon (dev + producción). Cuidado con `migrate:fresh`.
- **Resend email en producción**: sin dominio verificado, solo puede enviar a `nespiolin05@gmail.com`. Para desarrollo se usa Gmail SMTP.
- **Android cleartext**: el `AndroidManifest.xml` tiene `usesCleartextTraffic="true"` para permitir HTTP en desarrollo local.
- **baseUrl móvil**: en `mobile/lib/services/api_service.dart`. En release apunta a Railway. Para desarrollo local cámbialo a `http://TU_IP:8000`.

---

## 11. Flujo de trabajo sugerido

```bash
# 1. Siempre partir de main actualizado
git checkout main && git pull

# 2. Crear rama para tu feature
git checkout -b feature/nombre-feature

# 3. Desarrollar, probar localmente
# 4. Commit y push
git add archivo1 archivo2
git commit -m "feat: descripción breve"
git push origin feature/nombre-feature

# 5. Abrir PR en GitHub hacia main
```

**Convención de commits:**
- `feat:` nueva funcionalidad
- `fix:` corrección de bug
- `refactor:` cambio interno sin nueva funcionalidad

---

## 12. Contacto

Dudas con Nestor directamente. El proyecto tiene deadline **abril 2026**.
