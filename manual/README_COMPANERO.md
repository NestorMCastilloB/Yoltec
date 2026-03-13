# 🚀 Yoltec - Paquete de Instalación para Desarrollador

## 📋 Contenido del Paquete

- `yoltec_db_completa.sql` - Base de datos completa con todas las tablas
- `.env.companero` - Archivo de configuración con credenciales de base de datos
- `yoltec/` - Código fuente del proyecto Laravel

## ⚡ Instalación Rápida

### 1. Requisitos
- PHP 8.2+
- Composer
- PostgreSQL (o conexión a Neon)

### 2. Configuración del Proyecto

```bash
# 1. Copiar el código fuente
cp -r yoltec /var/www/
cd /var/www/yoltec/backend

# 2. Instalar dependencias
composer install

# 3. Copiar archivo de entorno
cp .env.companero .env

# 4. La base de datos ya está configurada en Neon (no necesitas crearla)
# Solo verifica que puedes conectarte:
php artisan migrate:status
```

### 3. Iniciar Servidor

```bash
php artisan serve
# Accede a: http://localhost:8000
```

## 🔐 Credenciales de Base de Datos

La base de datos está alojada en **Neon** (PostgreSQL en la nube):

- **URL**: postgresql://neondb_owner:npg_mP8gE1UpSOwW@ep-noisy-darkness-a49s74zs-pooler.us-east-1.aws.neon.tech/neondb?sslmode=require&channel_binding=require

⚠️ **IMPORTANTE**: No compartas estas credenciales públicamente ni las subas a GitHub.

## 📞 Soporte

Si tienes problemas de conexión a la base de datos, contacta al administrador del proyecto.

## 🔧 Notas Técnicas

- El proyecto usa Laravel 10+
- La base de datos es PostgreSQL en Neon (serverless)
- El frontend está en Angular (carpeta `frontend/`)
- La app móvil está en Flutter (carpeta `app/`)
