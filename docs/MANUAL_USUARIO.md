# Manual de Usuario – Yoltec

## 1. Introducción

Yoltec es un sistema web para la gestión de citas médicas, bitácoras y recetas entre alumnos y doctores. Este manual explica cómo usar el sistema desde la perspectiva de un usuario final (alumno o doctor).

El sistema tiene dos partes:
- Una **API backend** (Laravel) que se comunica con la base de datos.
- Una **aplicación web frontend** (Angular) que ves en el navegador.

---

## 2. Acceso al sistema

### 2.1. Acceso con Docker (modo producción/despliegue local)

1. Abre una terminal en la carpeta raíz del proyecto `Yoltec`.
2. Ejecuta:
   ```bash
   docker-compose up --build
   ```
3. Cuando los servicios estén arriba:
   - Abre el navegador en: `http://localhost:4200` → Aplicación web de Yoltec.

> Nota: El backend se expone en `http://localhost:8000/api`, pero normalmente no necesitas acceder directamente; el frontend lo usa internamente.

### 2.2. Acceso en modo desarrollo (sin Docker)

**Backend (Laravel):**
1. Entra a la carpeta `backend/`.
2. Configura tu archivo `.env` con la conexión a la base de datos Neon.
3. Ejecuta:
   ```bash
   composer install
   php artisan migrate
   php artisan serve --host=0.0.0.0 --port=8000
   ```

**Frontend (Angular):**
1. Entra a la carpeta `frontend/`.
2. Ejecuta:
   ```bash
   npm install
   npm start
   ```
3. Abre `http://localhost:4200` en el navegador.

---

## 3. Roles de usuario

El sistema maneja dos tipos de usuario:

- **Alumno** (`tipo = alumno`)
  - Puede agendar y cancelar sus propias citas.
  - Puede consultar sus bitácoras médicas.
  - Puede consultar sus recetas médicas.

- **Doctor** (`tipo = doctor`)
  - Puede agendar citas para alumnos.
  - Puede cancelar citas.
  - Puede marcar citas como "atendidas".
  - Puede registrar y editar bitácoras.
  - Puede registrar y editar recetas.

Dependiendo del tipo de usuario, verás un panel distinto después de iniciar sesión.

---

## 4. Inicio de sesión

1. Entra a `http://localhost:4200`.
2. Verás una pantalla de login con dos pestañas:
   - **Estudiante**
   - **Doctor**

### 4.1. Pestaña "Estudiante"

Campos:
- **Número de Control o Usuario**: puedes usar tu número de control o tu nombre de usuario.
- **Contraseña**: tu contraseña de acceso.

Pasos:
1. Selecciona la pestaña **Estudiante**.
2. Llena los campos.
3. Haz clic en **"Iniciar Sesión"**.

### 4.2. Pestaña "Doctor"

Campos:
- **Usuario**: tu `username` como doctor.
- **Contraseña**.

Pasos:
1. Selecciona la pestaña **Doctor**.
2. Llena los campos.
3. Haz clic en **"Iniciar Sesión"**.

### 4.3. Mensajes de error frecuentes

- Si las credenciales no son válidas, verás:
  - `Las credenciales son incorrectas.`
- Si inicias sesión con un usuario de tipo diferente a la pestaña seleccionada (por ejemplo, un alumno en la pestaña de doctor), el sistema te mostrará un mensaje indicando que el tipo de usuario no coincide con la pestaña.

Tras un inicio de sesión exitoso:
- Si eres **alumno**, irás a `/student-dashboard`.
- Si eres **doctor**, irás a `/doctor-dashboard`.

---

## 5. Panel del Alumno

Al entrar como alumno verás el **Student Dashboard**, con un menú superior con las secciones:

- **Inicio**
- **Citas**
- **Bitácora**
- **Recetas**

Y un botón para **Cerrar sesión**.

### 5.1. Sección "Inicio"

Muestra un resumen rápido:

- **Próxima Cita**
  - Fecha de tu cita más cercana en el futuro.
  - Hora de la cita.
  - Motivo (si fue capturado).

- **Citas Programadas**
  - Número total de citas con estatus "programada".

Si no tienes citas futuras, aparece un mensaje indicando que no tienes citas programadas.

### 5.2. Sección "Citas" (Alumno)

En esta sección puedes **agendar nuevas citas** y **cancelar citas pendientes**.

#### 5.2.1. Agendar una cita nueva

1. Haz clic en **"Agendar Nueva Cita"**.
2. En el formulario:
   - Selecciona la **fecha** en el calendario.
     - Los **domingos** se muestran como día cerrado y no se pueden elegir.
     - Los días llenos se muestran como "sin lugares".
   - Selecciona una **hora** disponible.
     - El horario va de **7:00 a 21:00** en bloques de **15 minutos**.
     - No puedes seleccionar horarios pasados del mismo día.
     - No puedes seleccionar bloques que ya están ocupados.
   - (Opcional) Escribe el **motivo** de tu consulta.
3. Haz clic en **"Guardar cita"**.

Posibles mensajes:
- Si el horario ya está ocupado:
  - `La hora seleccionada ya está ocupada. Elige otro bloque disponible.`
- Si falta seleccionar fecha u hora, el sistema no permitirá guardar y mostrará mensajes de ayuda bajo los campos.

#### 5.2.2. Ver y cancelar citas

La sección muestra dos columnas:

- **Próximas citas** (estatus `programada`):
  - Fecha y hora.
  - Motivo (si existe).
  - Doctor asignado (si ya hay uno).
  - Botón **"Cancelar cita"**.

- **Historial reciente** (citas `atendida` o `cancelada`):
  - Fecha y hora.
  - Motivo.
  - Estatus: "Atendida" o "Cancelada".

Al cancelar una cita verás un mensaje como:
- `Cita cancelada correctamente.`

> Nota: El sistema también marca automáticamente como "canceladas" las citas que quedan en el pasado sin haberse atendido.

### 5.3. Sección "Bitácora" (Alumno)

Aquí puedes consultar las **bitácoras médicas** registradas por el doctor.

Para cada bitácora se muestra:
- Nombre del alumno (tú).
- Información de la cita asociada (fecha y hora).
- Fecha y hora de creación de la bitácora.
- **Diagnóstico**, **Tratamiento** y **Observaciones**.
- Medidas como **peso**, **altura**, **temperatura** y **presión arterial** (si el doctor las capturó).

Las bitácoras son de solo lectura para el alumno.

### 5.4. Sección "Recetas" (Alumno)

Aquí puedes consultar tus **recetas médicas**.

Para cada receta verás:
- Nombre del alumno.
- Datos de la cita (fecha y hora).
- **Fecha de emisión** de la receta.
- **Medicamentos recetados**.
- **Indicaciones** del doctor (si las hay).

No puedes editar las recetas; son únicamente de consulta.

---

## 6. Panel del Doctor

Al entrar como doctor verás el **Doctor Dashboard**, con las secciones:

- **Inicio**
- **Citas**
- **Bitácoras**
- **Recetas**

Y un botón de **Cerrar sesión**.

### 6.1. Sección "Inicio"

Muestra estadísticas generales:

- **Citas del día**: número de citas programadas para la fecha actual.
- **Pacientes atendidos**: total de citas que se han marcado como "atendidas".
- **Citas pendientes**: total de citas con estatus "programada".

### 6.2. Sección "Citas" (Doctor)

Desde aquí el doctor puede **agendar citas** para los alumnos, **cancelar citas** y **marcarlas como atendidas**.

#### 6.2.1. Agendar cita para un alumno

1. Haz clic en **"Agendar Nueva Cita"**.
2. Llena los campos:
   - **Número de control del alumno** (obligatorio).
   - **Fecha**: selección en el calendario (no se permiten domingos ni días sin cupo).
   - **Hora**: selección en la lista de horarios disponibles.
   - **Motivo** (opcional).
3. Haz clic en **"Guardar cita"**.

Mensajes importantes:
- Si el formulario es inválido o falta el número de control:
  - `Ingresa el número de control del alumno.`
- Si el horario ya está ocupado o en el pasado:
  - `La hora seleccionada ya está ocupada. Elige otro bloque disponible.`

#### 6.2.2. Cancelar o marcar cita como atendida

En la lista de **Próximas citas**, cada tarjeta tiene opciones:

- **Cancelar cita**
  - Cambia el estatus a `cancelada`.
  - Muestra el mensaje `Cita cancelada correctamente.` cuando tiene éxito.

- **Marcar atendida**
  - Cambia el estatus a `atendida`.
  - Asigna el doctor actual a la cita y registra la fecha y hora de atención.
  - Actualiza estadísticas y listas de citas.

Las citas atendidas y canceladas se muestran en el **historial reciente**.

### 6.3. Sección "Bitácoras" (Doctor)

Permite **registrar** nuevas bitácoras médicas y **editar** las existentes.

#### 6.3.1. Registrar bitácora

1. Haz clic en **"Registrar Bitácora"**.
2. Completa el formulario:
   - **Cita atendida**: selecciona de la lista de citas con estatus "atendida" que aún no tienen bitácora.
   - **Diagnóstico**.
   - **Tratamiento**.
   - **Observaciones**.
   - **Peso**.
   - **Altura**.
   - **Temperatura**.
   - **Presión arterial**.
3. Haz clic en **"Guardar bitácora"**.

Validaciones y mensajes:
- Si no seleccionas una cita atendida:
  - `Selecciona la cita atendida correspondiente.`
- Si falta cualquier otro campo obligatorio:
  - `Por favor completa todos los campos obligatorios de la bitácora.`

#### 6.3.2. Editar bitácora

1. En la lista de bitácoras, haz clic en **"Editar bitácora"** en el registro que quieres modificar.
2. Se abrirá el formulario con los datos actuales.
3. Ajusta la información.
4. Guarda los cambios.

El alumno verá siempre la versión actualizada de la bitácora.

### 6.4. Sección "Recetas" (Doctor)

Permite **crear** y **editar** recetas para las citas atendidas.

#### 6.4.1. Registrar receta nueva

1. Haz clic en **"Registrar Receta"**.
2. Completa el formulario:
   - **Cita atendida**: selecciona una cita con estatus "atendida" que aún no tenga receta.
   - **Fecha de emisión**: se puede ajustar; por defecto se usa la fecha de la cita.
   - **Medicamentos recetados**: texto libre con nombres, dosis, etc.
   - **Indicaciones**: instrucciones para el paciente.
3. Haz clic en **"Guardar receta"**.

Validaciones:
- Si no seleccionas cita:
  - `Selecciona la cita atendida correspondiente.`
- Si no llenas medicamentos, indicaciones o fecha de emisión, se mostrarán mensajes indicando qué falta.
- Si ya existe una receta para esa misma cita, se mostrará un mensaje similar a:
  - `Ya existe una receta registrada para esta cita. Puedes editar la existente en lugar de crear otra.`

> Importante: Solo se permite **una receta por cada cita atendida**.

#### 6.4.2. Editar receta existente

1. En la lista de recetas, haz clic en **"Editar receta"**.
2. Se abrirá el formulario con los datos actuales (medicamentos, indicaciones, fecha de emisión).
3. Realiza los cambios necesarios.
4. Guarda la receta.

Cuando editas, la cita asociada no se puede cambiar.

---

## 7. Cerrar sesión

Tanto en el panel de alumno como en el de doctor, en la parte superior derecha hay un botón **"Cerrar Sesión"**.

Al hacer clic:
- Se cierra tu sesión en el servidor.
- Se eliminan el token y los datos de usuario almacenados en el navegador.
- Se te redirige a la pantalla de inicio de sesión.

---

## 8. Buenas prácticas de uso

- No compartas tu usuario ni contraseña.
- Si usas un equipo compartido, **cierra sesión** al terminar.
- Como alumno, revisa tu bitácora y recetas después de cada consulta para confirmar que la información sea correcta.
- Como doctor, procura llenar todos los campos de bitácoras y recetas de forma clara y legible.
