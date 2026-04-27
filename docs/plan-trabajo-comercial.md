# Plan de Trabajo Yoltec - Preparacion para Producto Comercial

**Fecha:** 27 abril 2026
**Deadline academico:** mediados de junio 2026
**Objetivo:** Entregar sistema funcional + preparar base para venta comercial post-semestre

---

## Resumen de Auditoria

Se reviso el sistema completo (5 capas) y se encontraron **~100 hallazgos** en total:

| Capa | Criticos | Altos | Medios | Bajos |
|------|----------|-------|--------|-------|
| Backend Laravel | 6 | 4 | 15 | 7 |
| Frontend Angular | 11 altos | - | 17 | 11 |
| App Movil Flutter | 4 | 2 | 6 | 6 |
| Microservicio IA | 2 | 5 | 5 | 6 |
| Infraestructura | 6 | - | 8 | 6 |

---

## Sprint 1 (25 abr - 5 may) — Seguridad y Sesion

### 1.1 Idle Session Web (NUEVO - solicitado)
- [ ] `auth.service.ts`: agregar idle timeout 30 min con deteccion de actividad
- [ ] Guardar `last_activity` en localStorage; al reabrir tab verificar si expiro
- [ ] Limpiar parametro muerto `recordar_por` / `duracionFija` del login
- [ ] Backend: verificar que Sanctum expiration=1440 funcione como safety net

### 1.2 Mobile Solo Estudiantes (NUEVO - solicitado)
- [ ] `login_screen.dart`: quitar tab Doctor, dejar solo formulario estudiante
- [ ] `home_screen.dart`: quitar rama doctor, siempre mostrar StudentHomeScreen
- [ ] Eliminar directorio `mobile/lib/screens/doctor/`
- [ ] Eliminar pantallas placeholder no usadas (`ia_assistant_screen.dart`, `two_factor_screen.dart`)

### 1.3 Rate Limiting Login (ya planeado)
- [ ] Backend: `throttle:5,1` ya existe en login, agregar a `/verify-2fa` y `/resend-2fa`
- [ ] Backend: bloqueo progresivo (exponential backoff) tras 5 intentos fallidos

### 1.4 Seguridad Critica (encontrado en auditoria)
- [ ] Backend: proteger rutas `/admin/*` con middleware CheckRole (actualmente solo `auth:sanctum`)
- [ ] Backend: restringir CORS a dominios especificos (quitar regex `*.vercel.app`, quitar fallback localhost)
- [ ] Backend: eliminar `CorsMiddleware.php` custom (tiene dominio ngrok hardcodeado), usar solo `config/cors.php`
- [ ] Backend: cambiar `allowed_headers: ['*']` a lista especifica
- [ ] IA: agregar CORS configurado (actualmente sin CORSMiddleware)
- [ ] Scripts: eliminar tokens ngrok hardcodeados de `scripts/start-ngrok.sh` y `scripts/iniciar-yoltec-ia.sh`

### 1.5 Tokens y Autenticacion
- [ ] Backend Sanctum: verificar expiration funciona (config dice 1440 min)
- [ ] Frontend: `auth.interceptor.ts` tiene `isRefreshing` flag muerto - implementar o quitar
- [ ] Mobile: agregar validacion de token expirado en `auth_service.dart._loadStoredAuth()`

---

## Sprint 2 (6-16 may) — Admin UI + Bugs Frontend

### 2.1 Dias Especiales Admin UI (ya planeado)
- [ ] Backend ya tiene `CalendarioAdminController` + tabla `dias_especiales`
- [ ] Crear UI en panel admin para CRUD de dias especiales

### 2.2 Bugs Frontend (encontrados en auditoria)
- [ ] Fix: token header key mismatch en `user.service.ts` (usa `'token'` pero auth guarda `'auth_token'`)
- [ ] Fix: tema inconsistente - `doctor-header` usa localStorage `'theme'`, ThemeService usa `'dark_mode'`
- [ ] Fix: error message menciona "Ollama" en student-dashboard chat (debe ser generico)
- [ ] Fix: login grid `1fr 1fr` se rompe en movil - agregar media query responsive
- [ ] Fix: validacion 2FA acepta caracteres no numericos (falta regex `/^\d{6}$/`)
- [ ] Fix: `setTimeout(1200)` en doctor-citas para cerrar formulario (debe cerrar en response, no timer)
- [ ] Fix: `setTimeout(60)` para scroll chat (usar MutationObserver)
- [ ] Quitar `alert()` en `panel-validacion.component.ts`, usar toast/snackbar

### 2.3 Limpieza de Codigo Muerto
- [ ] Frontend: quitar `recordar_por` de `auth.service.ts` y `duracionFija` de `login.component.ts`
- [ ] Frontend: quitar `totalPendientes` muerto en `doctor-dashboard.component.ts`
- [ ] Frontend: quitar `console.log()` en `documento-medico.service.ts`
- [ ] IA: quitar codigo Ollama no usado en `app.py` (solo se usa Groq)
- [ ] IA: actualizar comentario "Ollama" en `pre_evaluacion_service.dart` -> "Groq"

---

## Sprint 3 (17-27 may) — HU-06 Formulario Consulta + HU-11 Historial Medico

### 3.1 Formulario de Consulta (HU-06) (ya planeado)
- [ ] Doctor llena diagnostico + tratamiento + observaciones al atender cita

### 3.2 Historial Medico Alumno (HU-11) (ya planeado)
- [ ] Tipo de sangre, alergias, enfermedades cronicas
- [ ] Visible para doctor y alumno

### 3.3 Seguridad BD (encontrado en auditoria)
- [ ] Migracion: agregar UNIQUE constraint en `users.email`
- [ ] Migracion: agregar UNIQUE constraint en `citas.clave_cita`
- [ ] Migracion: agregar indices en `citas` (alumno_id, doctor_id, fecha_cita)
- [ ] Migracion: cambiar `citas.estatus` a ENUM ('programada','atendida','cancelada','no_asistio')
- [ ] Migracion: cambiar `users.tipo` a ENUM ('alumno','doctor','admin')
- [ ] Controller: validar email unique en AdminController CRUD
- [ ] Controller: validar doctor_id == user->id en RecetaController
- [ ] Controller: validar doctor owner en `/citas/{id}/consulta`

### 3.4 Mejoras IA (encontrado en auditoria)
- [ ] IA `app.py`: agregar rate limiting con `slowapi` (5 req/min por IP)
- [ ] IA `app.py`: agregar validacion de input (`max_length=5000`, `max_items=50` en ChatRequest)
- [ ] IA `app.py`: no exponer errores internos de Groq al cliente (loggear, retornar mensaje generico)
- [ ] IA `app.py`: `/health` debe retornar 503 si model es None
- [ ] IA: sincronizar `enfermedades_config.json` con `feature_names.json` (sintomas desincronizados)

---

## Sprint 4 (28 may - 7 jun) — IA Prioridad + Mobile + Hardening

### 4.1 IA Clasificacion de Prioridad (ya planeado)
- [ ] Solo visible para doctor en web
- [ ] Etiqueta alta/baja prioridad, no cancela citas

### 4.2 Mobile Sync y Polish
- [ ] Fix: status `'no_asistio'` no manejado en `Cita.estatusTexto` (mobile)
- [ ] Fix: `PreEvaluacionService.cargarHistorial()` catch silencioso
- [ ] Fix: offline cache sin expiracion en `offline_cache_service.dart`
- [ ] Crear modelo `Receta` en Dart (actualmente usa Map<String, dynamic> sin tipo)
- [ ] Cambiar `applicationId` de `com.example.yoltec_mobile` a dominio real
- [ ] Configurar Android release signing (actualmente usa debug key)
- [ ] Cambiar `usesCleartextTraffic="true"` a `false` en AndroidManifest release

### 4.3 Backend Hardening
- [ ] Hashear NIPs en BD (actualmente texto plano) + cambiar login a Hash::check()
- [ ] Cambiar `rand()` a `random_int()` en generacion 2FA
- [ ] Cambiar `md5()` a `Str::random(12)` en `generarClaveCita()`
- [ ] Race condition en slots: usar `lockForUpdate()` en transaccion
- [ ] Mover `autoCancelPastAppointments()` de request web a scheduled command
- [ ] Agregar timeout a HTTP calls hacia IA (actualmente 120s, bajar a 20s)
- [ ] Agregar foreign key cascading en citas (on delete cascade o restrict)

### 4.4 Infra
- [ ] Dockerfiles: pinear versiones de imagenes base (php:8.4.2-fpm-alpine, etc)
- [ ] IA Dockerfile: EXPOSE 5000 (actualmente dice 8080 pero corre en 5000)
- [ ] Backend Dockerfile: quitar sqlite-dev (no se usa, BD es Neon PostgreSQL)
- [ ] Nginx: agregar security headers (X-Frame-Options, X-Content-Type-Options, CSP)
- [ ] Vercel: agregar Cache-Control headers para assets

---

## Sprint 5 (8-15 jun) — Pulido, Tests, Demo (CERO features nuevas)

### 5.1 Testing
- [ ] IA: crear tests basicos (`test_app.py` para /health, /chat, /predict)
- [ ] Backend: test de login (alumno, doctor, admin, credenciales incorrectas)
- [ ] Backend: test de rate limiting
- [ ] Frontend: verificar accesibilidad basica con axe-core
- [ ] Mobile: probar flujo completo sin doctor en dispositivo real

### 5.2 Documentacion Comercial
- [ ] Guia de deployment (Railway + Vercel + Neon)
- [ ] Checklist de seguridad pre-launch
- [ ] Documentacion API (FastAPI ya genera /docs, falta documentar payloads)
- [ ] Procedimiento de backup/restore de BD

### 5.3 Demo
- [ ] Preparar datos de prueba limpios
- [ ] Verificar todo funcione en produccion (Railway + Vercel)
- [ ] Generar APK release final apuntando a produccion

---

## Post-Semestre — Antes de Vender (fuera de deadline academico)

Estos items son necesarios para venta comercial pero no bloquean la entrega academica:

### Seguridad Avanzada
- [ ] Penetration testing formal
- [ ] WAF en Vercel
- [ ] Rotacion automatica de secretos cada 90 dias
- [ ] Limpiar historial git de credenciales con `git-filter-repo`
- [ ] Audit logging completo (quien hizo que, cuando)

### Escalabilidad
- [ ] Monitoring: Sentry para errores, UptimeRobot para uptime
- [ ] Performance: request timeouts en todos los servicios frontend (30s)
- [ ] IA: versionado de modelos sklearn (model_v1.pkl, model_v2.pkl con symlink)
- [ ] BD: server-side pagination para citas (actualmente client-side filter)

### Calidad de Codigo
- [ ] Refactorizar student-dashboard.component.ts (1049 lineas, debe dividirse en 5 componentes)
- [ ] Extraer logica de calendario compartida entre student y doctor
- [ ] Tipado fuerte en admin.service.ts (actualmente usa `any`)
- [ ] CSS: consolidar estilos repetidos (.btn-primary, .logout-btn) en global

### Legal/Comercial
- [ ] Terminos de servicio
- [ ] Politica de privacidad (datos medicos = sensibles)
- [ ] Contrato de licencia de software
- [ ] SLA de uptime definido

---

## Notas

- **DB compartida**: NUNCA ejecutar `migrate:fresh`. Las migraciones nuevas deben ser incrementales.
- **Groq es gratuito** para nuestro volumen. No cambiar a APIs de pago.
- **Credenciales rotadas** el 2026-04-25. No pegar en commits ni chat.
- **model.pkl** se regenera con `python train_model_light.py` (~30s).
