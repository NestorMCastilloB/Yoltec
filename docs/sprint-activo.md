# Sprint Activo

> Una tarea a la vez. Al terminar → /clear y nuevo contexto.
> Completadas → mover a docs/sprints/completados.md

## Tarea actual

**Qué:** [una línea]
**Archivo:** [ruta exacta]
**Problema:** [qué falla o falta]
**Esperado:** [resultado concreto]

---

## Frontend — Vistas alumno (prioridad alta)

- [x] `student/mis-citas/` — 3 tabs: Próximas, Pasadas, Canceladas
- [x] `student/dashboard/` — bienvenida + próxima cita + accesos rápidos
- [ ] `shared/agendar-cita/` — @Input() modo alumno/doctor + paso buscar alumno
- [x] `student/pre-evaluacion-ia/` — chat + resultados
- [ ] `student/perfil/` — info médica + foto editable

## Frontend — Correcciones doctor (prioridad alta)

- [x] `doctor/prioridad-ia/` — manejar error PHP, botón reintentar
- [ ] `doctor/estadisticas/` — cargar en ngOnInit, skeleton loader
- [ ] `doctor/pre-evaluaciones/` — validar/descartar con modal
- [ ] `doctor/recetas/` — rediseño lista + drawer detalle

## Frontend — Bugs (prioridad alta)

- [x] `user.service.ts` key `'token'` → `'auth_token'` (ya estaba corregido)
- [x] `doctor-header` key `'theme'` → `'dark_mode'` (ya estaba corregido)
- [x] Login: media query móvil
- [x] 2FA: regex `/^\d{6}$/`
- [x] `setTimeout(1200)` doctor-citas → cerrar en HTTP response

## Backend — Seguridad (prioridad media)

- [ ] Rutas `/admin/*` con middleware `CheckRole`
- [ ] CORS: quitar wildcards, dominios exactos
- [ ] Eliminar `CorsMiddleware.php` custom
- [ ] Rate limiting en `/verify-2fa` y `/resend-2fa`
- [ ] `lockForUpdate()` en reserva de slots

## IA (prioridad media)

- [ ] Rate limiting `slowapi` 5 req/min
- [ ] Validación input `max_length=5000`
- [ ] CORS middleware
- [ ] Sincronizar `enfermedades_config.json` con `feature_names.json`

## Mobile — después de terminar web

- [ ] Mis Citas: 3 tabs
- [ ] Perfil: sin tabs duplicadas, foto editable
- [ ] Fix estatus `'no_asistio'` en `Cita.estatusTexto`
- [ ] Fix catch silencioso en `PreEvaluacionService`
- [ ] Crear clase `Receta` tipada

---

## Completados

- [x] Graphify instalado y configurado
- [x] CLAUDE.md optimizados (v3)
- [x] Design System completo web + móvil en Claude Design
