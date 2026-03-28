# Yoltec — Backend (Laravel 12)

API REST del sistema de consultorio médico universitario.

## Tecnologías
- Laravel 12 + Sanctum (autenticación por tokens)
- SQLite en local / PostgreSQL en producción
- PHP 8.2+

## Correr en local

```bash
composer install
cp .env.example .env
php artisan key:generate
php artisan migrate --seed
php artisan serve --host=127.0.0.1 --port=8000
```

## Variables de entorno importantes

| Variable | Descripción |
|----------|-------------|
| `APP_ENV` | `local` desactiva 2FA, `production` lo activa |
| `APP_DEBUG` | `false` en producción |
| `IA_SERVICE_URL` | URL del servicio Python (default: `http://127.0.0.1:5000`) |
| `CACHE_STORE` | `file` para que funcione el rate limiting sin Redis |

## Endpoints principales

Ver [`routes/api.php`](routes/api.php) o el README raíz del proyecto.

## Comandos útiles

```bash
php artisan migrate:fresh --seed    # reiniciar BD con datos de prueba
php artisan route:list              # ver todos los endpoints
php artisan optimize:clear          # limpiar caché
```
