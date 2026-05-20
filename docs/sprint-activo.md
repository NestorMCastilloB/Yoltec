# Sprint Activo

> Una tarea a la vez. Al terminar → /clear y nuevo contexto.
> Completadas → mover a la sección Completados al final.
> Reglas: ver `/home/nestor/yoltec/CLAUDE.md` y `/home/nestor/yoltec/backend/CLAUDE.md`

---

## Tarea actual

**Qué:** Bloque 4 — Smoke test end-to-end en producción (Vercel + Render)
**Esperado:** Validar flujos completos admin/alumno/doctor + IA sin errores

---

# FASE 3 — Web funcional end-to-end (junio 2026)

Objetivo: web (admin + doctor + alumno + IA) funcional en producción sin bugs bloqueantes.

---

## Bloque 1 — IA Web operativa ✅ COMPLETADO

- [x] **Diagnosticar IA alumno** — causa: endpoint mal (`/api/ia/chat` vs `/api/pre-evaluacion/chat`) + faltaba `cita_id`
- [x] **Fix endpoint + cita_id** — PR #29
- [x] **UX sin cita** — bloqueo con CTA "Agendar cita" + selector cuando hay varias citas + lectura modo pre-eval existente
- [x] **Eliminar `enfermedades_config.json`** — era código muerto, no lo usaba `app.py` ni `train_model_light.py`
- [x] **Loading state UX cold start** — typing indicator + hint "Conectando con el asistente… puede tardar hasta 30s la primera vez" después de 8s

---

## Bloque 2 — IA hardening ✅ COMPLETADO

- [x] **Rate limiting** con `slowapi`: 10/min por IP en `/chat` y `/predict` (>5/min del plan original, aceptable)
- [x] **Validación input** `max_length=5000` en `ChatMessage.content`, `max_length=50` en `messages[]` y `respuestas{}`
- [x] **CORS middleware** FastAPI con orígenes explícitos (Vercel + localhost)
- [x] **Health endpoint** `/health` retorna `{status, model_sklearn_loaded, llm_provider, llm_model, llm_available}` — 503 si modelo no cargado
- [x] **Migrar `@app.on_event` a `lifespan`** (FastAPI moderno)

---

## Bloque 3 — Backend hardening ✅ COMPLETADO

- [x] **Auditoría CheckRole en `routes/api.php`** — todas las rutas sensibles tienen `role:doctor` o `role:admin`. Las rutas mixtas `/perfil-medico/alumno/{id}` mantienen validación interna en controller (alumno usa su id, doctor pasa id explícito) — protección existente.
- [x] **`CorsMiddleware` custom** ya no existe (eliminado en sesiones anteriores). CORS solo en `config/cors.php` con orígenes explícitos (sin wildcards, sin ngrok).
- [x] **Rate limiting** `throttle:5,1` confirmado en `/verify-2fa`, `/resend-2fa`, `/login`.
- [x] **Eliminado `EnsureIsAdmin.php`** — duplicaba a `CheckRole` con param admin. Ahora `/admin/*` usa `role:admin` (un solo middleware para todos los roles).

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

### Fixes encontrados durante smoke test (PRs #37-#40)
- [x] **2FA en producción**: `MAIL_MAILER` no estaba en Render (default `log`, emails no llegaban) — agregado `MAIL_MAILER=resend`, `MAIL_FROM_ADDRESS=onboarding@resend.dev`, `MAIL_FROM_NAME=Yoltec`
- [x] **Resend workaround**: drop `UNIQUE(email)`, seeder unifica email admin+doctores a `nespiolin05@gmail.com` (Resend free tier sin dominio)
- [x] **localStorage corrupto**: `getStoredUser()` crasheaba con `JSON.parse("undefined")` — agregado try/catch
- [x] **Perfil género/foto**: `PerfilMedicoController::show()` no incluía `genero` ni `foto_perfil` en la respuesta
- [x] **Dark mode**: tokens CSS en admin días-especiales + select options en doctor pre-evaluaciones
- [x] **Datos de prueba**: seeder limpia alergias/enfermedades del alumno test

---

## Bloque 5 — Performance y polish (si hay tiempo)

- [x] **Keep-alive Render**: cron-job.org cada 10 min ping a backend + IA para evitar cold starts
- [x] **Refactor** `PreEvaluacionIAController` (ya estaba refactorizado, 166L)
- [x] **Refactor** `CitaController` → 250L → 184L (PR #46) + fix Reprogramar visible (PR #47) + bloquear horas pasadas (PR #48)
- [x] **Documentar** endpoints reales del backend → [docs/endpoints.md](endpoints.md)

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
