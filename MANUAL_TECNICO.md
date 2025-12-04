# Manual Técnico – Yoltec

## 1. Descripción general del proyecto

Yoltec es un sistema de gestión de citas, bitácoras y recetas para un consultorio clínico académico. Está organizado como un monorepo con:

- **Backend**: API REST en Laravel 12 (`backend/`).
- **Frontend**: SPA en Angular 20 (`frontend/`).
- **Base de datos**: PostgreSQL alojado en Neon.
- **Contenedores**: `docker-compose` para levantar frontend y backend.

Repositorio: `https://github.com/elnemito001/Yoltec.git`

---

## 2. Estructura del repositorio

En la raíz del proyecto (`Yoltec/`):

- `backend/` – Código de la API Laravel.
- `frontend/` – Código de la app Angular.
- `docker-compose.yml` – Orquestación de los servicios frontend y backend.
- `README.md` – Descripción breve inicial.
- `MANUAL_USUARIO.md` – Manual de usuario.
- `MANUAL_TECNICO.md` – Este documento.

### 2.1. Backend (Laravel)

Estructura relevante dentro de `backend/`:

- `app/`
  - `Models/`
    - `User.php` – Usuarios (alumno/doctor).
    - `Cita.php` – Citas médicas.
    - `Bitacora.php` – Bitácoras médicas.
    - `Receta.php` – Recetas médicas.
  - `Http/Controllers/`
    - `AuthController.php` – Login/logout y datos del usuario autenticado.
    - `CitaController.php` – CRUD y lógica de citas.
    - `BitacoraController.php` – CRUD de bitácoras.
    - `RecetaController.php` – CRUD de recetas.
    - `PerfilController.php` – Ver y actualizar datos del usuario, cambio de contraseña.
- `config/`
  - `database.php` – Configuración de conexiones a BD.
  - `clinic.php` – Configuración de días especiales (feriados, etc.).
- `database/migrations/`
  - `0001_01_01_000000_create_users_table.php`
  - `2025_11_12_200331_create_citas_table.php`
  - `2025_11_12_200344_create_bitacoras_table.php`
  - `2025_11_12_200351_create_recetas_table.php`
- `routes/api.php` – Definición de endpoints de la API.
- `Dockerfile` – Imagen del backend.
- `.env.docker` – Variables de entorno para despliegue con Docker.

### 2.2. Frontend (Angular)

Estructura relevante dentro de `frontend/`:

- `src/app/`
  - `login/` – Pantalla de inicio de sesión.
  - `student-dashboard/` – Dashboard del alumno.
  - `doctor-dashboard/` – Dashboard del doctor.
  - `services/`
    - `auth.service.ts` – Manejo de autenticación y redirecciones.
    - `cita.service.ts` – Consumo del módulo de citas.
    - `bitacora.service.ts` – Consumo del módulo de bitácoras.
    - `receta.service.ts` – Consumo del módulo de recetas.
    - `api-config.ts` – URL base de la API.
  - `guards/`
    - `auth.guard.ts` – Protección de rutas según rol.
  - `interceptors/`
    - `auth.interceptor.ts` – Inyección del token en cada request.
  - `app.routes.ts` – Definición de rutas principales.
- `Dockerfile` – Imagen del frontend.
- `proxy.conf.json` – Proxy en desarrollo (`/api` → backend).
- `package.json` – Scripts de npm y dependencias.

---

## 3. Arquitectura y componentes

### 3.1. Arquitectura de alto nivel

- **Cliente (Angular)**
  - Autenticación basada en token (almacenado en `localStorage`).
  - Routing protegido por `AuthGuard`.
  - Comunicación HTTP con la API mediante `HttpClient`.
  - Un interceptor (`AuthInterceptor`) añade `Authorization: Bearer <token>` a todas las peticiones.

- **Servidor (Laravel)**
  - Autenticación vía Laravel Sanctum (`HasApiTokens` en `User`).
  - Middleware `auth:sanctum` protege rutas.
  - Patrón típico de Laravel con controladores y modelos Eloquent.

- **Base de datos**
  - PostgreSQL en Neon.
  - Conexión a través de `DB_URL` en `.env.docker` o `.env`.


### 3.2. Modelado de dominio

#### 3.2.1. Usuarios (`User`)

- Campos clave:
  - `numero_control` (alumnos).
  - `username` (doctores).
  - `nombre`, `apellido`, `email`, `password`, `tipo`, `telefono`, `fecha_nacimiento`.
- Campos ocultos (`hidden`): `password`, `remember_token`.
- Casts: `email_verified_at`, `password`, `fecha_nacimiento`.
- Métodos helper:
  - `esAlumno()` – `tipo === 'alumno'`.
  - `esDoctor()` – `tipo === 'doctor'`.
- Relaciones:
  - Citas, bitácoras y recetas tanto como alumno como doctor.

> Nota: Se evita el uso de `enum` y claves únicas estrictas en DB para hacer el esquema más tolerante en Neon. La unicidad y validación se controlan a nivel de aplicación.

#### 3.2.2. Citas (`Cita`)

- Campos:
  - `clave_cita`, `alumno_id`, `doctor_id`, `fecha_cita`, `hora_cita`, `motivo`, `estatus`, `fecha_hora_atencion`, `notas`.
- Casts:
  - `fecha_cita` como `date:Y-m-d`.
  - `hora_cita` como `string`.
  - `fecha_hora_atencion` como `datetime`.
- Relaciones:
  - `alumno()` – pertenece a `User`.
  - `doctor()` – pertenece a `User`.
  - `bitacora()` – tiene una `Bitacora`.
  - `receta()` – tiene una `Receta`.
- Método `generarClaveCita()`:
  - Genera una cadena `CITA-YYYYMMDD-XXXXXX` y garantiza que no se repita en la tabla.

#### 3.2.3. Bitácoras (`Bitacora`)

- Campos:
  - `cita_id`, `alumno_id`, `doctor_id`, `diagnostico`, `tratamiento`, `observaciones`, `peso`, `altura`, `temperatura`, `presion_arterial`.
- Relaciones:
  - `cita()` – pertenece a `Cita`.
  - `alumno()` – pertenece a `User`.
  - `doctor()` – pertenece a `User`.

#### 3.2.4. Recetas (`Receta`)

- Campos:
  - `cita_id`, `alumno_id`, `doctor_id`, `medicamentos`, `indicaciones`, `fecha_emision`.
- Casts:
  - `fecha_emision` como `date`.
- Relaciones:
  - `cita()` – pertenece a `Cita`.
  - `alumno()` – pertenece a `User`.
  - `doctor()` – pertenece a `User`.

> Regla de negocio importante: **una sola receta por cita**. Esto se hace a nivel de lógica de aplicación, no con una restricción única en DB.


### 3.3. Migraciones y base de datos

Las migraciones de `users`, `citas`, `bitacoras` y `recetas` están diseñadas para:

- Evitar `enum` y ciertas constraints estrictas que pueden causar problemas en Neon.
- Utilizar `foreignId` sin `->constrained()` y manejar integridad referencial desde la aplicación.

En particular:

- `users`:
  - `tipo` es `string` con valores lógicos `alumno`/`doctor`.
  - `email`, `numero_control` y `username` no tienen índices `unique` en la DB; se pueden agregar posteriormente según necesidad.

- `citas`:
  - `estatus` es `string` con valores esperados `programada`, `atendida`, `cancelada`.
  - `fecha_hora_atencion` registra cuándo se marcó la cita como atendida.

- `bitacoras` y `recetas`:
  - Usan `foreignId` para `cita_id`, `alumno_id`, `doctor_id` sin constraints formales.


### 3.4. Controladores y lógica principal

#### AuthController

- `login(Request $request)`
  - Valida `identificador` y `password`.
  - Busca usuario por `numero_control` o `username`.
  - Verifica contraseña con `Hash::check`.
  - Crea token usando Sanctum (`createToken('auth_token')`).
  - Devuelve datos del usuario y token.

- `logout(Request $request)`
  - Elimina el token de acceso actual.

- `me(Request $request)`
  - Devuelve el usuario autenticado.

#### CitaController

Reglas clave implementadas:

- **Auto-cancelación de citas pasadas**
  - Método privado `autoCancelPastAppointments()` pone `estatus = 'cancelada'` a citas `programada` con fecha/hora en el pasado.
  - Se llama al listar citas y al calcular disponibilidad de agenda.

- `index(Request $request)`
  - Si el usuario es alumno: devuelve sólo sus citas con relación `doctor`.
  - Si es doctor: devuelve todas las citas con relación `alumno`.

- `availability(Request $request)`
  - Recibe parámetros opcionales `month` y `year`.
  - Consulta citas `programada` en ese rango.
  - Agrupa por día generando `taken_slots` (horarios ocupados) y combina con `config('clinic.special_days')` para días especiales (feriados, vacaciones, horario reducido).

- `store(Request $request)`
  - Valida:
    - `fecha_cita` ≥ hoy.
    - `hora_cita` en formato `H:i`.
    - `numero_control` existente en `users` (si se envía).
  - Verifica que no exista cita `programada` con la misma fecha y hora.
  - Determina `alumno_id` según si el usuario autenticado es alumno o doctor.
  - Genera `clave_cita` única.
  - Crea la cita con estatus `programada`.

- `cancelar(Request $request, $id)`
  - Permisos:
    - Alumnos sólo pueden cancelar sus propias citas.
    - Doctores pueden cancelar cualquiera.
  - No permite cancelar citas con estatus `atendida`.

- `atender(Request $request, $id)`
  - Sólo permitida para usuarios `esDoctor()`.
  - Marca la cita como `atendida`, asigna `doctor_id` y registra `fecha_hora_atencion`.


#### BitacoraController

- `index(Request $request)`
  - Alumno: devuelve sólo sus bitácoras.
  - Doctor: devuelve todas las bitácoras.

- `store(Request $request)` (sólo doctor)
  - Valida que la cita exista (`cita_id`) y que todos los campos (diagnóstico, tratamiento, observaciones, peso, altura, temperatura, presión arterial) estén presentes.
  - Obtiene `alumno_id` desde la cita.
  - Crea la bitácora.

- `update(Request $request, $id)` (sólo doctor)
  - Permite editar todos los campos de la bitácora.


#### RecetaController

- `index(Request $request)`
  - Alumno: devuelve sólo sus recetas.
  - Doctor: devuelve todas las recetas.

- `store(Request $request)` (sólo doctor)
  - Valida `cita_id`, `medicamentos`, `indicaciones`, `fecha_emision`.
  - Si ya existe una receta con ese `cita_id`, devuelve 422 con mensaje indicando que sólo puede haber una receta por cita.
  - Asigna `alumno_id` desde la cita y `doctor_id` desde el usuario autenticado.

- `update(Request $request, $id)` (sólo doctor)
  - Permite editar medicamentos, indicaciones y fecha de emisión.


### 3.5. Configuración de días especiales del consultorio

Archivo `config/clinic.php`:

- `special_days`: arreglo de días con comportamientos especiales, por ejemplo:
  - Feriados, vacaciones, horarios reducidos.
- `types`: define tipo de día y su impacto en la disponibilidad (`status` y color para el calendario).

Estos datos se combinan con las citas reales en `CitaController@availability` para que el frontend marque los días como "Disponible", "Parcial", "Sin lugares" o especiales.

---

## 4. Frontend – Angular

### 4.1. Routing

Definido en `src/app/app.routes.ts`:

- `/login` → `LoginComponent`.
- `/student-dashboard` → `StudentDashboardComponent`, protegido con `AuthGuard` y `roles: ['alumno']`.
- `/doctor-dashboard` → `DoctorDashboardComponent`, protegido con `AuthGuard` y `roles: ['doctor']`.
- Rutas desconocidas redirigen a `/login`.

### 4.2. Autenticación en el frontend

`AuthService`:

- `login(identificador, password, expectedRole?)`:
  - Envía POST a `/api/login`.
  - Si obtiene token, lo guarda en `localStorage` y redirige al dashboard según `tipo` (`alumno` o `doctor`).
  - Si `expectedRole` no coincide con el tipo de usuario, lanza un error con mensaje para la UI.

- `logout()`:
  - Llama a `/api/logout`.
  - Limpia `localStorage` (`auth_token`, `user_data`).
  - Navega a `/login`.

`AuthGuard`:

- Verifica que exista `auth_token` en `localStorage`.
- Obtiene `user_data` y revisa si `user.tipo` está dentro de `route.data.roles`.
- Si no está autenticado o no tiene rol adecuado:
  - Redirige a `/login` o al dashboard adecuado.

`AuthInterceptor`:

- Antes de cada request:
  - Toma el token del `AuthService` y añade `Authorization: Bearer <token>`.
- Manejo de errores:
  - 401: cierra sesión y redirige a `/login`.
  - 403: registra error de acceso denegado en consola.


### 4.3. Gestión de citas en el frontend

Tanto `StudentDashboardComponent` como `DoctorDashboardComponent`:

- Construyen un calendario mensual con:
  - Días fuera del mes actual.
  - Días pasados (no seleccionables).
  - Días especiales según la respuesta de `/citas/disponibilidad` y `clinic.php`.
  - Domingos marcados como `full` y "Cerrado".
- Disponibilidad por día:
  - Se basa en `taken_slots` (horas ya ocupadas) y en el número total de bloques posibles (uno por cada 15 minutos de 7:00 a 21:00).
- Al seleccionar fecha y hora:
  - Se normaliza la hora a formato `HH:mm`.
  - Se comprueba que el slot no esté ocupado y no sea pasado.

Validaciones de UX cubren el requerimiento funcional:

- "En la sección de doctor, en bitácoras y recetas, debe mostrarse un mensaje cuando se intente agendar sin tener todos los campos completos":
  - Formularios de bitácoras y recetas muestran mensajes específicos si se intenta enviar sin completar campos obligatorios.
- "En recetas, no se deben poder generar múltiples recetas para una misma cita atendida":
  - El backend valida y retorna 422 si ya existe receta para `cita_id`.
  - El frontend sólo ofrece citas atendidas que aún no tienen receta al crear una nueva.
- "La fecha de emisión debe mostrarse en formato día/mes/año":
  - Se utiliza `Intl.DateTimeFormat('es-MX')` para mostrar fechas de recetas en formato local (día/mes/año).

---

## 5. Ejecución y despliegue

### 5.1. Desarrollo local con Docker

Desde la raíz del proyecto:

```bash
docker-compose up --build
```

Servicios:

- `backend`:
  - Construido desde `backend/Dockerfile`.
  - Ejecuta `php artisan serve` en el contenedor (puerto 8000).
  - Usa `.env.docker`, que ya está configurado para Neon vía `DB_URL`.

- `frontend`:
  - Construido desde `frontend/Dockerfile`.
  - Fase 1: imagen Node 20, ejecuta `npm ci` y `ng build`.
  - Fase 2: imagen Nginx que sirve `dist/login/browser` en el puerto 80.
  - Expuesto como `http://localhost:4200`.


### 5.2. Desarrollo sin Docker

**Backend**

1. Ir a `backend/`.
2. Configurar `.env` (puede basarse en `.env.docker`) con:
   - `DB_CONNECTION=pgsql`.
   - `DB_URL=postgresql://...` (cadena para Neon).
3. Ejecutar:
   ```bash
   composer install
   php artisan key:generate
   php artisan migrate
   php artisan serve --host=0.0.0.0 --port=8000
   ```

**Frontend**

1. Ir a `frontend/`.
2. Ejecutar:
   ```bash
   npm install
   npm start
   ```
3. `npm start` usa `proxy.conf.json` para dirigir `/api` a `http://localhost:8000`.

---

## 6. Extensión y mantenimiento

### 6.1. Agregar nuevos campos o entidades

1. Crear/editar migraciones en `database/migrations/`.
2. Ajustar modelos Eloquent (`app/Models`).
3. Actualizar controladores para manejar los nuevos campos.
4. Ajustar servicios y componentes en Angular para enviar/recibir los datos.
5. Ejecutar migraciones:
   ```bash
   php artisan migrate
   ```

### 6.2. Manejo de roles adicionales

Si en el futuro se agregan más roles (por ejemplo, "administrador"):

- Backend:
  - Agregar lógica en `User::esXxx()` o usar políticas/guards personalizados.
  - Ajustar controladores para restricciones adicionales.

- Frontend:
  - Actualizar `AuthGuard` para entender los nuevos roles.
  - Añadir rutas específicas con `data: { roles: [...] }`.


### 6.3. Puntos de mejora

- Añadir **tests automatizados** para controladores y servicios Angular.
- Aplicar índices y constraints en BD (por ejemplo en producción distinta a Neon) para garantizar unicidad de `email`, `numero_control`, `username`.
- Implementar una vista de administración para gestionar usuarios.
- Mejorar manejo de errores 403 en el frontend (mostrar página de acceso denegado).

---

## 7. Referencias rápidas

- **Login**: `POST /api/login`
- **Logout**: `POST /api/logout`
- **Usuario actual**: `GET /api/me`
- **Perfil**: `GET/PUT /api/perfil`, `POST /api/perfil/cambiar-password`
- **Citas**:
  - `GET /api/citas`
  - `POST /api/citas`
  - `GET /api/citas/disponibilidad`
  - `POST /api/citas/{id}/cancelar`
  - `POST /api/citas/{id}/atender`
- **Bitácoras**:
  - `GET /api/bitacoras`
  - `POST /api/bitacoras`
  - `GET /api/bitacoras/{id}`
  - `PUT /api/bitacoras/{id}`
- **Recetas**:
  - `GET /api/recetas`
  - `POST /api/recetas`
  - `GET /api/recetas/{id}`
  - `PUT /api/recetas/{id}`

Con esto tienes una visión completa de la arquitectura, módulos y flujos principales del sistema Yoltec para continuar su desarrollo y mantenimiento.
