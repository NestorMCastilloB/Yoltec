# Plan de Pruebas Formales — Yoltec
**Versión:** 1.0
**Fecha:** 2026-04-19
**Sistema:** Consultorio Médico Universitario con IA
**Ejecutadas:** 2026-04-20

---

## 1. Alcance

Cubre los módulos principales del sistema:
- Autenticación (3 roles)
- Gestión de citas
- IA pre-evaluación de síntomas
- Recetas médicas
- Historial médico
- Panel administrativo
- App móvil Flutter

---

## 2. Entorno de prueba

| Elemento | Valor |
|----------|-------|
| Backend | http://localhost:8000 (local) / https://yoltec-backend.onrender.com (prod) |
| Frontend | http://localhost:4200 (local) / https://yoltec.vercel.app (prod) |
| IA | http://localhost:5000 (local) / https://yoltec-ia.onrender.com (prod) |
| DB | Neon PostgreSQL (compartida) |

### Credenciales de prueba

| Rol | Usuario | Contraseña |
|-----|---------|-----------|
| Alumno | `22690495` | NIP: `740270` |
| Doctor | `doctorOmar` | `doctor123` |
| Admin | `admin` | `admin123` |

---

## 3. Casos de prueba

### 3.1 Módulo de Autenticación

| ID | Descripción | Pasos | Resultado esperado | Pass/Fail |
|----|-------------|-------|--------------------|-----------|
| CP-AUTH-01 | Login alumno con credenciales válidas | 1. Ir a /login. 2. Ingresar número de control `22690495` y NIP `740270`. 3. Clic en Entrar | Redirige al dashboard del alumno | ✅ Pass |
| CP-AUTH-02 | Login alumno con NIP incorrecto | 1. Ingresar `22690495` y NIP `000000`. 2. Clic en Entrar | Mensaje de error "Credenciales inválidas" | ✅ Pass |
| CP-AUTH-03 | Login doctor con credenciales válidas (local) | 1. Ingresar `doctorOmar` / `doctor123`. 2. Clic en Entrar | Redirige al dashboard del doctor (sin 2FA en local) | ✅ Pass |
| CP-AUTH-04 | Login admin con credenciales válidas | 1. Ingresar `admin` / `admin123`. 2. Clic en Entrar | Redirige a /admin-dashboard | ✅ Pass |
| CP-AUTH-05 | Protección de rutas — acceso no autenticado | 1. Sin sesión activa, navegar a /doctor-dashboard | Redirige automáticamente a /login | ✅ Pass |
| CP-AUTH-06 | Cierre de sesión | 1. Iniciar sesión como alumno. 2. Clic en "Cerrar sesión" | Redirige a /login, token eliminado | ✅ Pass |
| CP-AUTH-07 | Recuperación de contraseña — envío de email | 1. Ir a /forgot-password. 2. Ingresar email de doctor registrado. 3. Clic en Enviar | Mensaje de confirmación de envío | ✅ Pass |
| CP-AUTH-08 | Sesiones activas — ver y revocar | 1. Login como alumno. 2. Ir a Mi Perfil → Sesiones activas. 3. Clic en "Revocar" en una sesión | Sesión eliminada de la lista | ✅ Pass |

---

### 3.2 Módulo de Citas

| ID | Descripción | Pasos | Resultado esperado | Pass/Fail |
|----|-------------|-------|--------------------|-----------|
| CP-CITAS-01 | Agendar cita como alumno | 1. Login alumno. 2. Ir a Citas → Agendar. 3. Seleccionar fecha futura (lunes–sábado). 4. Seleccionar slot disponible. 5. Ingresar motivo. 6. Confirmar | Cita creada, aparece en lista con estatus "programada" | ✅ Pass |
| CP-CITAS-02 | Calendario con colores de disponibilidad | 1. Login alumno. 2. Ver calendario | Verde = mucha disponibilidad, Amarillo = poca, Rojo = sin slots. Domingos deshabilitados | ✅ Pass |
| CP-CITAS-03 | Slot ocupado no es seleccionable | 1. Agendar cita en slot X. 2. Con otro usuario intentar agendar en mismo slot X | Slot aparece como no disponible | ✅ Pass |
| CP-CITAS-04 | Cancelar cita como alumno | 1. Login alumno. 2. Ir a cita programada. 3. Clic en "Cancelar". 4. Confirmar | Estatus cambia a "cancelada", slot queda libre | ✅ Pass |
| CP-CITAS-05 | Doctor ve agenda del día | 1. Login doctor. 2. Ir al dashboard | Lista de citas del día actual con nombre alumno, hora y motivo | ✅ Pass |
| CP-CITAS-06 | Doctor agenda cita a nombre de alumno | 1. Login doctor. 2. Ir a Citas → Nueva cita. 3. Buscar y seleccionar alumno. 4. Elegir fecha, hora y motivo. 5. Confirmar | Cita creada con nombre del alumno seleccionado | ✅ Pass |
| CP-CITAS-07 | Marcar alumno como "no asistió" | 1. Login doctor. 2. Buscar cita pasada con estatus "programada". 3. Clic en "No asistió" | Estatus cambia a "no_asistio", queda en bitácora | ✅ Pass |
| CP-CITAS-08 | Reprogramar cita | 1. Login doctor. 2. Abrir cita programada. 3. Clic en "Reprogramar". 4. Seleccionar nueva fecha y hora. 5. Confirmar | Cita actualizada con nueva fecha/hora | ✅ Pass |
| CP-CITAS-09 | Días especiales bloqueados en calendario | 1. Login admin. 2. Marcar un día como festivo. 3. Login alumno. 4. Intentar agendar en ese día | Día aparece en rojo en el calendario para todos los usuarios | ✅ Pass |
| CP-CITAS-10 | Filtros en citas del doctor | 1. Login doctor. 2. Ir a sección Citas. 3. Filtrar por estatus "cancelada" | Solo aparecen citas canceladas | ✅ Pass |

---

### 3.3 Módulo de IA — Pre-evaluación de síntomas

| ID | Descripción | Pasos | Resultado esperado | Pass/Fail |
|----|-------------|-------|--------------------|-----------|
| CP-IA-01 | Chat de pre-evaluación con Groq | 1. Login alumno. 2. Ir a Pre-evaluación. 3. Describir síntomas en texto libre | El chat responde en lenguaje natural con preguntas de seguimiento | ✅ Pass |
| CP-IA-02 | Diagnóstico con porcentaje de confianza | 1. Completar flujo de pre-evaluación. 2. Ver resultado | Muestra diagnóstico preliminar con % de confianza (sklearn) | ✅ Pass |
| CP-IA-03 | Doctor ve pre-evaluación del alumno | 1. Login doctor. 2. Ir a sección Pre-evaluaciones. 3. Buscar alumno con pre-eval registrada | Muestra síntomas, diagnóstico y % de confianza | ✅ Pass |
| CP-IA-04 | Doctor valida diagnóstico | 1. Login doctor. 2. Abrir pre-evaluación de alumno. 3. Clic en "Validar diagnóstico" | Diagnóstico marcado como validado por el doctor | ✅ Pass |
| CP-IA-05 | Doctor descarta diagnóstico | 1. Login doctor. 2. Abrir pre-evaluación. 3. Clic en "Descartar" | Diagnóstico marcado como descartado | ✅ Pass |
| CP-IA-06 | Clasificación de prioridad visible solo para doctor | 1. Login alumno. 2. Verificar menú | Sección de "Clasificación IA" no visible para alumno | ✅ Pass |
| CP-IA-07 | Doctor ve clasificación de prioridad | 1. Login doctor. 2. Ir a IA Prioridad | Lista de alumnos con etiqueta Alta/Baja prioridad según historial | ✅ Pass |

---

### 3.4 Módulo de Recetas Médicas

| ID | Descripción | Pasos | Resultado esperado | Pass/Fail |
|----|-------------|-------|--------------------|-----------|
| CP-RECETA-01 | Doctor crea receta | 1. Login doctor. 2. Ir a Recetas → Nueva receta. 3. Buscar alumno. 4. Ingresar medicamento, dosis e indicaciones. 5. Guardar | Receta creada y visible en lista del doctor | ✅ Pass |
| CP-RECETA-02 | Alumno ve sus recetas | 1. Login alumno. 2. Ir a Recetas | Lista de recetas con medicamento, dosis e indicaciones | ✅ Pass |
| CP-RECETA-03 | Receta ligada a cita | 1. Login doctor. 2. Crear receta desde una cita atendida | Receta aparece en el historial de esa cita | ✅ Pass |
| CP-RECETA-04 | Alumno no puede ver recetas de otros alumnos | 1. Login alumno `22690495`. 2. Intentar acceder a receta de otro alumno vía URL | Respuesta 403 o redirige | ✅ Pass |

---

### 3.5 Módulo de Historial Médico

| ID | Descripción | Pasos | Resultado esperado | Pass/Fail |
|----|-------------|-------|--------------------|-----------|
| CP-HIST-01 | Doctor registra diagnóstico al atender | 1. Login doctor. 2. Abrir cita del día. 3. Clic en "Atender". 4. Llenar diagnóstico, tratamiento y observaciones. 5. Guardar | Cita marcada como "atendida", datos guardados en tabla consultas | ✅ Pass |
| CP-HIST-02 | Alumno ve su historial médico | 1. Login alumno. 2. Ir a Historial | Lista de consultas pasadas con fecha, doctor, diagnóstico y tratamiento | ✅ Pass |
| CP-HIST-03 | Doctor ve perfil médico del alumno | 1. Login doctor. 2. Ir a Citas. 3. Abrir modal de alumno | Muestra tipo de sangre, alergias, enfermedades crónicas e historial | ✅ Pass |
| CP-HIST-04 | Alumno actualiza perfil médico | 1. Login alumno. 2. Ir a Mi Perfil → Datos médicos. 3. Actualizar tipo de sangre y alergias. 4. Guardar | Datos actualizados correctamente | ✅ Pass |
| CP-HIST-05 | Bitácora — filtros por fecha y alumno | 1. Login doctor. 2. Ir a Bitácora. 3. Filtrar por rango de fechas y nombre de alumno | Lista filtrada correctamente con paginación 10/página | ✅ Pass |
| CP-HIST-06 | Bitácora — exportar CSV | 1. Login doctor. 2. Ir a Bitácora. 3. Clic en "Exportar CSV" | Descarga archivo .csv con los registros visibles | ✅ Pass |

---

### 3.6 Panel Administrativo

| ID | Descripción | Pasos | Resultado esperado | Pass/Fail |
|----|-------------|-------|--------------------|-----------|
| CP-ADMIN-01 | Admin gestiona alumnos — crear | 1. Login admin. 2. Ir a Alumnos → Nuevo. 3. Ingresar datos. 4. Guardar | Alumno creado y visible en lista | ✅ Pass |
| CP-ADMIN-02 | Admin gestiona alumnos — editar | 1. Login admin. 2. Ir a Alumnos. 3. Seleccionar alumno. 4. Editar nombre. 5. Guardar | Datos actualizados correctamente | ✅ Pass |
| CP-ADMIN-03 | Admin gestiona alumnos — eliminar | 1. Login admin. 2. Seleccionar alumno sin citas activas. 3. Clic en eliminar. 4. Confirmar | Alumno eliminado de la lista | ✅ Pass |
| CP-ADMIN-04 | Búsqueda de alumnos en tiempo real | 1. Login admin. 2. Ir a Alumnos. 3. Escribir nombre parcial en buscador | Lista se filtra en tiempo real mostrando coincidencias | ✅ Pass |
| CP-ADMIN-05 | Admin gestiona días especiales | 1. Login admin. 2. Ir a Días especiales. 3. Seleccionar fecha. 4. Marcar como festivo. 5. Guardar | Día aparece en rojo en el calendario para todos los usuarios | ✅ Pass |

---

### 3.7 App Móvil Flutter

| ID | Descripción | Pasos | Resultado esperado | Pass/Fail |
|----|-------------|-------|--------------------|-----------|
| CP-MOVIL-01 | Splash screen con animación | 1. Abrir app sin sesión activa | Pantalla de splash con animación fade+scale, luego navega a login | ✅ Pass |
| CP-MOVIL-02 | Login alumno en app | 1. Ingresar `22690495` y NIP `740270`. 2. Clic en Entrar | Navega al home del alumno | ✅ Pass |
| CP-MOVIL-03 | Agendar cita desde app | 1. Login alumno. 2. Ir a Citas → Agendar. 3. Seleccionar fecha y slot. 4. Ingresar motivo | Cita creada, aparece en lista | ✅ Pass |
| CP-MOVIL-04 | IA chat desde app | 1. Login alumno. 2. Ir a Pre-evaluación. 3. Escribir síntomas | Chat responde y muestra diagnóstico con % | ✅ Pass |
| CP-MOVIL-05 | Ver recetas desde app | 1. Login alumno. 2. Ir a Recetas | Lista de recetas con detalle al tocar | ✅ Pass |
| CP-MOVIL-06 | Banner offline cuando sin conexión | 1. Desactivar WiFi/datos. 2. Abrir app o navegar | Banner naranja "Sin conexión" visible, datos cacheados disponibles | ✅ Pass |
| CP-MOVIL-07 | Dark mode en app | 1. Login. 2. Ir a Mi Perfil → Tema. 3. Activar modo oscuro | La app cambia a tema oscuro completamente | ✅ Pass |
| CP-MOVIL-08 | Tab Mi Perfil — ver y editar datos | 1. Login alumno. 2. Ir a tab Perfil. 3. Verificar foto/iniciales, datos personales e info médica | Datos visibles, opción de editar disponible | ✅ Pass |
| CP-MOVIL-09 | Notificación push al agendar cita | 1. Login alumno. 2. Agendar cita nueva | Notificación push recibida con confirmación de la cita | ✅ Pass |

---

## 4. Resumen de resultados

| Módulo | Total | Pass | Fail | Pendiente |
|--------|-------|------|------|-----------|
| Autenticación | 8 | 8 | 0 | 0 |
| Citas | 10 | 10 | 0 | 0 |
| IA | 7 | 7 | 0 | 0 |
| Recetas | 4 | 4 | 0 | 0 |
| Historial | 6 | 6 | 0 | 0 |
| Admin | 5 | 5 | 0 | 0 |
| App Móvil | 9 | 9 | 0 | 0 |
| **TOTAL** | **49** | **49** | **0** | **0** |

---

## 5. Defectos encontrados

| ID | Módulo | Descripción | Severidad | Estatus |
|----|--------|-------------|-----------|---------|
| DEF-01 | Seguridad | NIP del alumno estaba expuesto en respuestas JSON de `/api/perfil` | Alta | ✅ Corregido — agregado a `$hidden` en User.php |
| DEF-02 | Rendimiento | `autoCancelPastAppointments()` ejecutaba UPDATE en BD en cada GET /citas | Media | ✅ Corregido — cache throttle de 5 minutos |
| DEF-03 | Seguridad | Rate limiting de login no funcionaba en producción (Render) | Alta | ✅ Corregido — `CACHE_STORE=database` en docker-entrypoint.sh |

---

## 6. Pruebas de seguridad adicionales

| ID | Tipo | Descripción | Resultado |
|----|------|-------------|-----------|
| SEC-01 | SQL Injection | Login con payload `' OR 1=1 --` | ✅ Bloqueado (422) — Laravel PDO usa prepared statements |
| SEC-02 | Mass Assignment | PUT /perfil enviando `tipo:"doctor"` y `es_admin:true` | ✅ Protegido — campos no fillable ignorados |
| SEC-03 | XSS | Motivo de cita con `<script>alert(1)</script>` | ✅ API acepta como texto, Angular/Flutter escapan en render |
| SEC-04 | Privilege Escalation | Alumno invoca endpoint exclusivo de doctor | ✅ Bloqueado (403) |
| SEC-05 | IDOR Citas | Alumno accede a cita de otro alumno vía `/api/citas/{id}` | ✅ Bloqueado (403) |
| SEC-06 | IDOR Recetas | Alumno accede a receta de otro alumno vía `/api/recetas/{id}` | ✅ Bloqueado (403) |
| SEC-07 | Rate Limiting | 6 intentos de login fallidos en < 1 minuto | ✅ Bloqueado (429 Too Many Requests) |

---

*Pruebas ejecutadas el 2026-04-20 contra backend local (localhost:8000) con base de datos Neon PostgreSQL compartida.*
