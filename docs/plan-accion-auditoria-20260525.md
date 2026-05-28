# Plan de acción — Auditoría 2026-05-25 + Análisis de grafo 2026-05-27

**Insumo:** [auditoria-tecnica-20260525.md](auditoria-tecnica-20260525.md) + knowledge graph (graphify)
**Deadline académico:** mediados de junio 2026 (~2.5 semanas)
**Estrategia:** Resolver críticos bloqueantes + ya planificado, dejar resto para post-semestre

---

## Filosofía del plan

> Funciona en producción para entrega académica, no es un producto comercial.

- **Críticos que tocan datos médicos o auth en producción real** → resolver ya (fase 1).
- **Críticos puramente académicos** (UX rota, archivos grandes) → resolver si rompen demo (fase 2).
- **Medios/bajos** → si hay tiempo, en una jornada de pulido (fase 3).
- **Refactors estructurales** (dividir componentes grandes) → post-semestre.

---

## Fase 1 — Críticos bloqueantes ✅ COMPLETADA

> PRs #64 (IA), #65 (backend), #66 (mobile), #67 (frontend) — mergeados 2026-05-26

### Sesión A — Seguridad backend ✅

| # | Tarea | Archivo | Estado |
|---|-------|---------|--------|
| 1 | Cifrar `fcm_token` con cast `encrypted:` | `User.php` | ✅ |
| 2 | Validar foto perfil `image\|max:2048` | `PerfilController.php` | ✅ |
| 3 | Marcar campos médicos como `$hidden` | `User.php` | ✅ |
| 4 | Re-validar disponibilidad dentro de `lockForUpdate()` | `CitaService.php` | ✅ |
| 5 | Loguear errores en `listarPendientesPorPrioridad()` | `IAPriorityController.php` | ✅ |
| 6 | `updateOrCreate` en `ConsultaController::store()` | `ConsultaController.php` | ✅ |
| 7 | Validar que `reprogramar()` no acepte hora pasada | `CitaService.php` | ✅ |
| 8 | Hashear código 2FA en BD | `AuthController.php` | ✅ |

### Sesión B — Frontend UX + 2FA ✅

| # | Tarea | Estado |
|---|-------|--------|
| 1 | Límite intentos 2FA (5 + bloqueo 15min) | ✅ |
| 2 | Skeleton loader en `doctor-citas` | ✅ |
| 3 | Mover update reprogramar DESPUÉS de `tap()` | ✅ |
| 4 | `takeUntil(destroy$)` en polling | ✅ |
| 5 | Toast retry en `student-dashboard` | ✅ |
| 6 | Manejo `error.status === 0` en interceptor | ✅ |
| 7 | Modal aviso idle timeout | ✅ |
| 8-9 | Skeleton estadísticas + error amigable IA | ✅ |

### Sesión C — Mobile seguridad ✅

| # | Tarea | Estado |
|---|-------|--------|
| 1 | Migrar token a `flutter_secure_storage` | ✅ |
| 2 | Cifrar caché offline | ✅ |
| 3 | Campo `diagnostico` en modelo Cita | ✅ |
| 4-7 | Validar token, 401→login, foto 2MB, cached_network_image | ✅ |

### Sesión D — IA quick wins ✅

| # | Tarea | Estado |
|---|-------|--------|
| 1 | Validar `GROQ_API_KEY` en startup | ✅ |
| 2 | Alinear rate limit | ✅ |
| 3 | Validar historial chat ≤ 10 | ✅ |
| 4 | Eliminar `pre_evaluacion_ia.py` | ✅ |
| 5-6 | Dockerfile Python 3.12 + logging | ✅ |

---

## Fase 2 — Quick wins: auditoría + hallazgos del grafo (1 sesión, ~1.5h)

> Hallazgos nuevos del grafo marcados con 📊

| # | Tarea | Origen | Archivos | Esfuerzo |
|---|-------|--------|----------|----------|
| 1 | 📊 Reemplazar iconos web Flutter (favicon + Icon-192/512 + maskable) con logo Yoltec | Grafo | `mobile/web/favicon.png`, `mobile/web/icons/*` | 15 min |
| 2 | 📊 Extraer `formatFecha()` a pipe/util compartido (duplicado 8 veces en 7 componentes) | Grafo | `frontend/src/app/shared/` + 7 componentes | 30 min |
| 3 | 📊 Extraer `iniciales()` a util compartido (duplicado 6 veces en 6 componentes) | Grafo | `frontend/src/app/shared/` + 6 componentes | 20 min |
| 4 | Humanizar SYSTEM_PROMPT IA | Auditoría | `IA/app.py` | 30 min |
| 5 | Fix regex `/^\d{6}$/` en input 2FA | Auditoría | `verify-2fa.component.ts` | 5 min |
| 6 | Fix `IA_SERVICE_URL` en Render → `https://yoltec-ia.onrender.com` | Auditoría | Render env vars | 5 min |

**PR:** `feat: quick wins auditoria + grafo (2026-05-27)`

---

## Fase 3 — Pulido opcional (si queda tiempo, 1-2 sesiones)

### Backend
- Paginar `historial()` con `paginate(15)`
- Agregar índices: `citas.fecha_cita`, `citas.alumno_id`, `pre_evaluaciones_ia.estatus_validacion`
- Eager loading completo en `CitaController::index()` (`consulta`, `receta`)
- `Cache::forget()` en `CalendarioAdminController::update()`

### Frontend
- `trackBy` en `*ngFor` de `doctor-citas` y `mis-citas`
- Recarga automática de `mis-citas` tras cancelar
- Confirmación modal antes de cancelar cita
- Estados vacíos (icono + mensaje) en listas
- Filtros persistentes en URL query params
- 📊 Retry/fallback en `api-config.ts` para cold starts Render (betweenness 0.037)

### Mobile
- `ListView.builder` en lugar de `.separated`
- Throttle 2s en `RefreshIndicator`
- Cleanup automático de caché offline expirado

### IA
- `/health` expandido con versión, tamaño, estado LLM
- Cachear `groq_client.models.list()` 30s
- Mover `respuesta_a_binario` y `generar_recomendacion` a `utils.py`

---

## Post-semestre (no bloquea entrega)

### Refactors estructurales (detectados por grafo)

| Archivo | Líneas | Métodos | Límite | Origen |
|---------|--------|---------|--------|--------|
| `doctor-citas.component.ts` | 814 | 77 | +700 🔴 | Auditoría + Grafo |
| `nueva_cita_form.dart` | 914 | ~30 | +700 🔴 | 📊 Solo grafo |
| `perfil_tab.dart` | 927 | ~30 | +700 🔴 | Auditoría |
| `admin-dashboard.component.ts` | 558 | 41 | Tolerable | Auditoría |
| `citas_tab.dart` | 550 | ~20 | Tolerable | 📊 Solo grafo |
| `inicio_tab.dart` | 516 | ~20 | Tolerable | 📊 Solo grafo |

### Deuda técnica
- 📊 Centralizar `loadCitas()` (duplicado 4 veces en 4 comunidades)
- 📊 Centralizar `logout()` (duplicado 7 veces en 7 comunidades)
- Tests unitarios servicios Angular (cobertura 0%)
- `applicationId` Flutter: cambiar de `com.example.yoltec_mobile`
- Tipado fuerte: eliminar `any` en servicios/componentes
- AuthService centralizado en frontend (eliminar `localStorage` directo)
- 📊 Separar idle tracking de AuthService (6 métodos → `IdleService`)
- Migrar fotos perfil de base64 en BD a `storage/` (backend)
- Filtros avanzados pacientes (IMC, tipo sangre, etc.)
- Endpoint `/predict-batch` en IA para evitar N requests

---

## Resumen ejecutivo

| Fase | Estado | Duración |
|------|--------|----------|
| **1 — Críticos bloqueantes** | ✅ Completada (PRs #64-#67) | ~6h |
| **2 — Quick wins auditoría + grafo** | ⏳ Pendiente | ~1.5h |
| **3 — Pulido opcional** | Pendiente | ~3h |
| **Post-semestre** | Backlog | Semanas |

---

**Actualizado:** 2026-05-27
**Insumos:** [auditoria-tecnica-20260525.md](auditoria-tecnica-20260525.md) + knowledge graph (graphify, 1784 nodos, 2181 aristas)
