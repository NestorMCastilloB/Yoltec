# Yoltec — Sistema de Consultorio Médico con IA

Sistema integral de gestión de consultorio médico universitario con inteligencia artificial integrada. Desarrollado como proyecto académico con stack moderno y aplicación móvil multiplataforma.

---

## Stack tecnológico

| Capa | Tecnología |
|------|-----------|
| Backend | Laravel 12 + Sanctum |
| Frontend web | Angular 20 |
| App móvil | Flutter / Dart (Android, iOS, Linux, Windows) |
| Base de datos | SQLite (local) → PostgreSQL/Neon (producción) |
| IA | Python 3 + scikit-learn (modelo propio, sin APIs de pago) |
| Contenedores | Docker + Docker Compose |

---

## Funcionalidades

### Alumno
- Login con número de control + NIP
- Calendario de citas (Lun–Sáb, 8:00–16:45, intervalos de 15 min)
- Pre-evaluación de síntomas con IA (diagnóstico preliminar + % de confianza)
- Historial de citas, bitácoras y recetas

### Doctor
- Login con usuario + contraseña
- Dashboard con citas del día, próxima cita y totales en tiempo real
- Clasificación de prioridad de pacientes por IA (alta / media / baja)
- Validar o descartar diagnósticos de pre-evaluación
- Crear bitácoras y recetas por consulta
- Agendar y cancelar citas a nombre de alumnos

### Seguridad
- Rate limiting en login (5 intentos/min)
- 2FA por correo (activo en producción, desactivado en local)
- Tokens Sanctum con expiración
- Headers de seguridad (X-Powered-By oculto, APP_DEBUG=false en producción)
- Validación de domingos y días festivos en backend y frontend

---

## Modelo de IA

- **Tipo**: Machine Learning supervisado (clasificación multiclase)
- **Algoritmo**: VotingClassifier — Random Forest + HistGradientBoosting + ExtraTrees
- **Precisión**: ~86% en test set
- **Entrenamiento**: Dataset de Kaggle + datos sintéticos generados (~200k registros)
- **Sin APIs externas**: todo corre localmente con scikit-learn

---

## Correr en local

### Requisitos
- PHP 8.2+, Composer
- Node.js 20+, Angular CLI
- Python 3.12+
- Flutter SDK
- Docker (opcional)

### Backend Laravel
```bash
cd backend
composer install
cp .env.example .env
php artisan key:generate
php artisan migrate --seed
php artisan serve --host=127.0.0.1 --port=8000
```

### Frontend Angular
```bash
cd frontend
npm install
ng serve --host=0.0.0.0 --port=4200
```

### Servicio IA (Python)
```bash
cd IA
python -m venv venv
source venv/bin/activate       # Linux/Mac
# venv\Scripts\activate        # Windows
pip install -r requirements.txt
python train_model.py          # genera model.pkl (~1.3 GB, no incluido en repo)
python app.py                  # inicia en puerto 5000
```

### App Flutter
```bash
cd mobile
flutter pub get
flutter run                    # emulador o dispositivo conectado
```

### Docker (todo junto)
```bash
docker-compose up --build
# Frontend: http://localhost:4200
# Backend:  http://localhost:8000
# IA:       http://localhost:5000
```

> **Nota**: `model.pkl` no está en el repositorio por su tamaño (1.3 GB).
> Genéralo ejecutando `python train_model.py` dentro de la carpeta `/IA`.

---

## Credenciales de prueba

| Rol | Usuario | Contraseña |
|-----|---------|-----------|
| Alumno | `22690495` | `740270` |
| Doctor | `doctorOmar` | `doctor123` |
| Doctor 2 | `doctorCarlos` | `doctor123` |

---

## Estructura del proyecto

```
yoltec/
├── backend/          # Laravel 12 — API REST
│   ├── app/Http/Controllers/
│   ├── app/Models/
│   ├── database/migrations/
│   └── routes/api.php
├── frontend/         # Angular 20 — SPA web
│   └── src/app/
│       ├── login/
│       ├── student-dashboard/
│       └── doctor-dashboard/
├── mobile/           # Flutter — Android / iOS / Desktop
│   └── lib/
│       ├── screens/
│       └── services/
├── IA/               # Python + scikit-learn
│   ├── train_model.py
│   ├── app.py
│   └── enfermedades_config.json
├── manual/           # Documentación técnica y de usuario
└── docker-compose.yml
```

---

## Endpoints principales (API REST)

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| POST | `/api/login` | Login alumno o doctor |
| GET | `/api/citas` | Listar citas del usuario |
| POST | `/api/citas` | Agendar cita |
| POST | `/api/citas/{id}/cancelar` | Cancelar cita |
| POST | `/api/citas/{id}/atender` | Marcar cita como atendida (doctor) |
| GET | `/api/pre-evaluacion/preguntas` | Obtener cuestionario IA |
| POST | `/api/pre-evaluacion` | Enviar respuestas y obtener diagnóstico |
| POST | `/api/pre-evaluacion/{id}/validar` | Validar/descartar diagnóstico (doctor) |
| GET | `/api/ia/priority/pendientes` | Citas clasificadas por prioridad (doctor) |
| GET | `/api/bitacoras` | Historial de consultas |
| POST | `/api/bitacoras` | Crear bitácora (doctor) |
| GET | `/api/recetas` | Listar recetas |
| POST | `/api/recetas` | Crear receta (doctor) |

---

## Documentación adicional

- [`manual/MANUAL_TECNICO.md`](manual/MANUAL_TECNICO.md) — Arquitectura, base de datos, despliegue
- [`manual/MANUAL_USUARIO.md`](manual/MANUAL_USUARIO.md) — Guía de uso por rol
- [`manual/informe-pentesting.md`](manual/informe-pentesting.md) — Informe de seguridad (OWASP)

---

## Estado del proyecto

| Módulo | Web | Móvil |
|--------|-----|-------|
| Login (alumno + doctor) | ✅ | ✅ |
| Calendario de citas | ✅ | ✅ |
| Pre-evaluación IA | ✅ | ✅ |
| Dashboard doctor | ✅ | ✅ |
| Clasificación prioridad IA | ✅ | ✅ |
| Bitácora | ✅ | ✅ |
| Recetas | ✅ | ✅ |
| 2FA | ✅ producción | ✅ producción |
| Deploy en la nube | pendiente | — |

---

Proyecto académico — Instituto Tecnológico, 2026
