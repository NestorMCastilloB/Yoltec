# Endpoints — Backend Yoltec

Base URL local: `http://127.0.0.1:8000/api`
Base URL prod: `https://yoltec-backend.onrender.com/api`

Auth: Sanctum `Authorization: Bearer {token}` (24h). Todo lo de "Protegidas" requiere token.

Roles: `alumno`, `doctor`, `admin`.

---

## Públicas

| Método | Ruta | Throttle | Descripción |
|--------|------|----------|-------------|
| GET | `/health` | — | Health check (status + timestamp) |
| POST | `/login` | 5/min | Login. Devuelve token o reto 2FA |
| POST | `/forgot-password` | 5/10min | Envía email con link de reset |
| POST | `/reset-password` | 5/10min | Cambia contraseña usando token del email |
| POST | `/verify-2fa` | 5/min | Verifica código 2FA (solo doctores en prod) |
| POST | `/resend-2fa` | 5/min | Reenvía código 2FA |

---

## Auth (protegidas)

| Método | Ruta | Descripción |
|--------|------|-------------|
| POST | `/logout` | Revoca token actual |
| GET | `/me` | Datos del usuario logueado |
| POST | `/fcm-token` | Registra token FCM para push |

---

## Perfil (protegidas)

| Método | Ruta | Descripción |
|--------|------|-------------|
| GET | `/perfil` | Datos del perfil propio |
| PUT | `/perfil` | Actualiza perfil |
| POST | `/perfil/foto` | Sube foto de perfil (base64) |
| POST | `/perfil/cambiar-password` | Cambia contraseña con la actual |
| GET | `/sesiones` | Lista sesiones activas |
| DELETE | `/sesiones/{id}` | Revoca una sesión |

---

## Citas (compartidas alumno/doctor)

| Método | Ruta | Descripción |
|--------|------|-------------|
| GET | `/citas` | Lista citas del usuario (alumno → suyas, doctor → todas) |
| GET | `/citas/disponibilidad` | Slots libres del mes (`?month=&year=`) |
| POST | `/citas` | Crea cita. Alumno sin params extras; doctor con `numero_control` o `alumno_id` |
| GET | `/citas/{id}` | Detalle de cita |
| POST | `/citas/{id}/cancelar` | Cancela cita |

## Citas (solo doctor)

| Método | Ruta | Descripción |
|--------|------|-------------|
| PUT | `/citas/{id}/reprogramar` | Cambia fecha/hora |
| POST | `/citas/{id}/atender` | Marca cita como atendida |
| POST | `/citas/{id}/no-asistio` | Marca como no asistida |
| POST | `/citas/{id}/consulta` | Crea consulta médica (diagnóstico + tratamiento) |
| GET | `/citas/{id}/consulta` | Detalle de consulta de la cita |
| GET | `/alumnos/buscar` | Busca alumnos (`?q=` mín 2 chars, máx 20 resultados) |

---

## Perfil médico (protegidas)

| Método | Ruta | Descripción |
|--------|------|-------------|
| GET | `/perfil-medico` | Perfil médico propio (embebido en users) |
| PUT | `/perfil-medico` | Actualiza perfil médico propio |
| GET | `/perfil-medico/historial` | Historial clínico propio |
| GET | `/perfil-medico/alumno/{id}` | (doctor) Perfil médico de un alumno |
| GET | `/perfil-medico/alumno/{id}/historial` | (doctor) Historial de un alumno |

---

## Bitácoras

| Método | Ruta | Rol | Descripción |
|--------|------|-----|-------------|
| GET | `/bitacoras` | todos | Lista bitácoras |
| GET | `/bitacoras/{id}` | todos | Detalle |
| POST | `/bitacoras` | doctor | Crea bitácora |
| PUT | `/bitacoras/{id}` | doctor | Actualiza bitácora |

---

## Recetas

| Método | Ruta | Rol | Descripción |
|--------|------|-----|-------------|
| GET | `/recetas` | todos | Lista recetas |
| GET | `/recetas/{id}` | todos | Detalle |
| POST | `/recetas` | doctor | Crea receta |
| PUT | `/recetas/{id}` | doctor | Actualiza receta |

---

## Pre-evaluaciones IA

| Método | Ruta | Rol | Descripción |
|--------|------|-----|-------------|
| POST | `/pre-evaluacion/chat` | todos | Proxy chat IA (microservicio :5000) |
| GET | `/pre-evaluacion/preguntas` | todos | Preguntas iniciales |
| GET | `/pre-evaluacion` | todos | Lista pre-evaluaciones |
| POST | `/pre-evaluacion` | todos | Guarda pre-evaluación |
| GET | `/pre-evaluacion/pendientes` | doctor | Pre-evaluaciones por validar |
| POST | `/pre-evaluacion/{id}/validar` | doctor | Valida una pre-evaluación |
| GET | `/pre-evaluacion/{id}` | todos | Detalle (wildcard al final) |

---

## IA 1 — Clasificador de Prioridad (solo doctor)

| Método | Ruta | Descripción |
|--------|------|-------------|
| GET | `/ia/priority/info` | Info de los modelos cargados |
| GET | `/ia/priority/pendientes` | Citas pendientes ordenadas por prioridad |
| POST | `/ia/priority/clasificar/{citaId}` | Clasifica una cita |

## IA 2 — Pre-evaluación de Síntomas

| Método | Ruta | Rol | Descripción |
|--------|------|-----|-------------|
| POST | `/ia/symptoms/iniciar/{citaId}` | alumno+doctor | Inicia evaluación |
| POST | `/ia/symptoms/evaluar/{citaId}` | alumno+doctor | Siguiente paso |
| GET | `/ia/symptoms/resultado/{citaId}` | alumno+doctor | Resultado final |
| DELETE | `/ia/symptoms/{citaId}` | alumno+doctor | Cancela evaluación |
| GET | `/ia/symptoms/listado` | doctor | Listado de evaluaciones |
| POST | `/ia/symptoms/validar/{preEvaluacionId}` | doctor | Valida evaluación |

---

## Estadísticas

| Método | Ruta | Rol | Descripción |
|--------|------|-----|-------------|
| GET | `/estadisticas` | doctor | Métricas para dashboard |

---

## Admin (`/api/admin/*`, role:admin)

| Método | Ruta | Descripción |
|--------|------|-------------|
| GET | `/admin/stats` | KPIs admin |
| GET | `/admin/calendario` | Días especiales (vacaciones/festivos) |
| POST | `/admin/calendario` | Crea día especial |
| DELETE | `/admin/calendario/{id}` | Elimina día especial |
| GET | `/admin/alumnos` | Lista alumnos |
| POST | `/admin/alumnos` | Crea alumno |
| PUT | `/admin/alumnos/{id}` | Actualiza alumno |
| DELETE | `/admin/alumnos/{id}` | Elimina alumno |
| GET | `/admin/doctores` | Lista doctores |
| POST | `/admin/doctores` | Crea doctor |
| PUT | `/admin/doctores/{id}` | Actualiza doctor |
| DELETE | `/admin/doctores/{id}` | Elimina doctor |

---

## Notas

- Total endpoints: **57**
- Endpoints eliminados históricos: `/api/slots` (reemplazado por `/citas/disponibilidad`)
- Microservicio IA aparte en `:5000` (FastAPI) — no documentado aquí
- Fuente de verdad: [backend/routes/api.php](../backend/routes/api.php)
