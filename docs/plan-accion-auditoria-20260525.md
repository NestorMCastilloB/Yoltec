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

## Fase 2 — Quick wins: auditoría + hallazgos del grafo ✅ COMPLETADA

> PR #68 — mergeado 2026-05-27

| # | Tarea | Estado |
|---|-------|--------|
| 1 | 📊 Iconos web Flutter → logo Yoltec | ✅ |
| 2 | 📊 Extraer `formatFecha()` a shared util (6 componentes) | ✅ |
| 3 | 📊 Extraer `iniciales()` a shared util (2 componentes) | ✅ |
| 4 | Humanizar SYSTEM_PROMPT IA | ✅ |
| 5 | Fix regex 2FA | ✅ Ya estaba (PR #67) |
| 6 | Fix `IA_SERVICE_URL` Railway → Render | ✅ |

---

## Fase 3 — Pulido y rendimiento ✅ COMPLETADA

> PR #69 — mergeado 2026-05-27

| # | Tarea | Estado |
|---|-------|--------|
| 1 | Índice `pre_evaluaciones_ia.estatus_validacion` | ✅ |
| 2 | Paginar `historial()` con `paginate(15)` | ✅ |
| 3 | Eager loading en `CitaController::index()` | ✅ |
| 4 | `trackBy` en `doctor-citas` y `mis-citas` | ✅ |
| 5 | Retry cold start Render en interceptor | ✅ |
| 6 | `ListView.builder` en citas_tab y recetas_tab | ✅ |
| 7 | `/health` expandido + caché Groq 30s | ✅ |

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
