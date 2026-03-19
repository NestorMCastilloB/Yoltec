# 🏥 Yoltec - Sistema de Consultorio Médico con IA

Sistema integral para gestión de consultorio médico con pre-evaluación IA para alumnos y validación por doctores.

## 📋 ¿Qué incluye Yoltec?

- **Gestión de Citas**: Calendario con horario 8am-5pm, intervalos 15 min
- **Bitácoras Médicas**: Registro de consultas con métricas vitales
- **Recetas**: Generación y consulta de recetas médicas
- **Pre-evaluación IA**: Diagnóstico preliminar basado en síntomas (validado por doctor)
- **Login diferenciado**: Alumnos (NIP) vs Doctores (password)

## 🏗️ Arquitectura (3 Bloques Docker)

```
yoltec/
├── backend/          # Laravel 10 + PostgreSQL (Neon)
│   ├── app/Models/
│   │   ├── User.php
│   │   ├── Cita.php
│   │   ├── Bitacora.php
│   │   ├── Receta.php
│   │   └── PreEvaluacionIA.php      ← IA integrada
│   ├── app/Http/Controllers/
│   │   ├── AuthController.php        ← Login diferenciado
│   │   ├── PreEvaluacionIAController.php
│   │   └── ...
│   └── routes/api.php
│
├── frontend/         # Angular 17+
│   ├── src/app/
│   │   ├── login/                    ← NIP para alumnos
│   │   ├── student-dashboard/      ← Pre-evaluación IA
│   │   ├── doctor-dashboard/       ← Validación IA
│   │   └── services/
│   │       ├── auth.service.ts
│   │       ├── pre-evaluacion-ia.service.ts
│   │       └── ...
│   └── src/assets/
│
├── IA/               # Python (Rule-based, no ML)
│   ├── enfermedades_config.json     ← Configuración de reglas
│   └── pre_evaluacion_ia.py         ← Motor de diagnóstico
│
└── mobile/           # (Futuro: Flutter/React Native)
```

## 🤖 Sistema de IA (Rule-Based)

**Tipo**: Inteligencia Artificial Simbólica basada en reglas  
**NO usa**: Machine Learning, Deep Learning, ni APIs externas  

### Cómo funciona:
1. Alumno responde preguntas sobre síntomas en el frontend
2. Backend envía respuestas al script Python (`pre_evaluacion_ia.py`)
3. Script calcula coincidencias con enfermedades configuradas en `enfermedades_config.json`
4. Retorna diagnóstico preliminar con nivel de confianza (0-100%)
5. Doctor valida o descarta el diagnóstico desde su panel

### Para mejorar la IA:
Edita `IA/enfermedades_config.json`:
```json
{
  "enfermedades": {
    "gripe": {
      "sintomas": ["fiebre", "dolor_cabeza", "dolor_cuerpo"],
      "pesos": {"fiebre": 3, "dolor_cabeza": 2},
      "recomendacion": "Reposo, líquidos..."
    }
  }
}
```

## 🚀 Instalación Rápida

### Requisitos
- Docker & Docker Compose
- Git

### 1. Clonar y configurar
```bash
git clone <repo>
cd yoltec
```

### 2. Configurar variables de entorno
```bash
# Backend
cp backend/.env.example backend/.env
# Editar backend/.env con credenciales de base de datos

# Frontend (si aplica)
cp frontend/.env.example frontend/.env.local
```

### 3. Iniciar con Docker
```bash
docker-compose up -d
```

### 4. Migraciones (primera vez)
```bash
docker-compose exec backend php artisan migrate
```

### 5. Acceder
- **Frontend**: http://localhost:4200
- **Backend API**: http://localhost:8000/api

## 🔐 Login

| Rol | Identificador | Contraseña |
|-----|---------------|------------|
| Alumno | Número de control (8 dígitos) | NIP (6 dígitos) |
| Doctor | Username | Password |

## 👥 Flujo de Usuarios

### Alumno:
1. Login con número de control + NIP
2. Agenda cita médica (calendario 8am-5pm)
3. Completa **pre-evaluación IA** antes de la cita
4. Recibe diagnóstico preliminar (confianza XX%)
5. Doctor valida durante la consulta

### Doctor:
1. Login con username + password
2. Ve citas programadas del día
3. Revisa **pre-evaluaciones IA pendientes**
4. Valida o descarta diagnóstico sugerido
5. Registra bitácora y receta

## 📁 Estructura de Carpetas (para desarrolladores)

```
yoltec/
├── backend/
│   ├── app/
│   │   ├── Models/           # Eloquent models
│   │   ├── Http/Controllers/ # API controllers
│   │   └── Services/         # Lógica de negocio
│   ├── database/
│   │   └── migrations/       # Esquema de BD
│   └── routes/
│       └── api.php           # Endpoints REST
│
├── frontend/
│   ├── src/app/
│   │   ├── login/           # Login diferenciado
│   │   ├── student-dashboard/ # Panel alumno
│   │   ├── doctor-dashboard/  # Panel doctor
│   │   └── services/        # HTTP services
│   └── src/assets/          # Logo, imágenes
│
├── IA/
│   ├── enfermedades_config.json
│   └── pre_evaluacion_ia.py
│
├── manual/                  # Documentación útil
│   └── README_COMPANERO.md  # Guía para colaboradores
│
└── docker-compose.yml       # Orquestación de contenedores
```

## 🛠️ Comandos Útiles

```bash
# Backend (Laravel)
docker-compose exec backend php artisan migrate
docker-compose exec backend php artisan db:seed
docker-compose exec backend php artisan optimize

# Frontend (Angular)
cd frontend && npm install && ng serve

# IA (Python)
cd IA && python pre_evaluacion_ia.py
```

## 📚 Documentación

- `manual/README_COMPANERO.md` - Guía para colaboradores Git
- `backend/README.md` - Documentación API Laravel
- `frontend/README.md` - Documentación Angular

## 📝 Notas para Colaboradores

### No subir a Git:
- Archivos `.env` con credenciales
- Carpetas `node_modules/`, `vendor/`, `venv/`
- Archivos de IDE (`.vscode/`, `.idea/`)
- Logs y archivos temporales

### Flujo de trabajo Git:
```bash
# 1. Crear rama para feature
git checkout -b feature/nueva-funcionalidad

# 2. Hacer cambios y commit
git add .
git commit -m "feat: descripción clara"

# 3. Push y Pull Request
git push origin feature/nueva-funcionalidad
# Crear PR en GitHub para revisión
```

## 🎓 Estado Actual

✅ **Implementado**:
- Login diferenciado (alumno/doctor)
- Splash screen con logo Yoltec
- Calendario 8am-5pm con intervalos 15 min
- Pre-evaluación IA rule-based
- Validación de diagnósticos por doctores
- Gestión de citas, bitácoras y recetas

⏳ **Pendiente**:
- IA de prioridad (clasificación de urgencia)
- App móvil
- Notificaciones push/email

---

**Proyecto académico** - Instituto Tecnológico

