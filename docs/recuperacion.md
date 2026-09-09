# Recuperación de Yoltec

Diagnóstico inicial del checkout local, 8 de septiembre de 2026. El contenido
del artifact de Claude no estuvo disponible durante esta revisión. Esta guía
cubre el diagnóstico inicial. El estado de las comprobaciones actuales está en
[Desarrollo local](desarrollo-local.md#verificación-realizada).

## Hallazgos comprobados

| Problema | Estado |
| --- | --- |
| Docker copiaba `.env` y archivos locales al construir imágenes | Se agregaron `.dockerignore` por servicio y se reconstruyeron las imágenes locales. Las imágenes desplegadas no se han actualizado. |
| Cada arranque ejecutaba migraciones y `DatabaseSeeder`, ignorando fallos | Eliminado. Ahora esas operaciones se ejecutan explícitamente. |
| El backend esperaba una IA saludable para arrancar | Eliminada esa dependencia en Compose. Las funciones de IA siguen necesitando el microservicio. |
| `start.sh` creaba un entorno Python sin instalar dependencias | Corregido; instala requirements, valida configuración y prepara dependencias antes de lanzar servicios. |
| El script podía dejar servicios vivos al fallar | Se añade limpieza de grupos de procesos y propagación del error. |
| Groq no configurado | El clasificador ahora arranca; el chat queda no disponible y `/health` informa estado degradado. |
| PHP local no tiene `pdo_pgsql`, `iconv` ni `sodium` | Pendiente de instalar/habilitar. Composer confirmó los dos últimos requisitos. |
| Solo está disponible Python 3.14 | El entorno reproducible de IA del proyecto usa Python 3.12. |
| Docker CLI estaba instalado, pero el daemon no estaba disponible | Resuelto para esta sesión; los cinco servicios locales arrancan. |
| Faltaban las dependencias de los servicios | Instaladas en las imágenes Docker con PHP 8.4, Node 22 y Python 3.12. |

Los `.env` locales existen y tienen varias variables rellenadas. No se ha
comprobado que las credenciales sean válidas ni que hayan sido rotadas en sus
proveedores. No se han modificado esos archivos ni conectado a la base real.

## Configuración que hay que recuperar

| Servicio | Variables / archivos | Comprobación necesaria |
| --- | --- | --- |
| Laravel | `APP_ENV`, `APP_DEBUG`, `APP_URL`, `APP_KEY` | Separar desarrollo de producción; conservar la clave existente si se recupera una instalación. |
| PostgreSQL | `DB_CONNECTION=pgsql`, `DB_HOST`, `DB_PORT`, `DB_DATABASE`, `DB_USERNAME`, `DB_PASSWORD`, `DB_SSLMODE`; alternativamente `DB_URL` | Conexión a una base de desarrollo aislada primero. El entrypoint admite `NEON_URL` como alias si no existe `DB_URL`. |
| Correo SMTP | `MAIL_MAILER=smtp`, `MAIL_HOST`, `MAIL_PORT`, `MAIL_USERNAME`, `MAIL_PASSWORD`, `MAIL_FROM_ADDRESS`, `MAIL_FROM_NAME` | Prueba de entrega a una cuenta controlada; después probar 2FA y recuperación. |
| Resend | `MAIL_MAILER=resend`, `RESEND_API_KEY`, remitente autorizado | No hace falta rellenarlo si se usa SMTP. Revisar dominio/remitente en la cuenta recuperada. |
| Backend → IA | `IA_SERVICE_URL` | `http://127.0.0.1:5000` en local; Compose establece `http://ia:5000`. |
| Groq | `GROQ_API_KEY`, `GROQ_MODEL` en `IA/.env` | Configurar la clave nueva; probar disponibilidad antes del flujo conversacional. |
| Firebase | `FIREBASE_CREDENTIALS`, `FIREBASE_PROJECT_ID` y JSON de cuenta de servicio | Guardar el JSON fuera de la imagen e inyectarlo como archivo en ejecución. |
| Datos de prueba | `LocalDevelopmentSeeder` | Solo para el entorno local. La demo pública se preparará por separado. |
| Web | `frontend/proxy.conf.json`, `frontend/vercel.json`, `frontend/nginx.conf` | Angular usa `/api`; cada despliegue debe dirigirlo al backend correcto. |
| Móvil | `mobile/lib/services/api_service.dart`, configuración Firebase Android | Revisar URL y archivos del proyecto móvil antes de compilar. |

`APP_KEY` merece un tratamiento separado: cambiarla impide descifrar valores
protegidos con la anterior. Una clave nueva no recupera esos datos. Si la clave
anterior sigue disponible y procede conservarla, Laravel admite
`APP_PREVIOUS_KEYS`. Véase la [documentación de cifrado de Laravel](https://laravel.com/docs/12.x/encryption).

Las exclusiones de construcción se aplican por contexto, según la
[documentación de Docker](https://docs.docker.com/build/concepts/context/#dockerignore-files).
Rotar una credencial en un `.env` no la revoca en su proveedor ni la elimina de
imágenes construidas anteriormente.

## Arranque local actualizado

El propietario aclaró que los datos desplegados eran ficticios. Para continuar,
se eligió un entorno local limpio e independiente de Neon. Sigue
[Desarrollo local](desarrollo-local.md): `./local.sh up` y `./local.sh seed`.
Los comandos Docker del diagnóstico inicial han sido sustituidos por ese flujo.
El endpoint público `seed-demo` se retiró; las cuentas locales se crean por consola.

## Orden para reconstruir de forma verificable

1. Recuperar acceso a proveedores e inventario de variables. Confirmar qué
   datos quedan en PostgreSQL y crear un respaldo recuperable antes de migrarlos.
2. Conseguir un arranque reproducible en una base aislada. Verificar migraciones
   desde cero y sobre una copia de la base recuperada.
3. Cubrir login por rol, 2FA, recuperación de contraseña, permisos, citas y
   recetas con pruebas de comportamiento. Las pruebas iniciales cubren login y 2FA; falta completar los demás flujos.
4. Revisar las excepciones heredadas: correos compartidos para Resend, cuentas
   demo con contraseñas fijas, migraciones que modifican datos y respuestas de
   respaldo cuando falla IA.
5. Refactorizar por módulo conservando contratos HTTP. Mantener inicialmente
   `backend/`, `frontend/`, `mobile/` e `IA/`: en Laravel, validación en Requests,
   permisos en Policies, casos de uso en Services y presentación en Resources;
   en web/móvil, agrupar por funcionalidad y centralizar acceso a la API.
6. Añadir CI con compilación y pruebas, procedimiento de despliegue, copias de
   seguridad y un ensayo de restauración. La reorganización se completa por
   módulo, después de verificar su comportamiento.

## Verificación de esta corrección

```bash
python3 -m unittest discover -s tests -v
bash -n start.sh
sh -n backend/docker-entrypoint.sh
docker compose --env-file .env.local config --quiet
```

Las pruebas usan comandos simulados y no necesitan credenciales. Verifican que
el entrypoint no migra ni siembra automáticamente, falla sin clave, conserva
errores, respeta el puerto y la prioridad de las URL de conexión, y permite
comandos explícitos. También verifican que una IA mal configurada detiene el
script local antes de iniciar servicios. No sustituyen pruebas con contenedores
reales ni validan todavía el sistema completo.
