# Manual de Usuario – Yoltec

**Versión:** 2.0
**Fecha:** Abril 2026

Sistema de gestión de consultorio médico universitario con inteligencia artificial integrada.

---

## 1. Acceso al sistema

### 1.1. Web (navegador)

**Producción:** https://frontend-nu-weld-77.vercel.app
**Local:** http://localhost:4200

### 1.2. App móvil (Android)

Descarga el APK desde el repositorio (`mobile/build/app/outputs/flutter-apk/app-release.apk`) e instálalo en tu dispositivo Android.

---

## 2. Roles del sistema

| Rol | Acceso |
|-----|--------|
| **Alumno** | Agendar citas, ver historial, chat IA, perfil médico |
| **Doctor** | Gestionar citas, recetas, bitácora, clasificación IA |
| **Admin** | CRUD de usuarios, días especiales del calendario |

---

## 3. Inicio de sesión

La pantalla de login tiene tres pestañas: **Estudiante**, **Doctor** y **Admin**.

### 3.1. Alumno

- **Número de control:** tu número de control universitario (ej. `22690495`)
- **NIP:** tu número de identificación personal

### 3.2. Doctor

- **Usuario:** tu nombre de usuario (ej. `doctorOmar`)
- **Contraseña:** tu contraseña

> En producción los doctores reciben un **código de verificación por email** (2FA) después de ingresar su contraseña. Escribe el código en la pantalla siguiente. Puedes marcar el dispositivo como "de confianza" para no pedir el código durante 30 días.

### 3.3. Admin

- **Usuario:** `admin`
- **Contraseña:** tu contraseña

### 3.4. Recuperación de contraseña (doctores y admin)

1. Haz clic en **"¿Olvidaste tu contraseña?"** en la pantalla de login.
2. Ingresa tu correo electrónico registrado.
3. Recibirás un enlace por email.
4. Haz clic en el enlace y escribe tu nueva contraseña.

---

## 4. Panel del Alumno

Al iniciar sesión como alumno entrarás al **Panel del Estudiante**. El menú superior tiene las secciones:

**Inicio · Citas · Pre-evaluación IA · Recetas · Mi Perfil · Cerrar sesión**

### 4.1. Inicio

Muestra un resumen de tu situación médica:
- Próxima cita (fecha, hora, motivo)
- Total de citas programadas
- Total de citas atendidas

### 4.2. Citas

#### Agendar una cita

1. Haz clic en **"Agendar Nueva Cita"**.
2. Selecciona una **fecha** en el calendario:
   - Verde: mucha disponibilidad
   - Amarillo: poca disponibilidad
   - Rojo/gris: sin lugares o día inhabilitado
   - Los domingos siempre están cerrados
3. Selecciona una **hora** disponible (8:00 – 17:00, cada 15 minutos).
4. Escribe el **motivo** de tu consulta (obligatorio).
5. Haz clic en **"Confirmar cita"**.

#### Cancelar una cita

En la lista de citas programadas, haz clic en **"Cancelar"** junto a la cita que deseas cancelar. El slot quedará libre para otros alumnos.

#### Ver historial de citas

Desplázate hacia abajo para ver tus citas pasadas (atendidas, canceladas, no asistidas) con fecha, hora y estatus.

### 4.3. Pre-evaluación IA

Esta sección te permite hacer una **evaluación de síntomas** antes de tu cita, asistida por inteligencia artificial.

1. Haz clic en **"Nueva Pre-evaluación"**.
2. Describe tus síntomas en el **chat** (en lenguaje natural, en español).
3. El asistente te hará preguntas para entender mejor tu situación.
4. Tras 3–5 intercambios recibirás un **diagnóstico orientativo** con:
   - Enfermedad más probable
   - Porcentaje de confianza
   - 3 posibles diagnósticos
   - Recomendación (urgente / consulta en 24h / esperar)
5. El resultado queda guardado y el doctor lo puede revisar antes de tu cita.

> El diagnóstico de la IA es **orientativo**, no reemplaza la evaluación médica del doctor.

### 4.4. Historial médico

Aquí puedes ver todas tus **consultas atendidas** con:
- Fecha de la consulta
- Diagnóstico del doctor
- Tratamiento indicado
- Observaciones
- Receta (si se emitió)

### 4.5. Recetas

Lista de tus recetas médicas. Para cada una verás:
- Fecha de emisión
- Medicamentos recetados
- Indicaciones del doctor

Las recetas son de solo lectura.

### 4.6. Mi Perfil

#### Datos personales

- Puedes ver tu nombre, correo, teléfono y número de control.
- Haz clic en **"Editar"** para actualizar tus datos y guarda con **"Guardar cambios"**.

#### Perfil médico

Puedes registrar o actualizar:
- Tipo de sangre
- Alergias conocidas
- Enfermedades crónicas

Esta información la puede ver el doctor antes de atenderte.

#### Foto de perfil

Haz clic en tu foto (o en el ícono de cámara) para subir una imagen desde tu computadora.

#### Cambiar contraseña

1. Ingresa tu contraseña actual.
2. Escribe la nueva contraseña (mínimo 8 caracteres).
3. Confírmala.
4. Haz clic en **"Cambiar contraseña"**.

---

## 5. Panel del Doctor

Al iniciar sesión como doctor entrarás al **Panel del Doctor**. El menú lateral tiene las secciones:

**Inicio · Citas · Bitácoras · Estadísticas · Recetas · Pre-evaluaciones · IA Prioridad · Mi Perfil · Cerrar sesión**

### 5.1. Inicio

Vista rápida del día:
- Citas programadas para hoy
- Próxima cita (con nombre del alumno y hora)
- Total de citas atendidas hoy
- Total de citas del mes

### 5.2. Citas

#### Filtros

En la parte superior puedes filtrar por:
- **Estatus:** programada / atendida / cancelada / no asistió
- **Fecha desde / hasta**
- Botón **"Limpiar filtros"** para resetear

#### Agendar cita para un alumno

1. Haz clic en **"Agendar cita"**.
2. Ingresa el **número de control** del alumno.
3. Selecciona fecha, hora y motivo.
4. Confirma.

#### Acciones sobre citas

Cada cita tiene un menú de acciones:

| Acción | Estatus resultante |
|--------|-------------------|
| **Atender** | `atendida` — abre el formulario de consulta |
| **No asistió** | `no_asistio` |
| **Cancelar** | `cancelada` |
| **Reprogramar** | Cambia fecha y hora (estatus sigue `programada`) |
| **Ver perfil médico** | Modal con foto, datos médicos e historial del alumno |

#### Registrar consulta (al atender)

Cuando marcas una cita como "Atender" se abre el formulario de consulta:
- **Diagnóstico** (obligatorio)
- **Tratamiento** (obligatorio)
- **Observaciones** (opcional)

El alumno podrá ver este registro en su historial médico.

#### Reprogramar cita

1. En el menú de la cita, selecciona **"Reprogramar"**.
2. Se abre un modal con el calendario.
3. Selecciona nueva fecha y hora disponible.
4. Confirma la reprogramación.

El alumno recibirá una notificación push si tiene la app instalada.

### 5.3. Bitácoras

Historial completo de todas las consultas atendidas.

**Filtros disponibles:**
- Por nombre o número de control del alumno
- Por rango de fechas

**Exportar:**
- Botón **"Exportar CSV"** para descargar el historial en formato Excel-compatible.

Para cada registro verás: diagnóstico, tratamiento, observaciones, signos vitales (peso, altura, temperatura, presión arterial).

### 5.4. Estadísticas

Gráficas del consultorio:
- **Barras por mes:** citas atendidas vs. canceladas
- **Donut:** distribución por estatus (programada, atendida, cancelada, no asistió)
- Totales del período seleccionado

### 5.5. Recetas

#### Crear receta

1. Haz clic en **"Nueva Receta"**.
2. Selecciona la **cita atendida** (solo aparecen citas atendidas sin receta previa).
3. Llena:
   - **Medicamentos:** nombre, dosis, frecuencia
   - **Indicaciones:** instrucciones para el alumno
   - **Fecha de emisión**
4. Guarda.

> Solo se puede crear **una receta por cita**. Para modificarla usa el botón "Editar".

#### Editar receta

Haz clic en **"Editar"** junto a la receta que deseas modificar. Puedes cambiar medicamentos, indicaciones y fecha de emisión.

### 5.6. Pre-evaluaciones IA

Lista de pre-evaluaciones enviadas por alumnos antes de sus citas.

Para cada evaluación puedes:
- **Validar diagnóstico:** confirmar que el diagnóstico IA es correcto
- **Descartar diagnóstico:** marcarlo como incorrecto

Esto ayuda a mejorar el modelo de IA con el tiempo.

### 5.7. IA Clasificación de Prioridad

Esta sección muestra la **prioridad asignada** a cada alumno según su historial de citas:

- **Alta prioridad:** alumno que asiste puntualmente y no cancela
- **Baja prioridad:** alumno con historial frecuente de cancelaciones o inasistencias

> La clasificación es **informativa solamente**. El sistema nunca cancela citas automáticamente.

### 5.8. Mi Perfil

Igual que el alumno: puedes ver y editar tus datos personales, cambiar tu foto de perfil y cambiar tu contraseña.

---

## 6. Panel de Administrador

Acceso: `/admin-dashboard`

### 6.1. Gestión de alumnos

- **Listar** todos los alumnos registrados
- **Crear** nuevo alumno (nombre, número de control, NIP, email, teléfono)
- **Editar** datos de un alumno
- **Eliminar** alumno

### 6.2. Gestión de doctores

- **Listar** todos los doctores
- **Crear** nuevo doctor (nombre, usuario, contraseña, email, especialidad)
- **Editar** datos de un doctor
- **Eliminar** doctor

### 6.3. Días especiales del calendario

Permite bloquear o marcar días especiales en el calendario de citas:

1. Haz clic en **"Agregar día especial"**.
2. Selecciona la **fecha**.
3. Elige el **tipo:** festivo, cerrado, horario especial.
4. Escribe una **descripción** (opcional, ej. "Día del maestro").
5. Guarda.

Los días especiales aparecerán marcados en el calendario de alumnos y doctores y no permitirán agendar citas.

---

## 7. App móvil (Android)

La app móvil tiene las mismas funciones principales que la versión web:

**Para alumnos:**
- Login
- Ver y agendar citas
- Chat IA (pre-evaluación de síntomas)
- Historial médico y recetas
- Perfil médico (editable)
- Cambiar contraseña y foto de perfil

**Para doctores:**
- Login + 2FA
- Ver citas del día
- Agendar y cancelar citas para alumnos
- Pre-evaluaciones IA
- Bitácora e historial
- Clasificación de prioridad

**Notificaciones push:**
- Confirmación de cita agendada
- Aviso de cancelación o reprogramación
- Recordatorio 24 horas antes de tu cita

---

## 8. Notificaciones por email

El sistema envía correos automáticos en los siguientes eventos:

| Evento | Destinatario |
|--------|-------------|
| Recordatorio 24h antes de cita | Alumno y doctor |
| Código 2FA (solo doctores en producción) | Doctor |
| Enlace de recuperación de contraseña | Doctor o admin |

---

## 9. Cerrar sesión

Tanto en web como en la app, usa el botón **"Cerrar sesión"** del menú. Esto elimina tu sesión del servidor y borra el token local.

Si usas un equipo compartido, **siempre cierra sesión** al terminar.

---

## 10. Preguntas frecuentes

**¿Por qué no puedo seleccionar el domingo?**
El consultorio no atiende los domingos. Estos días siempre aparecen bloqueados en el calendario.

**¿Por qué un horario aparece en rojo?**
Ya está ocupado por otro alumno. Elige otro bloque disponible.

**¿Puedo cambiar la hora de mi cita?**
Cancela tu cita actual y agenda una nueva en el horario que desees. Solo el doctor puede reprogramar directamente.

**¿El diagnóstico de la IA es definitivo?**
No. Es un apoyo orientativo. El diagnóstico oficial lo da el doctor durante la consulta.

**No me llegó el código 2FA, ¿qué hago?**
Haz clic en **"Reenviar código"** en la pantalla de verificación. Revisa también tu carpeta de spam.

**¿Puedo usar la app sin conexión a internet?**
No. Tanto la web como la app requieren conexión para funcionar (la información está en la nube).
