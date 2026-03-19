# 🚀 Yoltec - Guía para Colaboradores

## 📋 Estructura del Proyecto (3 Bloques Docker)

```
yoltec/
├── backend/          # Laravel 10 + PostgreSQL (Neon)
├── frontend/         # Angular 17+
├── IA/               # Python (Rule-based)
└── mobile/           # (Futuro)
```

## ⚡ Instalación Rápida

### Requisitos
- Docker & Docker Compose
- Git

### 1. Clonar repositorio
```bash
git clone <repo>
cd yoltec
```

### 2. Iniciar con Docker
```bash
docker-compose up -d
```

### 3. Migraciones (primera vez)
```bash
docker-compose exec backend php artisan migrate
```

### 4. Acceder
- **Frontend**: http://localhost:4200
- **Backend API**: http://localhost:8000/api

## 🔐 Configuración Local (NO subir a Git)

Crea estos archivos localmente:

### backend/.env
```
DB_CONNECTION=pgsql
DB_URL=postgresql://...
```

### frontend/.env.local
```
# Variables de entorno Angular (si aplica)
```

## 🤝 Flujo de Trabajo Git

### 1. Crear rama para tu feature
```bash
git checkout -b feature/nombre-descriptivo
```

### 2. Hacer cambios
- Backend: `backend/`
- Frontend: `frontend/`
- IA: `IA/`

### 3. Commit y push
```bash
git add .
git commit -m "feat: descripción clara del cambio"
git push origin feature/nombre-descriptivo
```

### 4. Pull Request
Crea PR en GitHub para revisión antes de merge a `main`.

## 📁 Qué NO subir a Git

```gitignore
# Archivos de entorno
.env
.env.local
.env.companero

# Dependencias
node_modules/
vendor/
venv/

# IDEs
.vscode/
.idea/

# Logs y temporales
*.log
*.tmp
.DS_Store
```

## 🏗️ Arquitectura por Bloques

### Bloque 1: Backend (Laravel)
```
backend/
├── app/Models/           # User, Cita, Bitacora, Receta, PreEvaluacionIA
├── app/Http/Controllers/ # AuthController, CitaController, etc.
├── database/migrations/   # Esquema de BD
└── routes/api.php       # Endpoints REST
```

### Bloque 2: Frontend (Angular)
```
frontend/src/app/
├── login/                 # Login diferenciado (NIP/password)
├── student-dashboard/     # Panel alumno + pre-evaluación IA
├── doctor-dashboard/      # Panel doctor + validación IA
└── services/              # Auth, Cita, Bitacora, PreEvaluacionIA
```

### Bloque 3: IA (Python)
```
IA/
├── enfermedades_config.json    # Reglas de diagnóstico
└── pre_evaluacion_ia.py        # Motor IA (rule-based)
```

## 📝 Comandos Útiles

```bash
# Backend
docker-compose exec backend php artisan migrate
docker-compose exec backend php artisan db:seed

# Frontend (desarrollo local)
cd frontend && npm install && ng serve

# Ver logs
docker-compose logs -f backend
docker-compose logs -f frontend
```

## 🎓 Información Académica

- **Proyecto**: Sistema de Consultorio Médico con IA
- **IA**: Rule-based (no ML), 100% propio
- **Funcionalidades**: Citas, bitácoras, recetas, pre-evaluación IA
- **Stack**: Laravel + Angular + PostgreSQL + Docker

## 📞 Soporte

Si tienes problemas de conexión o configuración, revisa:
1. `README.md` en raíz del proyecto
2. Logs de Docker: `docker-compose logs`
3. Variables de entorno en `backend/.env`

---

**Nota**: Este proyecto usa IA basada en reglas (no requiere entrenamiento con datasets). Para mejorar la IA, edita `IA/enfermedades_config.json`.
