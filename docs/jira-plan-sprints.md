# Plan Jira — Yoltec 2.0 IA (5 Sprints)
**Estado: PENDIENTE DE SUBIR — esperando asignación de roles del equipo**
**Decisión pendiente: Opción A (borrar todo y subir limpio) — confirmar antes de ejecutar**

---

## ÉPICAS

| ID | Épica |
|----|-------|
| E1 | Autenticación y seguridad |
| E2 | Gestión de citas |
| E3 | IA médica |
| E4 | Panel administrativo y estadísticas |
| E5 | Comunicaciones y notificaciones |
| E6 | App móvil |
| E7 | Expediente y historial médico |
| E8 | Documentación y cierre |

---

## SPRINT 1 — Fundamentos del sistema ✅

| HU | Épica | Historia | Criterios de aceptación |
|----|-------|----------|------------------------|
| HU-01 | E1 | Como alumno quiero iniciar sesión con número de control y NIP | 1. Login exitoso con credenciales válidas. 2. Error claro con credenciales inválidas. 3. Redirige al dashboard según rol |
| HU-02 | E1 | Como doctor quiero iniciar sesión con usuario y contraseña | 1. Login exitoso. 2. En producción solicita código 2FA por email. 3. En local omite 2FA |
| HU-03 | E1 | Como doctor quiero confirmar mi identidad con 2FA | 1. Código enviado al email al iniciar sesión en producción. 2. Código expira en 10 min. 3. Opción de dispositivo confiable por 30 días |
| HU-04 | E1 | Como doctor quiero recuperar mi contraseña por email | 1. Formulario /forgot-password envía email con token. 2. Token expira en 60 min. 3. /reset-password actualiza contraseña correctamente |
| HU-05 | E1 | Como sistema quiero proteger el login contra fuerza bruta | 1. Máximo 5 intentos fallidos. 2. Bloqueo temporal tras exceder intentos. 3. Mensaje de error apropiado |
| HU-06 | E1 | Como sistema quiero que los tokens de sesión expiren | 1. Tokens Sanctum expiran en 24h. 2. Al expirar redirige al login. 3. No afecta sesiones activas en uso |

---

## SPRINT 2 — Gestión de citas ✅

| HU | Épica | Historia | Criterios de aceptación |
|----|-------|----------|------------------------|
| HU-07 | E2 | Como alumno quiero agendar una cita en máximo 3 pasos | 1. Selección de fecha → hora → motivo. 2. Solo lunes–sábado 8am–5pm disponibles. 3. Slots ocupados no son seleccionables. 4. Confirmación por pantalla al agendar |
| HU-08 | E2 | Como alumno quiero ver disponibilidad del calendario con colores | 1. Verde = mucha disponibilidad. 2. Amarillo = poca. 3. Rojo = sin disponibilidad o festivo. 4. Días pasados y domingos inhabilitados |
| HU-09 | E2 | Como alumno quiero cancelar una cita programada | 1. Solo se pueden cancelar citas futuras. 2. El slot queda libre para otros alumnos. 3. Confirmación antes de cancelar |
| HU-10 | E2 | Como doctor quiero agendar y cancelar citas a nombre de alumnos | 1. Doctor puede seleccionar alumno al agendar. 2. Doctor puede cancelar cualquier cita. 3. Queda registrado quién realizó la acción |
| HU-11 | E2 | Como doctor quiero ver mi agenda del día | 1. Lista de citas del día actual al entrar al dashboard. 2. Muestra nombre alumno, hora y motivo. 3. Se actualiza al cancelar/agendar |
| HU-12 | E2 | Como doctor quiero marcar a un alumno como "no asistió" | 1. Botón disponible en citas del día pasado. 2. Cambia estatus a no_asistio. 3. Queda registrado en bitácora |

---

## SPRINT 3 — IA médica ✅

| HU | Épica | Historia | Criterios de aceptación |
|----|-------|----------|------------------------|
| HU-13 | E3 | Como alumno quiero hacer una pre-evaluación de síntomas tras agendar | 1. Chat disponible después de agendar cita. 2. Responde en lenguaje natural vía Groq. 3. Genera diagnóstico preliminar con % de confianza usando sklearn |
| HU-14 | E3 | Como doctor quiero ver la pre-evaluación del alumno antes de la consulta | 1. Pre-evaluación visible en detalle de cita. 2. Muestra síntomas reportados, diagnóstico y %. 3. Doctor puede validar o descartar el diagnóstico |
| HU-15 | E3 | Como doctor quiero clasificar alumnos por prioridad según su historial | 1. Clasificación visible solo para doctor. 2. Alta prioridad: asiste siempre y puntual. 3. Baja prioridad: cancela frecuentemente o no asiste. 4. No cancela citas automáticamente |

---

## SPRINT 4 — Recetas, bitácora y admin ✅

| HU | Épica | Historia | Criterios de aceptación |
|----|-------|----------|------------------------|
| HU-16 | E4 | Como doctor quiero crear recetas médicas para el alumno | 1. Formulario con medicamento, dosis e indicaciones. 2. Receta queda ligada a la cita. 3. Alumno puede verla desde su cuenta |
| HU-17 | E4 | Como alumno quiero ver mis recetas en pantalla | 1. Lista de recetas accesible desde el menú. 2. Detalle con medicamento, dosis e indicaciones. 3. Sin opción de descarga PDF |
| HU-18 | E4 | Como doctor quiero ver la bitácora de citas con filtros | 1. Filtros por fecha y nombre/número de control. 2. Paginación de 10 por página. 3. Exportar a CSV. 4. Muestra estatus: atendida, cancelada, no asistió |
| HU-19 | E5 | Como alumno quiero recibir recordatorio de mi cita 24h antes | 1. Email enviado automáticamente 24h antes. 2. Incluye fecha, hora y doctor. 3. Solo si la cita sigue programada |
| HU-20 | E4 | Como admin quiero gestionar alumnos y doctores desde un panel | 1. CRUD completo de alumnos y doctores. 2. Accesible solo con rol admin en /admin-dashboard. 3. Búsqueda por nombre o número de control |
| HU-21 | E4 | Como admin quiero gestionar días especiales en el calendario | 1. Admin puede marcar días como festivos o inhabilitados. 2. Días marcados aparecen en rojo en el calendario. 3. Alumnos no pueden agendar en esos días |

---

## SPRINT 5 — Expediente, móvil y cierre ⏳

| HU | Épica | Historia | Criterios de aceptación |
|----|-------|----------|------------------------|
| HU-22 | E7 | Como doctor quiero registrar el diagnóstico y tratamiento de cada consulta | 1. Formulario al marcar cita como atendida. 2. Campos: diagnóstico, tratamiento, observaciones. 3. Queda ligado a la cita y visible para doctor y alumno |
| HU-23 | E7 | Como alumno quiero ver mi historial médico completo | 1. Lista de consultas pasadas con fecha y doctor. 2. Detalle con diagnóstico, tratamiento y receta. 3. Solo el propio alumno puede ver su historial |
| HU-24 | E7 | Como alumno quiero tener un perfil médico con mis datos de salud | 1. Campos: tipo de sangre, alergias, enfermedades crónicas. 2. Alumno puede actualizar sus datos. 3. Doctor puede verlo antes de la consulta |
| HU-25 | E6 | Como alumno quiero recibir notificaciones push en la app móvil | 1. Notificación al confirmar/cancelar una cita. 2. Recordatorio 24h antes. 3. Funciona en Android (Firebase Cloud Messaging) |
| HU-26 | E8 | Como equipo queremos tener el manual técnico del sistema | 1. Describe arquitectura, stack y endpoints principales. 2. Instrucciones de instalación y despliegue. 3. Almacenado en /docs |
| HU-27 | E8 | Como equipo queremos tener el manual de usuario | 1. Cubre flujos principales: agendar cita, pre-evaluación, recetas. 2. Con capturas de pantalla. 3. Versión para alumno y para doctor |

---

## HUs descartadas

- Auto-registro de alumnos (ya existen en sistema escolar)
- PDFs / justificantes con firma digital
- Resultados de laboratorio
- Inventario de medicamentos
- Encuestas de satisfacción
- Integración con sistema escolar
- Directorio de médicos por especialidad

---

## Notas para cuando se suba

- Usar Opción A: borrar todos los tickets actuales de Y20I y subir limpio
- Asignar tickets según roles del equipo (pendiente de confirmar)
- Borrar proyectos SCRUM (YolTec) y YV0 (yoltec v2.0) — confirmar antes
- Los sprints 1-4 marcarlos como completados al crear
