# Plan de accion — Auditoria 2026-05-25 + Analisis de grafo 2026-05-27

**Insumo:** [auditoria-tecnica-20260525.md](auditoria-tecnica-20260525.md) + knowledge graph (graphify)
**Deadline academico:** mediados de junio 2026
**Estado:** Fases 1-5 completadas (PRs #64-#78). Release v1.5.0 publicada con APK.
**Siguiente:** Cerrado — pendientes son features baja prioridad post-deadline.

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

## Fase 4 — Entrega final: APK + humanizar + bug IA ✅ COMPLETADA

> PR #70 — 2026-05-28

| # | Tarea | Estado |
|---|-------|--------|
| 1 | APK release Flutter (53 MB, apunta a Render prod) | ✅ |
| 2 | Humanizar textos login web (subtitulos, placeholders) | ✅ |
| 3 | Humanizar empty states frontend + mobile (~20 textos) | ✅ |
| 4 | Humanizar mensajes de error (IA, perfil, citas) | ✅ |
| 5 | Bug: Prioridad IA — errores diferenciados (cold start / 500 / red) + reintentar | ✅ |

**Nota:** Resend (emails solo llegan a `nespiolin05@gmail.com`) queda como feature futuro — requiere dominio verificado propio.

**PR:** `feat: fase 4 entrega final (APK + humanizar + bug IA)`

---

## Fase 5 — Refactors estructurales + deuda tecnica ✅ COMPLETADA

> PRs #71-#78 — mergeados 2026-05-28

### 5A — Partir archivos criticos (+700 lineas) ✅

| # | Archivo | Antes | Despues | PR |
|---|---------|-------|---------|----|
| 1 | `nueva_cita_form.dart` | 914 | 320 (4 modulos) | #71 |
| 2 | `perfil_tab.dart` | 927 | 328 (4 modulos) | #72 |
| 3 | `doctor-citas.component.ts` | 816 | 379 (4 sub-componentes Angular) | #73 |

### 5B — Partir archivos tolerables (400-700 lineas) ✅

| # | Archivo | Antes | Despues | PR |
|---|---------|-------|---------|----|
| 4 | `admin-dashboard.component.ts` | 558 | 174 (3 sub-componentes: panel/usuarios/calendario) | #74 |
| 5 | `citas_tab.dart` | 552 | 169 (3 modulos: tab/lista/card) | #75 |
| 6 | `inicio_tab.dart` | 516 | 202 (3 modulos: tab/card/widgets) | #76 |

### 5C — Centralizar logica duplicada ✅

| # | Tarea | Estado | PR |
|---|-------|--------|----|
| 7 | Centralizar `loadCitas()` | Skip — no era duplicacion real (cada componente llama al service propio) | — |
| 8 | Centralizar `logout()` | Hecho — `logout(redirectTo?)` elimino race condition con admin | #77 |
| 9 | Separar idle tracking de AuthService | Hecho — nuevo `idle.service.ts` (90 lineas) | #77 |

### 5D — Deuda tecnica general (alta+media completadas)

| # | Tarea | Estado | PR |
|---|-------|--------|----|
| 10 | `applicationId` Flutter | Ya estaba como `com.yoltec.app` (plan desactualizado) | — |
| 11 | Tipado fuerte: eliminar `any` en Angular | Skip — alcance enorme, bajo impacto | — |
| 12 | AuthService centralizado (eliminar `localStorage` directo) | Hecho — `setAuthData()` + AuthInterceptor global | #78 |
| 13-17 | Fotos base64, filtros, /predict-batch, tests, dominio Resend | Features / requieren infra externa — post-deadline | — |

---

## Resumen ejecutivo

| Fase | Estado | PRs |
|------|--------|-----|
| **1 — Criticos bloqueantes** | ✅ Completada | #64, #65, #66, #67 |
| **2 — Quick wins auditoria + grafo** | ✅ Completada | #68 |
| **3 — Pulido y rendimiento** | ✅ Completada | #69 |
| **4 — Entrega final (APK + humanizar + bug)** | ✅ Completada | #70 |
| **5 — Refactors + deuda tecnica** | ✅ Completada | #71, #72, #73, #74, #75, #76, #77, #78 |

---

**Actualizado:** 2026-05-28 (cierre fase 5)
**Insumos:** [auditoria-tecnica-20260525.md](auditoria-tecnica-20260525.md) + knowledge graph (graphify, 1784 nodos, 2181 aristas)
