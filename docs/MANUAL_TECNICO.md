# Manual Técnico – Yoltec

**Versión:** 2.0
**Fecha:** Abril 2026
**Autor:** Nestor (equipo Yoltec)
**Repositorio:** https://github.com/elnemito001/Yoltec.git

---

## 1. Descripción general

Yoltec es un sistema de gestión de consultorio médico universitario con inteligencia artificial integrada. Permite a alumnos agendar citas, recibir pre-evaluaciones de síntomas asistidas por IA, ver sus recetas e historial médico. Los doctores gestionan citas, registran consultas, crean recetas y consultan clasificaciones de prioridad generadas por IA.

El sistema está compuesto por cuatro capas:

| Capa | Tecnología | Función |
|------|-----------|---------|
| Backend | Laravel 12 | API REST, lógica de negocio, autenticación |
| Frontend | Angular 20 | Aplicación web SPA |
| App móvil | Flutter / Dart | Android/iOS |
| IA | Python + FastAPI | Chat conversacional + diagnóstico sklearn |
| Base de datos | PostgreSQL (Neon cloud) | Persistencia compartida dev/prod |

---

## 2. Estructura del repositorio

```
Yoltec/
├── backend/          # Laravel 12 (API REST)
├── frontend/         # Angular 20 (SPA web)
├── mobile/           # Flutter (Android/iOS)
├── IA/               # Python + FastAPI + scikit-learn + Groq
├── docs/             # Documentación (este archivo)
└── docker-compose.yml
```

---

## 3. Stack tecnológico

### 3.1. Backend – Laravel 12

- **Framework:** Laravel 12
- **Autenticación:** Laravel Sanctum (tokens API)
- **Base de datos:** PostgreSQL vía PDO
- **Correo:** SMTP Gmail (dev) / Resend (prod)
- **Notificaciones push:** Firebase Cloud Messaging (FCM)
- **Scheduler:** `citas:notificar-proximas` (hourly) — recordatorio 24h antes de la cita
- **PHP:** 8.2+
- **Bcrypt rounds:** 12

### 3.2. Frontend – Angular 20

- **Framework:** Angular 20.3.0
- **Lenguaje:** TypeScript 5.9.2
- **RxJS:** 7.8.0
- **Gráficas:** Chart.js 4.5.1
- **Estilos:** CSS puro (sin Bootstrap ni Tailwind)
- **Build:** Angular CLI 20.3.6

### 3.3. App móvil – Flutter

- **SDK:** Flutter (Dart ≥3.0)
- **State management:** Provider 6.1.0
- **HTTP:** http 1.1.0
- **Notificaciones:** firebase_messaging 15.1.3 + flutter_local_notifications 18.0.1
- **Storage local:** shared_preferences 2.2.2
- **Imágenes:** image_picker 1.0.7
- **i18n:** flutter_localizations + intl 0.20.2

### 3.4. IA – Python / FastAPI

- **Framework:** FastAPI 0.115.0
- **Servidor:** Uvicorn 0.30.6
- **ML:** scikit-learn 1.5.2, numpy 1.26.4, pandas 2.2.3, joblib 1.4.2
- **LLM:** Groq API (`llama-3.1-8b-instant`) — gratuito
- **Alternativa local:** Ollama (`qwen2.5:14b`)

---

## 4. Arquitectura

### 4.1. Diagrama de alto nivel

```
┌─────────────────────────────────────────────────┐
│              Clientes                           │
│   Angular 20 (web)    Flutter (móvil)           │
└──────────────┬─────────────────┬───────────────┘
               │ HTTP + Bearer   │ HTTP + Bearer
               ▼                 ▼
┌─────────────────────────────────────────────────┐
│          Laravel 12 – API REST                  │
│  Sanctum • Middleware • Controllers • Eloquent  │
└────────────────────┬────────────────────────────┘
                     │ HTTP interno
                     ▼
┌─────────────────────────────────────────────────┐
│        FastAPI – Microservicio IA               │
│   /health  /chat  /predict                      │
│   Groq LLM ← → sklearn RandomForest            │
└─────────────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────┐
│     PostgreSQL – Neon (cloud, compartida)       │
│     dev + producción usan la misma DB           │
└─────────────────────────────────────────────────┘
```

### 4.2. Autenticación y roles

| Rol | Identificador | 2FA | Acceso |
|-----|--------------|-----|--------|
| `alumno` | `numero_control` + NIP | No | `/student-dashboard` |
| `doctor` | `username` + password | Solo en producción (email) | `/doctor-dashboard` |
| `admin` | `username` + password | No | `/admin-dashboard` |

- Los tokens Sanctum se almacenan en `localStorage` (web) y `shared_preferences` (móvil).
- El campo `APP_ENV=local` desactiva el 2FA en desarrollo.
- Dispositivos de confianza: 30 días (tabla `trusted_devices`).
- Rate limiting en login: 5 intentos/minuto (`throttle:5,1`).

---

## 5. Base de datos

### 5.1. Conexión

```
Host:     ep-shy-dawn-amz6fidi.c-5.us-east-1.aws.neon.tech
Puerto:   5432
DB:       neondb
SSL:      require
```

> **IMPORTANTE:** Nunca ejecutar `php artisan migrate:fresh`. La DB es compartida con producción.

### 5.2. Tablas principales

| Tabla | Descripción |
|-------|-------------|
| `users` | Alumnos, doctores y admin. Campos: `numero_control`, `username`, `tipo`, `email`, `password`, `foto_perfil`, `fcm_token`, `tipo_sangre`, `alergias`, `enfermedades_cronicas`, `es_admin` |
| `citas` | Citas médicas. Campos: `clave_cita`, `alumno_id`, `doctor_id`, `fecha_cita`, `hora_cita`, `motivo`, `estatus` (`programada`/`atendida`/`cancelada`/`no_asistio`) |
| `consultas` | Registro de consulta al atender. Campos: `cita_id`, `diagnostico`, `tratamiento`, `observaciones` |
| `bitacoras` | Historial de consultas. Campos: `cita_id`, `alumno_id`, `doctor_id`, `diagnostico`, `tratamiento`, `peso`, `altura`, `temperatura`, `presion_arterial` |
| `recetas` | Recetas médicas (una por cita). Campos: `cita_id`, `alumno_id`, `doctor_id`, `medicamentos`, `indicaciones`, `fecha_emision` |
| `pre_evaluaciones_ia` | Pre-evaluaciones de síntomas. Campos: `cita_id`, `alumno_id`, `sintomas_detectados`, `diagnostico_principal`, `confianza`, `validado_por_doctor` |
| `dias_especiales` | Días festivos o con horario especial gestionados por admin |
| `two_factor_codes` | Códigos 2FA temporales para doctores |
| `trusted_devices` | Dispositivos de confianza (30 días sin 2FA) |
| `personal_access_tokens` | Tokens Sanctum |
| `audit_logs` | Registro de acciones relevantes |
| `password_reset_tokens` | Tokens de recuperación de contraseña |

### 5.3. Migraciones

Las migraciones están en `backend/database/migrations/`. Para aplicarlas:

```bash
php artisan migrate
```

No usan `enum` ni constraints `foreignKey` estrictas para compatibilidad con Neon. La integridad referencial se maneja en la capa de aplicación.

---

## 6. API REST – Endpoints

Base URL local: `http://localhost:8000/api`
Base URL producción: `https://lucid-motivation-production.up.railway.app/api`

Todas las rutas protegidas requieren el header:
```
Authorization: Bearer <token>
```

### 6.1. Rutas públicas

| Método | Ruta | Descripción |
|--------|------|-------------|
| POST | `/login` | Login (max 5 intentos/min) |
| POST | `/forgot-password` | Solicitar recuperación de contraseña |
| POST | `/reset-password` | Resetear contraseña con token |
| POST | `/verify-2fa` | Verificar código 2FA |
| POST | `/resend-2fa` | Reenviar código 2FA |

### 6.2. Auth y perfil

| Método | Ruta | Descripción |
|--------|------|-------------|
| POST | `/logout` | Cerrar sesión |
| GET | `/me` | Datos del usuario autenticado |
| POST | `/fcm-token` | Registrar token FCM |
| GET/PUT | `/perfil` | Ver/actualizar perfil |
| POST | `/perfil/foto` | Subir foto de perfil |
| POST | `/perfil/cambiar-password` | Cambiar contraseña |

### 6.3. Citas

| Método | Ruta | Acceso |
|--------|------|--------|
| GET | `/citas` | Alumno: sus citas. Doctor: todas |
| GET | `/citas/disponibilidad` | Disponibilidad del calendario |
| POST | `/citas` | Agendar cita |
| GET | `/citas/{id}` | Detalle de cita |
| POST | `/citas/{id}/cancelar` | Cancelar cita |
| PUT | `/citas/{id}/reprogramar` | Reprogramar (solo doctor) |
| POST | `/citas/{id}/atender` | Marcar como atendida (solo doctor) |
| POST | `/citas/{id}/no-asistio` | Marcar no asistió (solo doctor) |
| POST | `/citas/{id}/consulta` | Registrar consulta (solo doctor) |
| GET | `/citas/{id}/consulta` | Ver consulta |

### 6.4. Historial y perfil médico

| Método | Ruta | Descripción |
|--------|------|-------------|
| GET/PUT | `/perfil-medico` | Perfil médico propio |
| GET | `/perfil-medico/historial` | Historial médico propio |
| GET | `/perfil-medico/alumno/{id}` | Perfil médico de un alumno (doctor) |
| GET | `/perfil-medico/alumno/{id}/historial` | Historial médico de un alumno (doctor) |

### 6.5. Bitácoras, recetas, estadísticas

| Método | Ruta | Acceso |
|--------|------|--------|
| GET | `/bitacoras` | Alumno: las suyas. Doctor: todas |
| POST/PUT/GET | `/bitacoras/{id}` | CRUD (doctor) |
| GET | `/recetas` | Alumno: las suyas. Doctor: todas |
| POST/PUT/GET | `/recetas/{id}` | CRUD (doctor) |
| GET | `/estadisticas` | Dashboard del doctor (solo doctor) |

### 6.6. IA – Pre-evaluación de síntomas

| Método | Ruta | Descripción |
|--------|------|-------------|
| POST | `/pre-evaluacion/chat` | Chat conversacional con Groq |
| GET | `/pre-evaluacion/preguntas` | Preguntas de síntomas |
| GET | `/pre-evaluacion` | Listar pre-evaluaciones |
| POST | `/pre-evaluacion` | Crear pre-evaluación |
| GET | `/pre-evaluacion/{id}` | Detalle |
| POST | `/pre-evaluacion/{id}/validar` | Validar diagnóstico (doctor) |
| GET | `/pre-evaluacion/pendientes` | Pendientes por validar (doctor) |

### 6.7. IA – Clasificación de prioridad (solo doctor)

| Método | Ruta | Descripción |
|--------|------|-------------|
| GET | `/ia/priority/info` | Info del modelo |
| GET | `/ia/priority/pendientes` | Alumnos pendientes |
| POST | `/ia/priority/clasificar/{citaId}` | Clasificar alumno |

### 6.8. Admin

| Método | Ruta | Descripción |
|--------|------|-------------|
| GET/POST | `/admin/alumnos` | Listar/crear alumnos |
| PUT/DELETE | `/admin/alumnos/{id}` | Editar/eliminar alumno |
| GET/POST | `/admin/doctores` | Listar/crear doctores |
| PUT/DELETE | `/admin/doctores/{id}` | Editar/eliminar doctor |
| GET/POST | `/admin/calendario` | Listar/crear días especiales |
| DELETE | `/admin/calendario/{id}` | Eliminar día especial |

---

## 7. Backend – Lógica de negocio

### 7.1. Calendario de citas

- **Días hábiles:** lunes a sábado (domingos siempre inhabilitados)
- **Horario:** 8:00 – 17:00 en intervalos de 15 minutos (36 slots por día)
- **Disponibilidad:** verde (≥50% libre), amarillo (<50%), rojo (lleno)
- **Auto-cancelación:** citas `programada` con fecha/hora pasada se cancelan automáticamente al consultar disponibilidad
- **Días especiales:** gestionados en tabla `dias_especiales` (festivos, horario reducido)

### 7.2. Reglas de citas

- Un slot es exclusivo: nadie más puede tomarlo mientras esté `programada`
- Solo el alumno dueño o un doctor puede cancelar su cita
- No se puede cancelar una cita `atendida`
- El doctor puede agendar citas a nombre de un alumno enviando `numero_control`
- `clave_cita` se genera con formato `CITA-YYYYMMDD-XXXXXX` (único)

### 7.3. Flujo de consulta médica

```
Cita programada
    → Doctor marca "Atender"  (estatus = atendida)
    → Doctor registra Consulta (diagnóstico, tratamiento, observaciones)
    → Doctor puede crear Receta
    → Alumno ve historial + receta
```

### 7.4. Notificaciones

- **Email 24h antes:** comando `php artisan citas:notificar-proximas` programado cada hora
- **Push FCM:** al confirmar, cancelar, reprogramar una cita y en el recordatorio

### 7.5. Controladores principales

| Controlador | Responsabilidad |
|-------------|-----------------|
| `AuthController` | Login, logout, 2FA, me |
| `CitaController` | CRUD citas, disponibilidad, reprogramación |
| `ConsultaController` | Registro de consulta médica |
| `BitacoraController` | Historial con filtros y CSV |
| `RecetaController` | Recetas (una por cita) |
| `PerfilController` | Foto, datos personales, contraseña |
| `PerfilMedicoController` | Tipo sangre, alergias, enfermedades |
| `PreEvaluacionIAController` | Chat IA y gestión de pre-evaluaciones |
| `IAPriorityController` | Clasificación alta/baja prioridad |
| `EstadisticasController` | Métricas para dashboard doctor |
| `AdminController` | CRUD alumnos y doctores |
| `CalendarioAdminController` | Gestión días especiales |
| `PasswordResetController` | Recuperación de contraseña |

---

## 8. Frontend – Angular

### 8.1. Rutas

| Ruta | Componente | Guard |
|------|-----------|-------|
| `/login` | `LoginComponent` | — |
| `/verify-2fa` | `Verify2faComponent` | — |
| `/forgot-password` | `ForgotPasswordComponent` | — |
| `/reset-password` | `ResetPasswordComponent` | — |
| `/student-dashboard` | `StudentDashboardComponent` | `AuthGuard` (rol: alumno) |
| `/doctor-dashboard` | `DoctorDashboardComponent` | `AuthGuard` (rol: doctor) |
| `/admin-dashboard` | `AdminDashboardComponent` | `AuthGuard` (rol: admin) |

### 8.2. Estructura de componentes

```
frontend/src/app/
├── login/
├── verify-2fa/
├── forgot-password/
├── reset-password/
├── student-dashboard/           ← vista alumno (citas, IA, recetas, historial, perfil)
├── doctor-dashboard/
│   ├── doctor-dashboard.component.*   ← wrapper, solo enruta secciones
│   └── components/
│       ├── doctor-header/             ← barra de navegación
│       ├── doctor-inicio/             ← citas del día + próxima cita
│       ├── doctor-citas/              ← calendario, filtros, reprogramar, modales
│       ├── doctor-bitacoras/          ← historial + CSV export
│       ├── doctor-estadisticas/       ← gráficas Chart.js
│       ├── doctor-recetas/            ← recetas digitales
│       ├── doctor-pre-evaluaciones/   ← validar/descartar diagnósticos IA
│       └── doctor-ia-prioridad/       ← clasificación alta/baja prioridad
├── admin-dashboard/
├── guards/
│   └── auth.guard.ts
└── interceptors/
    └── auth.interceptor.ts
```

### 8.3. Servicios

- `AuthService`: login, logout, token, redirección por rol
- `AuthInterceptor`: inyecta `Authorization: Bearer` en cada request; maneja 401/403
- `AuthGuard`: verifica token + rol antes de activar ruta
- `CalendarioAdminService`: días especiales (admin)

---

## 9. Microservicio IA

### 9.1. Endpoints

**`GET /health`** — Verifica que el modelo y el LLM estén disponibles.
```json
{ "model_sklearn_loaded": true, "llm_provider": "groq", "llm_available": true }
```

**`POST /chat`** — Chat conversacional para pre-evaluación de síntomas.
```json
// Request
{ "messages": [{ "role": "user", "content": "tengo fiebre y tos" }] }

// Response
{
  "message": "respuesta del asistente",
  "finished": true,
  "diagnostico": {
    "diagnostico_principal": "Gripe",
    "confianza": 0.82,
    "sintomas_detectados": ["fiebre", "tos"],
    "posibles_enfermedades": ["Gripe", "Resfriado", "COVID-19"],
    "recomendacion": "Consulta médica en las próximas 24 horas"
  }
}
```

**`POST /predict`** — Predicción directa por síntomas (legacy/formulario).

### 9.2. Flujo del chat IA

1. Groq entrevista al alumno en lenguaje natural (sistema empático en español)
2. Tras 3-5 respuestas, extrae síntomas estructurados
3. El modelo sklearn (RandomForest) predice la enfermedad con porcentaje de confianza
4. Se devuelven los 3 diagnósticos más probables y una recomendación:
   - ≥75% confianza → urgente
   - 50-75% → consulta en 24h
   - 30-50% → esperar y observar
   - <30% → consultar médico

### 9.3. Síntomas reconocidos (33)

`fiebre`, `tos`, `tos_seca`, `dolor_garganta`, `congestion_nasal`, `estornudos`, `dolor_cabeza`, `dolor_cuerpo`, `cansancio`, `nauseas`, `vomito`, `diarrea`, `dolor_abdominal`, `perdida_apetito`, `perdida_olfato`, `erupcion_piel`, `picazon`, `ojos_rojos`, `lagrimeo`, `dolor_orinar`, `frecuencia_urinar`, `mareos`, `palpitaciones`, `sensibilidad_luz`, `dolor_articulaciones`, `sudoracion`, `escalofrios`, `dolor_espalda`, `dificultad_respirar`, `fiebre_alta`, `sangre_orina`, `orina_turbia`, `confusion`, `rigidez_cuello`

### 9.4. Archivos generados (NO en git)

| Archivo | Descripción |
|---------|-------------|
| `IA/model.pkl` | Modelo sklearn entrenado |
| `IA/label_encoder.pkl` | Codificador de etiquetas de enfermedades |
| `IA/feature_names.json` | Lista de síntomas usados en entrenamiento |

Se regeneran con:
```bash
cd IA && python train_model_light.py   # ~30 segundos
```

---

## 10. App móvil – Flutter

### 10.1. Configuración de la URL base

Archivo: `mobile/lib/services/api_service.dart`

```dart
// Desarrollo local (cambiar a la IP de tu máquina)
static const String baseUrl = 'http://192.168.X.X:8000';

// Producción (APK release)
static const String baseUrl = 'https://lucid-motivation-production.up.railway.app';
```

> El `AndroidManifest.xml` tiene `usesCleartextTraffic="true"` para permitir HTTP en desarrollo.

### 10.2. Servicios disponibles

| Servicio | Descripción |
|---------|-------------|
| `api_service.dart` | Cliente HTTP base, headers, métodos CRUD |
| `auth_service.dart` | Login, logout, 2FA, gestión de token |
| `cita_service.dart` | Operaciones de citas |
| `bitacora_service.dart` | Historial de citas |
| `receta_service.dart` | Recetas médicas |
| `pre_evaluacion_service.dart` | Chat conversacional con IA |
| `ia_priority_service.dart` | Clasificación de prioridad |
| `notification_service.dart` | FCM y notificaciones locales |

### 10.3. Pantallas implementadas

- Login + 2FA
- Home (citas del día)
- Agendar cita (calendario)
- Chat IA (pre-evaluación)
- Bitácora
- Recetas
- Perfil médico (editable)
- Cambiar contraseña
- Vista doctor: pacientes, prioridad IA, pre-evaluaciones

---

## 11. Variables de entorno

### Backend (`backend/.env`)

```env
APP_ENV=local              # Cambia a 'production' en Railway
APP_KEY=base64:...
DB_CONNECTION=pgsql
DB_HOST=ep-shy-dawn-amz6fidi.c-5.us-east-1.aws.neon.tech
DB_PORT=5432
DB_DATABASE=neondb
DB_USERNAME=neondb_owner
DB_PASSWORD=<ver contexto_proyecto.md>
DB_SSLMODE=require
MAIL_MAILER=smtp
MAIL_HOST=smtp.gmail.com
MAIL_USERNAME=nespiolin05@gmail.com
MAIL_PASSWORD=<app password>
IA_SERVICE_URL=http://127.0.0.1:5000
FRONTEND_URL=http://localhost:4200
```

### IA (`IA/.env`)

```env
GROQ_API_KEY=<tu key de console.groq.com>
GROQ_MODEL=llama-3.1-8b-instant
LLM_PROVIDER=groq
```

---

## 12. Ejecución del proyecto

### 12.1. Con Docker (recomendado)

```bash
cd /home/nestor/yoltec
docker compose up -d
```

Servicios:
- Backend: `http://localhost:8000`
- Frontend: `http://localhost:4200`
- IA: `http://localhost:5000`

### 12.2. Sin Docker

```bash
# Backend
cd backend
composer install
php artisan migrate        # solo la primera vez
php artisan serve --host=127.0.0.1 --port=8000

# Frontend
cd frontend
npm install
ng serve --host=0.0.0.0 --port=4200

# IA
cd IA
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
python train_model_light.py     # genera model.pkl (~30s)
uvicorn app:app --host=0.0.0.0 --port=5000

# App móvil
cd mobile
flutter pub get
flutter run                     # requiere dispositivo/emulador conectado
```

### 12.3. Generar APK release

```bash
cd mobile
flutter build apk --release
# Output: mobile/build/app/outputs/flutter-apk/app-release.apk
```

---

## 13. Despliegue en producción

### 13.1. URLs

| Servicio | URL |
|----------|-----|
| Frontend | https://frontend-nu-weld-77.vercel.app |
| Backend | https://lucid-motivation-production.up.railway.app |
| IA | https://yoltec-production.up.railway.app |

### 13.2. Plataformas

- **Frontend:** Vercel (deploy automático desde `main`)
- **Backend:** Railway (Root Directory: `/backend`)
- **IA:** Railway (Root Directory: `/IA`, regenera `model.pkl` en cada build)

### 13.3. Variables críticas en Railway

- `APP_ENV=production` (activa 2FA para doctores)
- `GROQ_API_KEY=<key>` (en el servicio IA)
- `MAIL_*` configurado con Resend (solo envía a `nespiolin05@gmail.com` sin dominio verificado)
- Credenciales Neon PostgreSQL

---

## 14. Seguridad

| Mecanismo | Implementación |
|-----------|---------------|
| Autenticación | Laravel Sanctum (Bearer tokens) |
| 2FA | Código por email, solo doctores, solo producción |
| Dispositivos de confianza | 30 días sin 2FA (tabla `trusted_devices`) |
| Rate limiting | `throttle:5,1` en `/login` |
| Hashing | Bcrypt 12 rounds |
| CORS | `CorsMiddleware` en Laravel |
| Roles | Verificación por `tipo` en cada controlador |
| HTTPS | Forzado en producción (Railway + Vercel) |
| Archivos sensibles | `.env`, `firebase-adminsdk.json`, `google-services.json` en `.gitignore` |

---

## 15. Archivos que NO deben subirse a GitHub

| Archivo | Motivo |
|---------|--------|
| `backend/.env` | Credenciales DB + email |
| `IA/.env` | GROQ_API_KEY |
| `IA/model.pkl` | Generado en build (>1MB) |
| `backend/storage/app/firebase-adminsdk.json` | Service account Firebase |
| `mobile/android/app/google-services.json` | Firebase config |
| `scripts/start-ngrok.sh` | Token ngrok hardcodeado |

---

## 16. Credenciales de prueba

| Rol | Usuario | Contraseña | Notas |
|-----|---------|-----------|-------|
| Alumno | `22690495` | NIP: `740270` | Login por número de control |
| Doctor 1 | `doctorOmar` | `doctor123` | 2FA solo en producción |
| Doctor 2 | `doctorCarlos` | `doctor123` | 2FA solo en producción |
| Admin | `admin` | `admin123` | Ruta: `/admin-dashboard` |
