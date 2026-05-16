# Sprint Activo

> Una tarea a la vez. Al terminar → /clear y nuevo contexto.
> Completadas → mover a la sección Completados al final.
> Reglas: ver `/home/nestor/yoltec/CLAUDE.md` y `/home/nestor/yoltec/backend/CLAUDE.md`

---

## Tarea actual

**Qué:** Diagnosticar por qué la IA no funciona en el alumno web
**Archivo:** `frontend/src/app/components/student/pre-evaluacion-ia/`, `backend/app/Http/Controllers/PreEvaluacionIAController.php`, `IA/main.py`
**Problema:** El alumno no puede usar el chat de pre-evaluación IA — desconocemos si es timeout, CORS, env var, o token Groq
**Esperado:** Identificar la causa raíz con DevTools + logs Render → fix mínimo

---

# FASE 3 — Web funcional end-to-end (junio 2026)

Objetivo: web (admin + doctor + alumno + IA) funcional en producción sin bugs bloqueantes.

---

## Bloque 1 — IA Web operativa (PRIORIDAD MÁXIMA)

- [ ] **Diagnosticar IA alumno**: abrir DevTools en alumno → click "Pre-evaluación IA" → ver Network. Posibles causas:
  - Backend timeout (IA en cold start Render ~50s, backend timeout 20s)
  - `IA_SERVICE_URL` mal configurado en Render panel (sigue apuntando a localhost)
  - Groq API key vencido/inválido
  - CORS en IA bloqueando origin de Vercel
- [ ] **Fix encontrado**: aplicar el cambio mínimo según el diagnóstico
- [ ] **Loading state UX**: mientras IA está cold-starting, mostrar "Conectando con el asistente (puede tardar 30s la primera vez)"
- [ ] **Sincronizar** `IA/enfermedades_config.json` con `IA/feature_names.json` (si están desfasados)

---

## Bloque 2 — IA hardening (después del bloque 1)

- [ ] **Rate limiting** con `slowapi`: 5 req/min por IP en `/chat`
- [ ] **Validación input** `max_length=5000` en `ChatMessage.content`
- [ ] **CORS middleware** FastAPI con orígenes explícitos (Vercel + localhost)
- [ ] **Health endpoint** `/health` que retorne `{status:'ok', model:'loaded'}` — usado por keep-alive de Render

---

## Bloque 3 — Backend hardening pendiente

- [ ] **Middleware `CheckRole`** auditar `routes/api.php` — verificar que TODAS las rutas sensibles tienen `role:doctor` o `role:admin`
- [ ] **Eliminar `CorsMiddleware.php`** custom si existe (ngrok hardcodeado) — CORS ya está en `config/cors.php`
- [ ] **Rate limiting** en `/verify-2fa` y `/resend-2fa` — confirmar que `throttle:5,1` está aplicado

---

## Bloque 4 — Pruebas end-to-end (smoke test antes de entregar)

Todas en producción (Vercel + Render).

- [ ] **Admin**: login → crear alumno → crear doctor → marcar día festivo → marcar día reducido con cierre 12:00
- [ ] **Alumno**: login → agendar cita en día reducido con hora antes de 12:00 (debe permitir) → intentar a 12:30 (debe rechazar) → cancelar
- [ ] **Alumno**: pre-evaluación IA → chat completo → ver diagnóstico → ver pre-evaluación en perfil
- [ ] **Doctor**: login → ver cita programada → atender → llenar consulta → emitir receta
- [ ] **Doctor**: bitácora con filtros → exportar CSV
- [ ] **Doctor**: estadísticas → ver gráficos cargados
- [ ] **Doctor**: prioridad IA → ver score → reintento si falla

---

## Bloque 5 — Performance y polish (si hay tiempo)

- [ ] **Keep-alive Render**: cron-job.org cada 10 min ping a backend + IA para evitar cold starts
- [ ] **Refactor** `PreEvaluacionIAController` (>300L) → extraer a service
- [ ] **Refactor** `CitaController` → mover lógica restante a `CitaService`
- [ ] **Documentar** endpoints reales del backend (descartar zombies como `/api/slots` viejos)

---

## Mobile — fuera de fase 3, post-semestre

- [ ] Mis Citas: 3 tabs (Próximas, Pasadas, Canceladas)
- [ ] Perfil: sin tabs duplicadas, foto editable
- [ ] Fix estatus `'no_asistio'` en `Cita.estatusTexto`
- [ ] Fix catch silencioso en `PreEvaluacionService`
- [ ] Crear clase `Receta` tipada

---

## Completados

### Fase 2 — Polish, fixes y features (mayo 2026)

#### Sesión 2026-05-15/16 — PRs #22-#28 mergeados
- [x] **PR #22** Filtro citas doctor atenúa calendario semanal + KPI Pendientes filtrado
- [x] **PR #23** Iconos SVG inline en sidebar doctor + alumno (reemplazo de Unicode tofu) + fix `doctor-header.ts` con themeService/userMenuOpen
- [x] **PR #24** Campo `genero` en users + saludo dinámico Bienvenido/a + reactivo (sin re-login) vía `AuthService.updateCurrentUser`
- [x] **PR #25** Polish completo Design System v2 (admin, doctor, alumno — 38 archivos, ~4300 líneas) + fix admin-dashboard días pasados
- [x] **PR #26** Bloqueo de días pasados en calendario de días especiales (admin) + selector de tipo + tabla con etiqueta + fix routing `/admin/calendario`
- [x] **PR #27** Backend rechaza días `holiday/vacation` en `validarHorario` + invalidación de cache disponibilidad + banner aviso para días reducidos
- [x] **PR #28** Hora de cierre configurable en días reducidos + bloqueo de slots posteriores + fix completo del componente shared agendar-cita (endpoints zombi → endpoints reales) + endpoint `/api/alumnos/buscar` + FCM defer para acelerar agendar/cancelar/reprogramar
- [x] Auto-cancelación de citas pasadas (lazy fallback al scheduler de Render que no corre cron) — `CitaService::marcarPasadasComoNoAsistio()`
- [x] Migración FK CASCADE en `bitacoras` y `recetas` referenciando `citas`
- [x] Paginación en historial de citas doctor (client-side 10/página) + paginación recetas doctor (backend 15/página)
- [x] Migración `add_genero_to_users` + `add_hora_cierre_to_dias_especiales`

#### Frontend — Admin
- [x] Login Admin — ReactiveForm, toast 401/403, diseño DS v2
- [x] Panel Admin — sidebar, stats con skeleton, preview usuarios + días próximos (forkJoin)
- [x] Usuarios Admin — tabs Todos/Alumnos/Doctores, búsqueda unificada, tabla con rol-badge
- [x] Días Especiales Admin — calendario Lun-Sáb, colores por tipo, formulario inline
- [x] Optimizaciones admin-dashboard: OnPush, cache de datos, getters→propiedades

#### Frontend — Doctor
- [x] `doctor/citas/` — rediseño DS v2 + filtro atenúa calendario
- [x] `doctor/prioridad-ia/` — manejo error PHP, botón reintentar
- [x] `doctor/estadisticas/` — ngOnInit + skeleton loader
- [x] `doctor/pre-evaluaciones/` — validar/descartar con modal
- [x] `doctor/recetas/` — lista + drawer detalle + paginación
- [x] `doctor/nueva-cita/` — flujo 3 pasos
- [x] `doctor/bitacoras/` — rediseño DS v2
- [x] `doctor/header/` — sidebar SVG + user dropdown + modo oscuro

#### Frontend — Alumno
- [x] `student/mis-citas/` — 3 tabs: Próximas, Pasadas, Canceladas
- [x] `student/dashboard/` — bienvenida dinámica + próxima cita + accesos rápidos + sidebar SVG
- [x] `shared/agendar-cita/` — funcional alumno+doctor con endpoints reales
- [x] `student/pre-evaluacion-ia/` — UI lista (pendiente diagnóstico funcional → ver Bloque 1)
- [x] `student/perfil/` — info médica + foto editable + selector género

#### Frontend — Bugs resueltos (fase 1-2)
- [x] `user.service.ts` key `'token'` → `'auth_token'`
- [x] `doctor-header` key `'theme'` → `'dark_mode'`
- [x] Login: media query móvil
- [x] 2FA: regex `/^\d{6}$/`
- [x] `setTimeout(1200)` doctor-citas → cerrar en HTTP response

#### Backend
- [x] Auto-cancelación citas pasadas con cache throttle 5min
- [x] FK CASCADE bitacoras/recetas → citas
- [x] Validación días especiales en `validarHorario`
- [x] Hora de cierre para días reducidos
- [x] Endpoint `/api/alumnos/buscar` (doctor)
- [x] FCM defer post-response (acelera agendar ~2-5s)
- [x] Cache invalidation al guardar/borrar día especial
- [x] Fix routing `/admin/dias-especiales` → `/admin/calendario`

#### Setup y transversal
- [x] Graphify instalado y configurado
- [x] CLAUDE.md optimizados (v3)
- [x] Design System v2 — tokens.css, fuentes locales, dark mode
- [x] Migración Railway → Render (backend + IA), Vercel (frontend)
- [x] Migraciones de BD: `add_genero_to_users`, `add_hora_cierre_to_dias_especiales`, `add_cascade_fk_to_bitacoras_recetas`
