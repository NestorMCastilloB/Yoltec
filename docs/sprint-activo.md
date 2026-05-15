# Sprint Activo

> Una tarea a la vez. Al terminar → /clear y nuevo contexto.
> Completadas → mover a la sección Completados al final.
> Reglas: ver `/home/nestor/yoltec/CLAUDE.md` y `/home/nestor/yoltec/backend/CLAUDE.md`

---

## Tarea actual

**Qué:** —
**Archivo:** —
**Problema:** —
**Esperado:** —

---

## Backend — Bloque 1: Commit de pendientes (inmediato)

Hay 5 archivos del backend modificados sin commitear. Revisar y commitear antes de continuar.

- [ ] Revisar y commitear: `BitacoraController.php`, `CitaController.php`, `EstadisticasController.php`, `RecetaController.php`, `Receta.php`

---

## Backend — Bloque 2: Seguridad (prioridad alta)

- [ ] **Middleware `CheckRole`** — crear `app/Http/Middleware/CheckRole.php` y aplicar en `routes/api.php`:
  - Rutas solo-doctor: `cancelar`, `atender`, `no-asistio`, `reprogramar`, `bitacoras store/update`, `recetas store/update`, `ia/priority/*`, `ia/symptoms/validar`, `estadisticas`
  - Rutas solo-alumno: ninguna aún, pero dejar el middleware listo
- [ ] **Race condition en citas** — `CitaController::store()`: envolver verificación de slot + inserción en `DB::transaction()` con `lockForUpdate()`
- [ ] **Eliminar `CorsMiddleware.php` custom** si existe (tiene ngrok hardcodeado) — CORS ya está correcto en `config/cors.php`
- [ ] **Rate limiting** en `/verify-2fa` y `/resend-2fa` — agregar `throttle:5,1` en `routes/api.php`

---

## Backend — Bloque 3: Refactorizar Controllers → Services (prioridad media)

Regla: Controllers < 80L, lógica de negocio en `app/Services/`. Ver `backend/CLAUDE.md`.

- [ ] `PreEvaluacionIAController` (364L) → extraer a `PreEvaluacionService`
- [ ] `CitaController` (343L) → extraer a `CitaService`
- [ ] `AuthController` (305L) → extraer lógica 2FA a `Auth2FAService`
- [ ] `IASymptomController` (216L) → extraer a `IASymptomService`

---

## Backend — Bloque 4: Ajustes funcionales (prioridad media)

- [ ] **Estadísticas doctor** — verificar que `EstadisticasController` retorna los campos que usa el frontend rediseñado (diagnósticos, evolución mensual, distribución motivos)
- [ ] **Bitácora CSV export** — verificar si `BitacoraController::index()` soporta `?formato=csv` o falta implementarlo
- [ ] **Recetas** — confirmar que los campos del response de `RecetaController` coinciden con el frontend rediseñado (alumno y doctor)
- [ ] **FK cascading en citas** — migración incremental `ON DELETE CASCADE` en pre_evaluaciones, bitácoras y consultas que referencian `citas`

---

## Backend — Bloque 5: Producción (prioridad baja)

- [ ] `IA_SERVICE_URL` en Render apunta a `localhost` → cambiar a `https://yoltec-ia.onrender.com` (variable de entorno en panel de Render, no código)
- [ ] Verificar que responses de citas, recetas y perfil son compatibles con Flutter (consumidos por mobile)

---

## IA (pendiente)

- [ ] Rate limiting `slowapi` 5 req/min
- [ ] Validación input `max_length=5000`
- [ ] CORS middleware
- [ ] Sincronizar `enfermedades_config.json` con `feature_names.json`

---

## Mobile — después de backend (pendiente)

- [ ] Mis Citas: 3 tabs (Próximas, Pasadas, Canceladas)
- [ ] Perfil: sin tabs duplicadas, foto editable
- [ ] Fix estatus `'no_asistio'` en `Cita.estatusTexto`
- [ ] Fix catch silencioso en `PreEvaluacionService`
- [ ] Crear clase `Receta` tipada

---

## Completados

### Frontend — Admin
- [x] Login Admin — ReactiveForm, toast 401/403, diseño DS v2
- [x] Panel Admin — sidebar, stats con skeleton, preview usuarios + días próximos (forkJoin)
- [x] Usuarios Admin — tabs Todos/Alumnos/Doctores, búsqueda unificada, tabla con rol-badge
- [x] Días Especiales Admin — calendario Lun-Sáb, colores por tipo (festivo/vacaciones/reducido), formulario inline
- [x] Optimizaciones admin-dashboard: OnPush, cache de datos, getters→propiedades, memoización Intl

### Frontend — Doctor
- [x] `doctor/citas/` — rediseño DS v2
- [x] `doctor/prioridad-ia/` — manejo error PHP, botón reintentar
- [x] `doctor/estadisticas/` — ngOnInit + skeleton loader
- [x] `doctor/pre-evaluaciones/` — validar/descartar con modal
- [x] `doctor/recetas/` — lista + drawer detalle
- [x] `doctor/nueva-cita/` — flujo 3 pasos
- [x] `doctor/bitacoras/` — rediseño DS v2

### Frontend — Alumno
- [x] `student/mis-citas/` — 3 tabs: Próximas, Pasadas, Canceladas
- [x] `student/dashboard/` — bienvenida + próxima cita + accesos rápidos
- [x] `shared/agendar-cita/` — @Input() modo alumno/doctor + paso buscar alumno
- [x] `student/pre-evaluacion-ia/` — chat + resultados
- [x] `student/perfil/` — info médica + foto editable

### Frontend — Bugs resueltos
- [x] `user.service.ts` key `'token'` → `'auth_token'`
- [x] `doctor-header` key `'theme'` → `'dark_mode'`
- [x] Login: media query móvil
- [x] 2FA: regex `/^\d{6}$/`
- [x] `setTimeout(1200)` doctor-citas → cerrar en HTTP response

### Setup y transversal
- [x] Graphify instalado y configurado
- [x] CLAUDE.md optimizados (v3)
- [x] Design System v2 — tokens.css, fuentes locales, dark mode
- [x] Migración Railway → Render (backend + IA), Vercel (frontend)
