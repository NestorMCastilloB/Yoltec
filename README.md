<div align="center">

# Yoltec

### Consultorio médico universitario con inteligencia artificial

Plataforma integral (web + móvil) para la gestión de citas, recetas y pre-evaluación de síntomas con IA, desarrollada para el consultorio del **Instituto Tecnológico Superior de Ciudad Valles (ITSV)**.

[![Laravel](https://img.shields.io/badge/Laravel-12-FF2D20?logo=laravel&logoColor=white)](https://laravel.com)
[![Angular](https://img.shields.io/badge/Angular-20-DD0031?logo=angular&logoColor=white)](https://angular.dev)
[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Python](https://img.shields.io/badge/Python-3.12-3776AB?logo=python&logoColor=white)](https://python.org)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-Neon-336791?logo=postgresql&logoColor=white)](https://neon.tech)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)

**[ Demo en vivo ](https://yoltec.vercel.app)** · **[ APK Android ](https://github.com/NestorMCastilloB/Yoltec/releases)** · **[ Documentación ](docs/)**

</div>

---

<div align="center">
<table>
<tr>
<td width="50%"><img src="docs/capturas/web/alumno-03-pre-evaluacion.png" alt="Pre-evaluación con IA"/></td>
<td width="50%"><img src="docs/capturas/web/doctor-02-citas.png" alt="Gestión de citas"/></td>
</tr>
</table>
</div>

---

## Sobre el proyecto

Yoltec digitaliza el flujo completo del consultorio médico universitario: agendado, atención, recetas, historial y reportes. Integra **dos componentes de IA** que asisten al doctor sin sustituirlo:

- **Prioridad de atención** (heurística ponderada, PHP): ordena las citas pendientes según el historial del alumno — visitas recientes, inasistencias, cancelaciones y condiciones crónicas detectadas en su bitácora. No es un modelo entrenado con datos reales: son factores con pesos ajustables sobre un dataset sintético.
- **Pre-evaluación conversacional** (`scikit-learn` + `Groq`/`Llama 3.1 8B` opcional): orienta al alumno antes de la consulta, sugiere diagnóstico preliminar con porcentaje de confianza y aviso explícito de que **no sustituye al médico**. El diagnóstico lo da siempre el modelo propio; el LLM solo conduce la charla, y si no está disponible el chat sigue funcionando con un guion de preguntas y extracción de síntomas por reglas.

El sistema cubre tres roles (alumno, doctor, administrador) en web responsiva y una app móvil exclusiva para estudiantes.

---

## Características destacadas

- Tres roles con interfaz adaptada: alumno, doctor y administrador
- **Dos componentes de IA**, con revisión posterior del doctor sobre cada pre-evaluación
- Calendario con disponibilidad real (slots de 15 min, días especiales, festivos)
- Recetas digitales sin generación de PDF (visualización directa)
- Bitácora del consultorio exportable a CSV
- Autenticación con **Laravel Sanctum** + **2FA** por correo para doctores y admin
- Modo oscuro en web y móvil
- Diseño responsivo, mobile-first en web
- Rate limiting, headers de seguridad y CORS con allowlist
- Pruebas automatizadas del backend y del microservicio de IA, ejecutadas junto con la compilación en cada Pull Request

---

## Stack tecnológico

| Capa          | Tecnología                                                  |
| ------------- | ----------------------------------------------------------- |
| Backend       | Laravel 12 · PHP 8.4 · Sanctum                              |
| Frontend web  | Angular 20 · TypeScript · RxJS · Chart.js                   |
| App móvil     | Flutter 3.x · Dart 3 · Material 3                           |
| IA            | Python 3.12 · FastAPI · scikit-learn · Groq opcional (Llama 3.1 8B) |
| Base de datos | PostgreSQL (Neon, SSL)                                      |
| Notificaciones| Firebase Cloud Messaging                                    |
| Email         | Resend/SMTP (despliegues) · Mailpit (local)               |
| Infraestructura | Docker · Docker Compose · Render · Vercel                 |

---

## Arquitectura

```
┌─────────────────┐   ┌──────────────────┐   ┌──────────────────┐
│  Frontend web   │   │  App móvil       │   │  Admin (web)     │
│  Angular 20     │   │  Flutter 3.x     │   │  Angular 20      │
│  Doctor         │   │  Estudiantes     │   │  CRUD usuarios   │
└────────┬────────┘   └────────┬─────────┘   └────────┬─────────┘
         │                     │                      │
         └──────────────┬──────┴───────┬──────────────┘
                        │              │
                        ▼              ▼
                ┌──────────────────────────┐
                │   Backend Laravel 12     │
                │   API REST + Sanctum     │
                └────────┬─────────────────┘
                         │
              ┌──────────┴──────────┐
              ▼                     ▼
   ┌────────────────────┐   ┌────────────────────┐
   │  PostgreSQL Neon   │   │  Microservicio IA  │
   │  (cloud)           │   │  FastAPI + sklearn │
   └────────────────────┘   └────────────────────┘
```

---

## Capturas

### Web — Acceso

![Login dual](docs/capturas/web/00-login.png)

Login dual con selector de rol estudiante o doctor. El alumno ingresa con número de control y NIP de 6 dígitos; el doctor con usuario y contraseña. El acceso administrativo está oculto en `/acceso-gestion` y exige 2FA.

### Web — Alumno

| Inicio | Mis citas |
|:-:|:-:|
| ![](docs/capturas/web/alumno-01-inicio.png) | ![](docs/capturas/web/alumno-02-mis-citas.png) |

| Recetas | Perfil |
|:-:|:-:|
| ![](docs/capturas/web/alumno-04-recetas.png) | ![](docs/capturas/web/alumno-05-perfil.png) |

### Web — Doctor

| Bitácora | Pre-evaluaciones IA |
|:-:|:-:|
| ![](docs/capturas/web/doctor-03-bitacoras.png) | ![](docs/capturas/web/doctor-05-pre-evaluaciones.png) |

### Web — Administrador

![Días especiales](docs/capturas/web/admin-03-dias-especiales.png)

Gestión del calendario administrativo: días no laborables, festivos y horarios reducidos. El calendario respeta estas reglas al ofrecer disponibilidad a los alumnos.

### Móvil — Flutter (exclusivo alumno)

<table>
<tr>
<td><img src="docs/capturas/movil/movil-01-inicio.jpeg" width="200"/></td>
<td><img src="docs/capturas/movil/movil-03-citas-pasadas.jpeg" width="200"/></td>
<td><img src="docs/capturas/movil/movil-06-recetas-vacio.jpeg" width="200"/></td>
<td><img src="docs/capturas/movil/movil-12-pre-evaluacion-ia.jpeg" width="200"/></td>
</tr>
<tr>
<td align="center">Inicio</td>
<td align="center">Historial</td>
<td align="center">Recetas</td>
<td align="center">Pre-evaluación IA</td>
</tr>
</table>

### Móvil — Modo oscuro

<table>
<tr>
<td><img src="docs/capturas/movil/movil-11-inicio-oscuro.jpeg" width="200"/></td>
<td><img src="docs/capturas/movil/movil-09-recetas-oscuro.jpeg" width="200"/></td>
</tr>
<tr>
<td align="center">Inicio</td>
<td align="center">Recetas</td>
</tr>
</table>

---

## Roles y funcionalidades

### Estudiante (app móvil)
- Login con número de control + NIP de 6 dígitos.
- Calendario de citas (Lun–Sáb, 8:00–17:00, slots de 15 min).
- Pre-evaluación conversacional con IA, asociada a la próxima cita.
- Historial de citas (Próximas / Pasadas / Canceladas).
- Recetas con detalle de medicación.
- Perfil médico editable (alergias, crónicas, contacto de emergencia).

### Doctor (web)
- Login con usuario + contraseña + 2FA por correo.
- Dashboard con KPIs en tiempo real (citas, atendidas, asistencia).
- Validación de diagnósticos de pre-evaluación generados por IA.
- Creación de consultas, bitácoras y recetas.
- Agendar y cancelar citas a nombre de alumnos.
- Citas pendientes ordenadas por prioridad estimada.
- Exportación de bitácora a CSV.

### Administrador (web, ruta oculta)
- CRUD de alumnos y doctores.
- Gestión del calendario (días especiales, cierres).
- Acceso vía `/acceso-gestion` (no enlazado desde el login público).
- 2FA obligatorio, sin excepción por entorno.

---

## Instalación

Para desarrollar sin las credenciales antiguas, sigue la
[guía de desarrollo local](docs/desarrollo-local.md). Requiere Docker Engine,
Compose, Bash y OpenSSL.

```bash
./local.sh up
./local.sh seed
```

Esto crea PostgreSQL local, construye Laravel y Angular, inicia la IA y prepara
un buzón Mailpit para probar correo y 2FA. No utiliza los `.env` heredados ni
conecta a Neon. La primera construcción descarga las dependencias.

| Servicio | URL local |
| --- | --- |
| Aplicación | http://localhost:4200 |
| Backend | http://localhost:8000/api/health |
| Correo de prueba | http://localhost:8025 |
| IA | http://localhost:5000/health |

La IA funciona sin clave de Groq: el chat pasa a modo guiado y sigue
entregando diagnóstico. Consulta las cuentas ficticias y los pasos de 2FA en la guía.

Pruebas: `./local.sh test`. Detener conservando datos: `./local.sh down`.

El arranque nativo `./start.sh` necesita PHP 8.4 con sus extensiones, Composer,
Node compatible con Angular 20, Python 3.12 y una base PostgreSQL aislada,
configurados por separado. No ejecutes ese camino con los `.env` antiguos sin
revisar primero el destino de la conexión.

La configuración de Flutter se abordará por separado; este entorno levanta la
aplicación web, el backend y el microservicio de IA.

---

## Configuración de entorno

Cada subproyecto trae una plantilla de variables. El entorno Docker local genera
`.env.local`, ignorado por Git. Hubo credenciales expuestas en el historial:
retirarlas del árbol actual no sustituye su revocación en los proveedores.

| Variable                          | Dónde se usa | Cómo obtenerla                          |
| --------------------------------- | ------------ | --------------------------------------- |
| `APP_KEY`                         | Laravel      | `php artisan key:generate`              |
| `DB_HOST`, `DB_PASSWORD`          | Laravel      | Panel de Neon (o tu PostgreSQL)         |
| `GROQ_API_KEY`                    | IA           | https://console.groq.com                |
| `MAIL_USERNAME`, `MAIL_PASSWORD`  | Laravel      | Gmail App Password o Resend             |
| `FIREBASE_CREDENTIALS`            | Laravel      | Service account JSON desde Firebase     |
| `DEMO_MODE`, `DEMO_USUARIOS`      | Laravel      | Ver el bloque «Modo demostración» de `.env.example` |

---

## Seguridad

- Contraseñas y NIPs almacenados con **bcrypt**.
- Tokens Sanctum con expiración de 24 h y purga automática diaria.
- **2FA obligatorio** para doctores y administradores, en todos los entornos. El código llega por correo, salvo en las cuentas de demostración: ahí se muestra en pantalla, porque el plan gratuito de Resend solo entrega al correo verificado de la cuenta y un visitante no podría recibirlo. El segundo factor no se desactiva —el código sigue caducando a los 10 minutos y sigue siendo de un solo uso—, solo cambia por dónde llega, y únicamente en las cuentas nombradas en `DEMO_USUARIOS`.
- Rate limiting (`throttle:5,1`) en endpoints sensibles (login, 2FA, reset).
- CORS con allowlist explícita, sin wildcards en producción.
- Headers de seguridad (`SecurityHeaders` middleware): HSTS y X-Frame-Options. CSP pendiente de implementar.
- Para reportar vulnerabilidades: [`SECURITY.md`](SECURITY.md).

> Los datos que se ven en la instancia desplegada son de **demostración**: no hay expedientes de personas reales. Aun así, es una instancia compartida, así que las credenciales de acceso **no se publican en este README** — solicítalas si necesitas revisarla.

---

## Despliegue

| Servicio | Plataforma | URL                                           |
| -------- | ---------- | --------------------------------------------- |
| Frontend | Vercel     | https://yoltec.vercel.app                     |
| Backend  | Render     | https://yoltec-backend.onrender.com           |
| IA       | Render     | https://yoltec-ia.onrender.com                |
| BD       | Neon       | privada                                       |

Los releases del APK móvil se publican en [GitHub Releases](https://github.com/NestorMCastilloB/Yoltec/releases).

---

## Estructura del repositorio

```
Yoltec/
├── backend/          Laravel 12 — API REST + IA de priorización
├── frontend/         Angular 20 — SPA web (alumno + doctor + admin)
├── mobile/           Flutter — App estudiante (Android)
├── IA/               Python + FastAPI — sklearn + LLM opcional
├── docs/             Documentación técnica, capturas y entregables
├── docker-compose.yml
├── README.md
├── LICENSE
├── SECURITY.md
└── CONTRIBUTING.md
```

---

## Contribuir

Lee primero [`CONTRIBUTING.md`](CONTRIBUTING.md): flujo de ramas, convenciones de commit y qué se comprueba antes de fusionar.

`main` está protegida — solo se actualiza por Pull Request y con el CI en verde, sin excepciones para nadie.

```bash
git checkout main && git pull
git checkout -b feat/descripcion-corta
git commit -m "feat(ambito): descripción breve"
git fetch origin && git rebase origin/main
git push -u origin feat/descripcion-corta
gh pr create --base main
```

Convención de commits: `feat` · `fix` · `docs` · `refactor` · `perf` · `test` · `chore` · `ci` · `build` · `style`.

---

## Licencia

Distribuido bajo licencia **MIT**. Consulta [`LICENSE`](LICENSE) para más detalles.

---

<div align="center">
<sub>Proyecto académico · Instituto Tecnológico Superior de Ciudad Valles (ITSV) · 2026</sub>
</div>
