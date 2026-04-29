# Contexto completo — Proyecto Yoltec
> Documento para cargar en un Proyecto de Claude.ai como contexto permanente.
> Fecha de última actualización: 2026-04-29

---

## ¿Qué es Yoltec?

Sistema de gestión de consultorio médico universitario con IA integrada.
Desarrollado por **Nestor** (alumno universitario, carrera de ingeniería en sistemas).
Proyecto académico con deadline: **mediados de junio 2026** (prácticamente terminado).

Repositorio: https://github.com/elnemito001/Yoltec.git

El sistema atiende a **alumnos universitarios** que necesitan citas médicas en el consultorio de su institución.
Los **doctores** gestionan citas, crean recetas y consultan diagnósticos de IA.
El **admin** gestiona usuarios y días especiales del calendario.

---

## Stack tecnológico (NO cambiar sin consultar)

| Capa | Tecnología | Hosting |
|------|-----------|---------|
| Backend | Laravel 12 (PHP) | Render |
| Frontend web | Angular 20 (TypeScript) | Vercel |
| App móvil | Flutter / Dart | APK en GitHub Releases |
| Base de datos | PostgreSQL (Neon cloud) | Neon |
| IA chat | Python 3 + FastAPI + Groq API | Render |
| IA diagnóstico | scikit-learn (HistGradientBoosting) | mismo servicio FastAPI |
| Email | Gmail SMTP (dev) / Resend (prod) | — |
| Push notifications | Firebase Cloud Messaging (FCM) | — |

**IMPORTANTE sobre la IA:** Groq es 100% gratuito para el volumen del proyecto. NO usar OpenAI ni Anthropic ni otras APIs de pago. El modelo Groq es `llama-3.1-8b-instant`.

---

## URLs de producción

| Servicio | URL |
|----------|-----|
| Frontend (Vercel) | https://frontend-nu-weld-77.vercel.app |
| Backend (Render) | https://yoltec-backend.onrender.com |
| Microservicio IA (Render) | https://yoltec-ia.onrender.com |

---

## Credenciales de prueba

| Rol | Usuario | Contraseña | Notas |
|-----|---------|-----------|-------|
| Alumno | `22690495` (número de control) | NIP: `740270` | Nestor Moises Castillo |
| Doctor | `doctorOmar` | `doctor123` | — |
| Doctor 2 | `doctorCarlos` | `doctor123` | — |
| Admin | `admin` | `admin123` | ruta `/admin-dashboard` |

> El 2FA está **desactivado en local** (`APP_ENV=local`). En producción solo los doctores reciben código por email.

---

## Estructura de carpetas

```
Yoltec/
├── backend/          # Laravel 12 — API REST
│   ├── app/Http/Controllers/
│   ├── routes/api.php
│   └── tests/        # Solo tests de ejemplo de Laravel (vacíos)
├── frontend/         # Angular 20 — SPA web
│   └── src/app/
│       ├── login/
│       ├── student-dashboard/
│       ├── doctor-dashboard/
│       └── admin-dashboard/
├── mobile/           # Flutter — Android/iOS/desktop
│   └── lib/
│       ├── services/api_service.dart  # baseUrl — cambiar para dev local
│       └── screens/
├── IA/               # Python FastAPI + sklearn + Groq
│   ├── app.py        # FastAPI principal
│   ├── train_model_light.py  # genera model.pkl (~30s)
│   └── model.pkl     # NO está en git — regenerar con train_model_light.py
└── docs/             # Documentación académica
    ├── entregable_sistema.md
    ├── diagrama_dominio.mmd
    └── diagrama_arquitectura.mmd
```

---

## Cómo correr el proyecto en desarrollo local

> La base de datos ya está en Neon (cloud). **NUNCA ejecutar `migrate:fresh` — destruye datos de producción.**

### Backend — Laravel
```bash
cd backend
composer install
php artisan serve --host=127.0.0.1 --port=8000
```

### Frontend — Angular
```bash
cd frontend
npm install
ng serve --host=0.0.0.0 --port=4200
# Abre http://localhost:4200
```

### IA — Python/FastAPI
```bash
cd IA
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
python train_model_light.py   # solo la primera vez
uvicorn app:app --host=0.0.0.0 --port=5000
```

### App móvil — Flutter
```bash
cd mobile
flutter pub get
flutter run   # requiere dispositivo o emulador
```
Para dev local cambiar `baseUrl` en `mobile/lib/services/api_service.dart` a `http://TU_IP:8000`.

---

## Base de datos — Tablas (PostgreSQL Neon)

11 tablas en total:

| Tabla | Descripción |
|-------|-------------|
| `users` | Alumnos, doctores y admin. Incluye campos de perfil médico: `tipo_sangre`, `alergias`, `enfermedades_cronicas`, `foto_perfil` |
| `citas` | Citas médicas con soft deletes (`deleted_at`) |
| `bitacoras` | Historial de citas: atendida, cancelada, no_asistio |
| `recetas` | Recetas creadas por el doctor |
| `pre_evaluaciones_ia` | Chat de síntomas. Respuestas y síntomas como JSON |
| `consultas` | Formulario de consulta que llena el doctor al atender |
| `dias_especiales` | Días feriados/inhabilitados. Tipos: holiday, vacation, reduced |
| `two_factor_codes` | Códigos 2FA para doctores (válidos 10 min) |
| `trusted_devices` | Dispositivos de confianza (token 30 días) |
| `password_reset_tokens` | Recuperación de contraseña |
| `audit_logs` | Log de acciones del sistema |

---

## Backend — Rutas API clave

```
POST   /login                          # 3 flujos: alumno, doctor, admin
POST   /logout
POST   /verify-2fa                     # Solo doctores en producción
POST   /verify-trusted-device
POST   /forgot-password
POST   /reset-password

GET    /citas                          # Citas del usuario autenticado
POST   /citas                          # Agendar cita
DELETE /citas/{id}                     # Cancelar cita
GET    /citas/disponibles              # Slots libres por fecha
GET    /citas/alumno/{id}              # Citas de un alumno (doctor)
POST   /citas/{id}/no-asistio         # Marcar no asistió

POST   /pre-evaluacion/chat            # Proxy → FastAPI → Groq
POST   /pre-evaluacion/{id}/validar    # Doctor valida/descarta

GET    /ia/priority/pendientes         # Clasificación prioridad alumnos

GET    /recetas                        # Recetas del alumno o del doctor
POST   /recetas                        # Doctor crea receta

GET    /bitacora                       # Historial (doctor: todo, alumno: solo suyas)
GET    /bitacora/export                # Exportar CSV

POST   /consultas                      # Doctor llena formulario de consulta

GET    /admin/usuarios                 # CRUD usuarios
POST   /admin/usuarios
PUT    /admin/usuarios/{id}
DELETE /admin/usuarios/{id}
GET    /admin/calendario               # Días especiales
POST   /admin/calendario
```

---

## Autenticación y seguridad

- **Tokens:** Laravel Sanctum, expiran a las 24h
- **2FA:** Solo doctores, solo en producción. Código 6 dígitos por email, válido 10 min
- **Trusted devices:** Token 30 días guardado en `trusted_devices`
- **Rate limiting:** 5 intentos por minuto en login (`throttle:5,1`)
- **Roles:** alumno / doctor / admin (campo `role` en tabla `users`)
- **2FA desactivado en local:** `APP_ENV=local` salta el 2FA y devuelve token directo

---

## Módulos del sistema

### 1. Login
- **Alumno:** número_control + NIP
- **Doctor:** username + password → 2FA por email (solo producción)
- **Admin:** username + password → ruta `/admin-dashboard`
- Recuperación de contraseña por email

### 2. Calendario de citas
- **Días:** Lunes a sábado (domingos SIEMPRE inhabilitados)
- **Horario:** 8:00am - 5:00pm, intervalos de 15 minutos
- **Colores:** verde (mucha disponibilidad), amarillo (poca), rojo (no disponible/festivo)
- Tiempo pasado: inhabilitado automáticamente
- Reservas exclusivas: si alguien aparta un slot, nadie más puede tomarlo
- Cancelaciones liberan el slot
- Motivo obligatorio al agendar
- Doctor puede agendar Y cancelar citas a nombre de alumnos

### 3. Dashboard Doctor
- Citas del día actual, cita más próxima, totales
- Gráficas Chart.js: barras por mes + donut por estado
- Se actualiza dinámicamente

### 4. IA — Pre-evaluación de síntomas (chat)
**Flujo completo:**
1. Alumno inicia chat → Frontend POST `/pre-evaluacion/chat` con `{cita_id, messages[]}`
2. Laravel (`PreEvaluacionIAController`) → `Http::timeout(120)->post("$IA_SERVICE_URL/chat")`
3. FastAPI → Groq API (`llama-3.1-8b-instant`) con SYSTEM_PROMPT
4. Groq hace preguntas una a la vez (3-5 turnos) → emite `"DIAGNÓSTICO_FINAL:{json}"`
5. FastAPI extrae JSON → sklearn predice enfermedad con % confianza → retorna `{finished:true, diagnostico}`
6. Laravel detecta `finished=true` → `PreEvaluacionIA::create()` con estatus `pendiente`
7. Doctor valida o descarta → POST `/pre-evaluacion/{id}/validar`

Disponible en web y móvil (Flutter).

### 5. IA — Clasificación de prioridad (solo doctor)
**Flujo (solo PHP, sin FastAPI):**
- Implementado en `IAService.php` como `PriorityClassifier`
- Scoring por alumno:
  - Síntomas graves en motivo: +10 pts
  - Síntomas moderados: +5 pts
  - Síntomas leves: +1 pt
  - Inasistencias: -3 pts cada una
  - Cancelaciones: -1 pt cada una
  - Condiciones crónicas: +3 pts
- Umbrales: >=15 = ALTA, >=8 = MEDIA, <8 = BAJA
- **Solo etiqueta, NO cancela ni mueve citas automáticamente**

### 6. Recetas médicas
- Doctor crea receta vinculada a cita y alumno
- Alumno la ve en pantalla (web y móvil)
- **Los PDFs fueron eliminados** (decisión de arquitectura)

### 7. Formulario de consulta
- Doctor llena al momento de atender: diagnóstico, tratamiento, observaciones
- Guarda en tabla `consultas`

### 8. Bitácora
- Historial de citas: atendidas, canceladas, no asistidas
- Filtros por fecha y alumno, paginación
- Exportar CSV
- Doctor ve todo; alumno ve solo sus propias citas

### 9. Panel Admin
- CRUD alumnos y doctores
- Gestión de días especiales del calendario (UI ya implementada)
- Ruta: `/admin-dashboard`

### 10. App móvil Flutter (solo estudiantes)
- Login solo alumno (sin tab de doctor), citas, IA chat, bitácora, recetas, historial médico
- APK release publicado en GitHub Releases v1.2.1
- En release apunta a Render (producción)
- Biometría eliminada — login solo con número de control + NIP
- Para dev local: cambiar `baseUrl` en `mobile/lib/services/api_service.dart`

### 11. Email y notificaciones
- Recordatorio 24h antes de la cita (comando `citas:notificar-proximas`, scheduler hourly)
- 2FA por email para doctores
- Recuperación de contraseña por email
- **Push notifications FCM** — implementadas en móvil para confirmaciones/cancelaciones/recordatorios

### 12. Perfil médico del alumno
- Campos en tabla `users`: tipo_sangre, alergias, enfermedades_cronicas, foto_perfil
- Visible para doctor y alumno
- Foto de perfil opcional

---

## Modelo sklearn (IA diagnóstico)

- **Archivo activo en producción:** `train_model_light.py` → genera `model.pkl` (~7.1MB)
- **Algoritmo:** `HistGradientBoostingClassifier` (200 iteraciones, lr=0.05)
- **Dataset:** 27,000 registros sintéticos, 24 enfermedades, 34 síntomas
- `model.pkl` NO está en git — regenerar con `python train_model_light.py` (~30s)

**Archivo alternativo (NO usado en producción):**
- `train_model.py` — usa dataset real (182MB CSV, 246k registros)
- Algoritmo: `VotingClassifier` (RF + HGB + ExtraTrees)
- Precisión esperada ~90-95% pero el path del CSV está mal en el script
- El pkl sería demasiado grande para Render sin Git LFS

---

## Estado actual — Qué está implementado (todo)

| Módulo | Estado | Notas |
|--------|--------|-------|
| Login (3 roles) | FUNCIONA | 2FA solo en producción |
| Calendario de citas web | FUNCIONA | |
| Calendario de citas móvil | FUNCIONA | |
| Dashboard doctor | FUNCIONA | Gráficas Chart.js |
| IA chat síntomas (Groq) | FUNCIONA | Ver error de producción abajo |
| IA diagnóstico (sklearn) | FUNCIONA | |
| IA clasificación prioridad | FUNCIONA | Solo doctor |
| Recetas médicas web | FUNCIONA | Sin PDF |
| Recetas médicas móvil | FUNCIONA | |
| Formulario de consulta | FUNCIONA | Doctor llena al atender |
| Bitácora web | FUNCIONA | CSV export |
| Bitácora móvil | FUNCIONA | |
| Historial médico alumno | FUNCIONA | tipo_sangre, alergias, crónicas |
| Foto de perfil | FUNCIONA | |
| Panel admin | FUNCIONA | CRUD + días especiales |
| Marcar "no asistió" | FUNCIONA | Manual por doctor |
| Email recordatorio 24h | FUNCIONA | Scheduler hourly |
| 2FA doctores | FUNCIONA | Solo producción |
| Trusted device 30 días | FUNCIONA | |
| Recuperación contraseña | FUNCIONA | Email con Resend |
| Push notifications FCM | FUNCIONA | Móvil |
| Dark mode | FUNCIONA | Toggle en los 3 dashboards |
| Rate limiting login | FUNCIONA | 5 intentos/min |
| Tokens Sanctum 24h | FUNCIONA | |
| App Flutter completa | FUNCIONA | APK v1.2.1 en GitHub Releases, solo estudiantes |

---

## Errores conocidos / bugs en producción

### IA falla en producción (Render backend)
**Problema:** La variable `IA_SERVICE_URL=http://localhost:5000` en el servicio backend de Render apunta a localhost en lugar del servicio IA.
**Fix:** Ir a Render → servicio backend → Variables → cambiar `IA_SERVICE_URL` a `https://yoltec-ia.onrender.com`
**Estado:** Pendiente de aplicar.

### Resend — solo puede enviar a un correo
**Problema:** Sin dominio verificado en Resend, los emails en producción solo pueden enviarse a `nespiolin05@gmail.com`.
**Impacto:** Emails de recuperación de contraseña y recordatorios solo llegan a ese correo.
**Estado:** Aceptado (limitación de plan gratuito).

---

## Lo que NO existe / está fuera de scope

- Auto-registro de alumnos (ya existen en el sistema escolar)
- PDFs / justificantes con firma digital (eliminados)
- Resultados de laboratorio
- Inventario de medicamentos
- Encuestas de satisfacción
- Integración con sistema escolar
- Directorio de médicos por especialidad
- Reprogramar cita (solo cancelar existe; reprogramar como flujo no está)

---

## Tests automatizados

**No hay tests propios escritos.** Solo los archivos de ejemplo que generan los frameworks:
- `backend/tests/Unit/ExampleTest.php` — `assertTrue(true)` (inútil)
- `backend/tests/Feature/ExampleTest.php` — `GET /` (falla porque la ruta no existe)
- `frontend/src/app/app.spec.ts` y 3 archivos spec más — boilerplate de Angular CLI

---

## Flujo de trabajo Git

```bash
git checkout main && git pull
git checkout -b feature/nombre-feature
# desarrollar y probar
git add archivo1 archivo2
git commit -m "feat: descripción breve"
git push origin feature/nombre-feature
# abrir PR en GitHub hacia main
```

**Convención de commits:** `feat:` / `fix:` / `refactor:`
**Rama principal:** `main`

**Colaboradores del repositorio:**
- `elnemito001` (Nestor — dueño)
- `juliancitou`
- `nachocodexx` (profesor — acceso de lectura para revisión académica)
- Nota: aparece "claude" en contributors por commits históricos — no tiene acceso de escritura

---

## Archivos de entorno

### backend/.env (variables importantes)

```
APP_ENV=local                    # Cambia a production en Render
APP_URL=http://localhost:8000
DB_CONNECTION=pgsql
DB_HOST=ep-shy-dawn-amz6fidi.c-5.us-east-1.aws.neon.tech
DB_PORT=5432
DB_DATABASE=neondb
DB_USERNAME=neondb_owner
# DB_PASSWORD y credenciales sensibles: preguntar a Nestor
DB_SSLMODE=require
IA_SERVICE_URL=http://127.0.0.1:5000   # En prod Render: URL del microservicio IA
FRONTEND_URL=http://localhost:4200
```

### IA/.env

```
GROQ_API_KEY=...                 # Obtener gratis en console.groq.com
GROQ_MODEL=llama-3.1-8b-instant
LLM_PROVIDER=groq
```

---

## Decisiones de arquitectura importantes

1. **Sin 2FA en local** — Solo en producción, solo para doctores. `APP_ENV=local` lo salta.
2. **Sin PDFs** — Eliminados por simplicidad. Las recetas se ven en pantalla.
3. **Groq para IA chat** — Gratuito, sin tarjeta de crédito. sklearn para el diagnóstico.
4. **DB en Neon (cloud compartida)** — La misma DB sirve dev y producción. **NUNCA `migrate:fresh`**.
5. **No auto-registro de alumnos** — El admin los da de alta manualmente.
6. **Perfil médico embebido en `users`** — No es tabla separada (tipo_sangre, alergias, etc. son columnas en users).
7. **IA de prioridad solo en PHP** — No usa FastAPI, implementada directamente en `IAService.php`.

---

## Contexto académico / Jira

- Proyecto gestionado en Jira con metodología SCRUM
- Proyecto Jira: Y20I (backlog) + SCRUM (sprints)
- 29 historias de usuario finalizadas en Jira
- 75 subtareas (SCRUM-92 a SCRUM-166) con criterios de aceptación en formato Dado/Cuando/Entonces
- Las historias SCRUM-67 a SCRUM-91 ya tenían criterios desde antes
- Documento entregable académico: `docs/entregable_sistema.md` (25 RF, 8 RNF, diagramas Mermaid)

---

## Preferencias de trabajo

- Comunicación siempre en **español**
- Priorizar que funcione sobre que sea perfecto
- Eliminar código que no sirve, no acumular deuda técnica
- No incluir `Co-Authored-By` en commits
- Siempre verificar que el backend esté corriendo antes de probar el frontend
- No proponer features nuevos ni refactorizaciones si no se pidieron
