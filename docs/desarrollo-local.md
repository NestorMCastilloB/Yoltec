# Desarrollo local de Yoltec

Este entorno permite reparar y probar Yoltec sin acceder a Neon, Gmail, Resend
ni Firebase. El propietario confirmó que los datos de los despliegues anteriores
son ficticios. No es necesario recuperarlos para desarrollar las versiones normal
y demo; la revocación de las credenciales antiguas sigue pendiente.

## Requisitos

- Docker Engine iniciado y accesible para tu usuario, con Docker Compose v2.
- Bash y OpenSSL (para generar claves locales).
- Conexión a Internet para descargar imágenes y dependencias la primera vez.

Docker proporciona PHP 8.4, Node 22, Python 3.12 y PostgreSQL 16. No necesitas
instalar estos runtimes en tu equipo para seguir este camino. En Linux con
systemd, puedes iniciar Docker con `sudo systemctl start docker`.

## Arranque

Desde la raíz del repositorio:

```bash
./local.sh up
./local.sh seed
```

`up` genera `.env.local` con permisos restringidos y claves nuevas si falta,
construye los servicios y aplica las migraciones en `yoltec_local`. Los `.env`
anteriores del backend y de IA no se leen ni se reemplazan. El entrypoint de
producción sigue sin ejecutar migraciones ni seeders automáticamente.

`seed` crea únicamente tres cuentas ficticias. Es idempotente: no reinicia
contraseñas ni sobrescribe datos existentes. Este seeder rechaza entornos que
no sean `local`; no está pensado para la demo pública.

| Servicio | Dirección |
| --- | --- |
| Aplicación web | http://localhost:4200 |
| Backend | http://localhost:8000/api/health |
| Buzón de prueba Mailpit | http://localhost:8025 |
| IA, estado de funciones | http://localhost:5000/health |
| IA, proceso activo | http://localhost:5000/live |

Los puertos publicados solo escuchan en el equipo local. PostgreSQL no publica
un puerto al equipo ni a la red. Mailpit recibe el correo de prueba y no está
configurado para reenviarlo a destinatarios reales.

## Cuentas ficticias

| Rol | Identificador | Contraseña / NIP |
| --- | --- | --- |
| Alumno | `99000001` | `123456` |
| Doctor | `doctor-local` | `SoloLocal123!` |
| Administrador | `admin-local` | `SoloLocal123!` |

Para alumno y doctor, abre `/login` y selecciona el rol correspondiente. Para
administrador, abre `/acceso-gestion`. El 2FA también se exige en local:
abre Mailpit, busca el mensaje dirigido a
`doctor@yoltec.test` o `admin@yoltec.test` y copia el código a Yoltec.

Estas credenciales son públicas y exclusivas del desarrollo local. No despliegues
este Compose como versión normal o demo pública.

## IA sin Groq

El servicio no depende de Groq para dar un diagnóstico. Quien clasifica es
siempre `model.pkl`; el LLM solo traduce lenguaje natural a la lista de síntomas
que entiende el clasificador. Cuando no hay clave —o cuando Groq falla, agota su
cuota o tarda demasiado— `/chat` pasa a **modo guiado**: hace un guion fijo de
preguntas (`extractor.py`) y extrae los síntomas por reglas, con negación
(«no tengo fiebre») y sinónimos coloquiales. La respuesta estática ante
emergencias se conserva y tiene prioridad sobre ambos modos.

Por eso `/health` devuelve 200 y `status: ok` mientras el clasificador esté
cargado, e informa del modo activo:

| Campo | Sin Groq | Con Groq |
| --- | --- | --- |
| `status` | `ok` | `ok` |
| `llm_available` | `false` | `true` |
| `modo_chat` | `guiado` | `llm` |

`status: degraded` (HTTP 503) queda reservado para lo que sí impide diagnosticar:
que `model.pkl` no cargue. `/live` sigue respondiendo 200 sin comprobar terceros.

Para habilitar la conversación libre, escribe tu clave en `LOCAL_GROQ_API_KEY`
dentro de `.env.local` y ejecuta `./local.sh up`. No compartas ese archivo. El
healthcheck consulta la lista de modelos y no garantiza que una conversación
funcione: también hay que probar `/chat` con el modelo configurado.

## Comprobaciones

```bash
./local.sh test
python3 -m unittest discover -s tests -v
```

Las pruebas Laravel utilizan una base separada, `yoltec_test`, que puede vaciarse
durante su ejecución. Nunca se deben apuntar las pruebas a una base que quieras
conservar. Incluyen cuentas locales, login de alumno, acceso por rol, 2FA de un
solo uso y ausencia de la ruta pública de siembra. Las pruebas de IA cargan el
modelo versionado y simulan Groq, sin consumir la API; el extractor por reglas
se prueba aparte, sin dependencias.

## Detener y volver a iniciar

```bash
./local.sh status
./local.sh logs backend
./local.sh down
./local.sh up
```

`down` conserva el volumen PostgreSQL. Conserva también `.env.local`: cambiar
la contraseña del archivo no cambia la contraseña de un volumen ya inicializado.
No se incluye ningún comando de borrado de datos en el script.

## Versiones normal y demo

Se construirán desde el mismo código, con despliegues, bases y credenciales
independientes. La versión normal partirá de una base limpia y un acceso inicial
controlado. La demo tendrá datos ficticios y un mecanismo de restauración por
consola o tarea administrativa, nunca mediante una ruta pública de siembra.

Pendiente: revisar el resto de hallazgos de la auditoría, completar las pruebas
de citas y permisos, configurar proveedores, preparar el móvil y desplegar ambas
versiones. Este arranque local no certifica todavía que todo el producto funcione.

## Verificación realizada

- Construcción de los tres servicios y aplicación de las 32 migraciones sobre
  PostgreSQL local desde cero.
- Diez pruebas de scripts, ocho de Laravel (incluidas dos de andamiaje) y cuatro
  de IA aprobadas. Las pruebas de Laravel se detienen si la base configurada no
  es `yoltec_test`.
- Login en Chromium de alumno, doctor y administrador; llegada del correo a
  Mailpit y verificación 2FA para los dos roles de gestión; carga de sus paneles.
- Las tres cuentas locales se conservan después de ejecutar las pruebas.
- Arranque del cliente Groq comprobado con una clave ficticia y sin red. No se
  ha probado una conversación con un proveedor real.

La instalación detectó avisos de dependencias: `npm audit --omit=dev` reportó
seis paquetes Angular con severidad alta. Falta actualizar y revisar su alcance;
este resultado no demuestra por sí solo que todas las vulnerabilidades sean
explotables en Yoltec. La actualización de dependencias forma parte del siguiente
bloque de seguridad antes de publicar las versiones normal y demo.
