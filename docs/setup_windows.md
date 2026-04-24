# Setup Yoltec en Windows

## 1. Instalar dependencias

Abre PowerShell 7 como administrador y corre:

```powershell
winget install PHP.PHP
winget install Composer.Composer
winget install OpenJS.NodeJS.LTS
winget install Python.Python.3.11
```

Cierra y reabre PowerShell 7, verifica que todo quedó bien:

```powershell
php -v && composer -v && node -v && python --version
```

---

## 2. Clonar el repositorio

```powershell
git clone https://github.com/elnemito001/Yoltec.git
cd Yoltec
```

---

## 3. Backend (Laravel)

```powershell
cd backend
composer install
copy .env.example .env
code .env
```

Reemplaza el contenido del `.env` con esto (llenando tus valores):

```env
APP_NAME=Yoltec
APP_ENV=local
APP_KEY=base64:zfLaLYOFnln8BDLkBVSDBxXKdDggX2RZhFBVlXXUeKo=
APP_DEBUG=true
APP_URL=http://localhost:8000

DB_CONNECTION=pgsql
DB_HOST=ep-shy-dawn-amz6fidi.c-5.us-east-1.aws.neon.tech
DB_PORT=5432
DB_DATABASE=neondb
DB_USERNAME=neondb_owner
DB_PASSWORD=TU_PASSWORD_DE_NEON
DB_SSLMODE=require

SESSION_DRIVER=file
SESSION_LIFETIME=120
BROADCAST_CONNECTION=log
FILESYSTEM_DISK=local
QUEUE_CONNECTION=database
CACHE_STORE=file

MAIL_MAILER=smtp
MAIL_HOST=smtp.gmail.com
MAIL_PORT=587
MAIL_USERNAME=nespiolin05@gmail.com
MAIL_PASSWORD=TU_APP_PASSWORD_GMAIL
MAIL_FROM_ADDRESS="nespiolin05@gmail.com"
MAIL_FROM_NAME="Yoltec"

IA_SERVICE_URL=http://127.0.0.1:5000
FRONTEND_URL=http://localhost:4200
```

Arranca el backend:

```powershell
php artisan serve --host=127.0.0.1 --port=8000
```

---

## 4. Frontend (Angular)

```powershell
cd ..\frontend
npm install
npm install -g @angular/cli
ng serve --host=0.0.0.0 --port=4200
```

Abre http://localhost:4200

---

## 5. IA (Python / FastAPI)

```powershell
cd ..\IA
python -m venv venv
.\venv\Scripts\Activate.ps1
pip install -r requirements.txt
python train_model_light.py
uvicorn app:app --host=0.0.0.0 --port=5000
```

Crea el archivo `IA\.env` con:

```env
GROQ_API_KEY=TU_KEY_DE_GROQ
GROQ_MODEL=llama-3.1-8b-instant
LLM_PROVIDER=groq
```

---

## Problema comun en Windows — scripts bloqueados

Si al activar el venv de Python te aparece un error de permisos, corre esto una sola vez:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

---

## Puertos

| Servicio  | URL                       |
|-----------|---------------------------|
| Backend   | http://127.0.0.1:8000     |
| Frontend  | http://localhost:4200      |
| IA        | http://127.0.0.1:5000     |
| DB        | Neon cloud (no requiere nada local) |

---

## Credenciales que necesitas tener a mano

| Dato | Donde conseguirlo |
|------|-------------------|
| `DB_PASSWORD` | neon.tech → tu proyecto → connection string |
| `MAIL_PASSWORD` | Google → Seguridad → Verificacion en 2 pasos → Contrasenas de aplicacion |
| `GROQ_API_KEY` | console.groq.com → API Keys |
