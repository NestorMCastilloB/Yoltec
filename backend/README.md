# Yoltec — Backend (Laravel 12)

API REST del sistema de consultorio médico universitario.

## Tecnologías
- Laravel 12 + Sanctum (autenticación por tokens)
- PostgreSQL en Neon (cloud, compartida)
- PHP 8.4+

## Correr en local

```bash
composer install
cp .env.example .env   # editar con credenciales reales
php artisan migrate
php artisan serve --host=127.0.0.1 --port=8000
```

> **No instalar PostgreSQL local** — la BD está en Neon (cloud).
> **Nunca ejecutar `migrate:fresh`** — la BD es compartida.

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
php artisan route:list              # ver todos los endpoints
php artisan optimize:clear          # limpiar caché
php artisan citas:notificar-proximas  # enviar recordatorios manuales
```
