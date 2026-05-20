# Yoltec

> Sistema integral de gestión para el consultorio médico universitario del **TecNM Campus Valle de México**, con pre‑evaluación de síntomas asistida por IA.

![Laravel](https://img.shields.io/badge/Laravel-12-FF2D20?logo=laravel&logoColor=white)
![Angular](https://img.shields.io/badge/Angular-20-DD0031?logo=angular&logoColor=white)
![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)
![Python](https://img.shields.io/badge/Python-3.12-3776AB?logo=python&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-Neon-336791?logo=postgresql&logoColor=white)
![License](https://img.shields.io/badge/license-MIT-green)

---

## Tabla de contenido

- [Resumen](#resumen)
- [Arquitectura](#arquitectura)
- [Stack tecnológico](#stack-tecnológico)
- [Requisitos](#requisitos)
- [Instalación](#instalación)
- [Configuración de entorno](#configuración-de-entorno)
- [Roles y funcionalidades](#roles-y-funcionalidades)
- [Estructura del repositorio](#estructura-del-repositorio)
- [Despliegue](#despliegue)
- [Seguridad](#seguridad)
- [Contribuir](#contribuir)
- [Licencia](#licencia)

---

## Resumen

**Yoltec** es una plataforma médica de tres canales (web administrativo, web del doctor y app móvil del estudiante) que digitaliza el flujo completo del consultorio universitario: agendado de citas, pre‑evaluación de síntomas con IA conversacional, historial clínico, recetas y bitácora del doctor.

La pre‑evaluación combina dos modelos:

- **`scikit-learn`** (`HistGradientBoostingClassifier`) para clasificación de síntomas → diagnóstico probable.
- **Groq + Llama 3.1 8B** para conversación natural y refinamiento de motivo de consulta.

---

## Arquitectura

```
┌─────────────────┐   ┌──────────────────┐   ┌──────────────────┐
│  Frontend web   │   │  App móvil       │   │  Admin (web)     │
│  Angular 20     │   │  Flutter 3.x     │   │  Angular 20      │
│  Doctores       │   │  Estudiantes     │   │  CRUD usuarios   │
└────────┬────────┘   └────────┬─────────┘   └────────┬─────────┘
         │                     │                      │
         └──────────────┬──────┴───────┬──────────────┘
                        │              │
                        ▼              ▼
                ┌──────────────────────────┐
                │   Backend Laravel 12     │
                │   API REST + Sanctum     │
                └────────┬─────────────────┘
                         │
              ┌──────────┴──────────┐
              ▼                     ▼
   ┌────────────────────┐   ┌────────────────────┐
   │  PostgreSQL Neon   │   │  Microservicio IA  │
   │  (cloud)           │   │  FastAPI + Groq    │
   └────────────────────┘   └────────────────────┘
```

---

## Stack tecnológico

| Capa | Tecnología |
|------|------------|
| Backend | Laravel 12 · PHP 8.4 · Sanctum |
| Frontend web | Angular 20 · TypeScript · RxJS |
| App móvil | Flutter 3.x · Dart 3 · Material 3 |
| IA | Python 3.12 · FastAPI · scikit-learn · Groq (Llama 3.1) |
| Base de datos | PostgreSQL en Neon (SSL) |
| Push | Firebase Cloud Messaging |
| Email | Gmail SMTP (dev) · Resend (prod) |
| Infra | Docker · Docker Compose · Render · Vercel |

---

## Requisitos

| Herramienta | Versión mínima |
|-------------|----------------|
| PHP | 8.4 |
| Composer | 2.7 |
| Node.js | 20 LTS |
| Python | 3.12 |
| Flutter SDK | 3.x |
| Docker / Compose | 24.x / v2 |
| PostgreSQL | gestionado en Neon |

---

## Instalación

### Opción A — Docker (recomendado)

```bash
# 1. Clonar
git clone https://github.com/NestorMCastilloB/Yoltec.git
cd Yoltec

# 2. Crear .env locales a partir de los ejemplos
cp backend/.env.docker.example backend/.env.docker
cp IA/.env.example IA/.env

# 3. Editar credenciales (ver sección "Configuración de entorno")

# 4. Levantar
docker compose up -d --build
```

| Servicio  | URL local              |
|-----------|------------------------|
| Frontend  | http://localhost:4200  |
| Backend   | http://localhost:8000  |
| IA        | http://localhost:5000  |

Detener: `docker compose down`

### Opción B — Sin Docker (4 terminales)

```bash
# Terminal 1 — Backend
cd backend
cp .env.example .env
composer install
php artisan key:generate
php artisan migrate
php artisan serve --host=127.0.0.1 --port=8000

# Terminal 2 — Frontend
cd frontend
npm install
ng serve --host=0.0.0.0 --port=4200

# Terminal 3 — Microservicio IA
cd IA
cp .env.example .env
python3 -m venv venv && source venv/bin/activate
pip install -r requirements.txt
python train_model_light.py            # genera model.pkl (~30s, una sola vez)
uvicorn app:app --host=0.0.0.0 --port=5000

# Terminal 4 — App móvil (opcional)
cd mobile
flutter pub get
flutter run
```

> Para usar la app móvil contra el backend local, cambia `baseUrl` en `mobile/lib/services/api_service.dart` a `http://TU_IP_LAN:8000`.

---

## Configuración de entorno

Cada subproyecto trae un archivo `*.example` con la lista completa de variables. **Ninguna credencial real está versionada**.

| Archivo | Propósito |
|---------|-----------|
| `backend/.env.example` | Variables Laravel (DB, mail, Firebase, IA) |
| `backend/.env.docker.example` | Variables Laravel en modo Docker |
| `IA/.env.example` | API key de Groq + modelo |
| `mobile/lib/services/api_service.dart` | `baseUrl` configurable por entorno |

**Variables críticas que debes proveer tú mismo**:

| Variable | Dónde se usa | Cómo obtenerla |
|----------|--------------|----------------|
| `APP_KEY` | Laravel | `php artisan key:generate` |
| `DB_HOST`, `DB_PASSWORD` | Laravel | Panel de Neon (o tu PostgreSQL) |
| `GROQ_API_KEY` | IA | https://console.groq.com |
| `MAIL_USERNAME`, `MAIL_PASSWORD` | Laravel | Gmail App Password o Resend |
| `FIREBASE_CREDENTIALS` | Laravel | Service account JSON desde Firebase Console |

---

## Roles y funcionalidades

### Estudiante (app móvil)

- Login con número de control + NIP.
- Calendario de citas (Lun–Sáb, 8:00–17:00, slots de 15 min).
- Pre‑evaluación conversacional con IA, asociada a la próxima cita.
- Historial de citas (Próximas / Pasadas / Canceladas).
- Recetas con detalle de medicación.
- Perfil médico editable (alergias, crónicas, contacto de emergencia).

### Doctor (web)

- Login con usuario + contraseña + 2FA por correo (producción).
- Dashboard con citas del día, gráficas y atajos.
- Validar o descartar diagnósticos de pre‑evaluación.
- Crear consultas, bitácoras y recetas.
- Agendar y cancelar citas a nombre de alumnos.
- IA de priorización de pacientes.
- Exportar bitácora en CSV.

### Admin (web, ruta oculta)

- CRUD de alumnos y doctores.
- Gestión del calendario (días especiales, cierres).
- 2FA obligatorio.

---

## Estructura del repositorio

```
Yoltec/
├── backend/          Laravel 12 — API REST + IA priorización
├── frontend/         Angular 20 — SPA web (doctor + admin)
├── mobile/           Flutter — App estudiante (Android/iOS/Desktop)
├── IA/               Python + FastAPI — sklearn + Groq
├── docs/             Documentación técnica y entregables
├── docker-compose.yml
├── README.md
├── LICENSE
├── SECURITY.md
└── CONTRIBUTING.md
```

Cada subcarpeta tiene su propio `CLAUDE.md` (gitignored) con convenciones internas y notas para el equipo.

---

## Despliegue

| Servicio | Plataforma | URL |
|----------|------------|-----|
| Frontend | Vercel | https://frontend-nu-weld-77.vercel.app |
| Backend | Render | https://yoltec-backend.onrender.com |
| IA | Render | https://yoltec-ia.onrender.com |
| BD | Neon | privada |

> Los releases del APK móvil se publican en [GitHub Releases](https://github.com/NestorMCastilloB/Yoltec/releases).

---

## Seguridad

- Todas las contraseñas y NIPs se almacenan con `bcrypt`.
- Tokens Sanctum con expiración configurada a 24 h.
- 2FA por correo obligatorio para doctores y admin en producción.
- Rate limiting (`throttle:5,1`) en endpoints sensibles (login, 2FA, reset).
- CORS con allowlist explícita, sin wildcards en producción.
- Encabezados de seguridad (`SecurityHeaders` middleware): HSTS, X‑Frame‑Options, CSP base.
- Para reportar vulnerabilidades, consulta [`SECURITY.md`](SECURITY.md).

> Si necesitas credenciales de prueba (usuarios demo para reviewers), solicítalas al mantenedor del repo. **No se publican en este README** porque las instancias desplegadas son reales y compartidas.

---

## Contribuir

Lee primero [`CONTRIBUTING.md`](CONTRIBUTING.md) para conocer el flujo de ramas, convenciones de commits y proceso de revisión. En resumen:

```bash
git checkout main && git pull
git checkout -b feat/descripcion-corta
# desarrollar y probar
git add archivos_modificados
git commit -m "feat: descripción breve"
git push origin feat/descripcion-corta
# abrir PR hacia main
```

Convención de commits: `feat` · `fix` · `refactor` · `docs` · `chore` · `test`.

---

## Licencia

Distribuido bajo licencia **MIT**. Consulta [`LICENSE`](LICENSE) para más detalles.

---

<sub>Proyecto académico — Instituto Tecnológico Nacional de México · Campus Valle de México · 2026</sub>
