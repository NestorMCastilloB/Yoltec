# Monografía Técnica — Proyecto 2: Implementación de Mecanismos de Autenticación Segura y Control de Acceso en Aplicaciones Web

**Unidad 3: Seguridad en el Transporte de Datos**
**Materia:** Seguridad Informática — 8.° Semestre, Ingeniería en Sistemas Computacionales
**Proyecto aplicado sobre:** Sistema Yoltec — Consultorio Médico Universitario con IA
**Fecha:** Mayo 2026

---

## 1. Introducción

La seguridad en el transporte de datos es un pilar fundamental en cualquier sistema de información moderno. En el contexto de aplicaciones web que manejan datos sensibles — como información médica de estudiantes universitarios — resulta imperativo que la autenticación, la autorización y la protección de sesiones estén diseñadas como requisitos estructurales del sistema, no como complementos opcionales.

El presente documento describe el análisis, diseño e implementación de mecanismos de autenticación segura y control de acceso aplicados al sistema **Yoltec**, un sistema de consultorio médico universitario compuesto por un backend REST (Laravel 12), un frontend web (Angular 20), una aplicación móvil (Flutter) y un microservicio de inteligencia artificial (Python/FastAPI).

El objetivo es garantizar que:

- **El usuario es quien dice ser** (autenticación).
- **Solo accede a lo que le corresponde** (autorización).
- **Las sesiones y tokens están protegidos durante el tránsito** (seguridad en transporte).

Este proyecto aborda la intersección entre seguridad en tránsito, gestión de identidades y protección de sesiones, siguiendo las directrices de OWASP Top 10 (2021) y buenas prácticas de la industria.

---

## 2. Marco Teórico

### 2.1 Autenticación vs. Autorización

| Concepto | Definición | Ejemplo en Yoltec |
|----------|------------|-------------------|
| **Autenticación** | Verificar la identidad del usuario | Login con número de control + NIP (alumno) o username + password + 2FA (doctor) |
| **Autorización** | Verificar los permisos del usuario | Un alumno solo ve sus propias citas; un doctor ve todas |

### 2.2 Hashing de Contraseñas — bcrypt y Argon2

El almacenamiento de contraseñas en texto plano es una de las vulnerabilidades más críticas (OWASP A02:2021 — Cryptographic Failures). Los algoritmos de hashing unidireccional garantizan que, aun si la base de datos es comprometida, las contraseñas no pueden ser recuperadas.

**bcrypt** utiliza un factor de costo configurable (rounds) que determina cuántas iteraciones se ejecutan. Con 12 rounds (2^12 = 4,096 iteraciones), cada hash toma ~250ms, haciendo inviable un ataque de fuerza bruta a escala.

```
Contraseña → bcrypt(12 rounds) → $2y$12$... (60 caracteres, irreversible)
```

Laravel utiliza el cast `hashed` en el modelo, que aplica automáticamente el algoritmo configurado (bcrypt con 12 rounds por defecto).

### 2.3 Tokens de Acceso — Bearer Tokens con Laravel Sanctum

A diferencia de las sesiones basadas en cookies tradicionales, los tokens Bearer viajan en el header `Authorization` de cada petición HTTP:

```
Authorization: Bearer 1|a4b8c3d7e9f0...
```

**Ventajas de este enfoque:**
- Stateless: el servidor no almacena estado de sesión en memoria.
- Compatible con múltiples clientes (web, móvil, API).
- Cada token tiene expiración configurable (24 horas en Yoltec).
- Revocable individualmente sin afectar otras sesiones.

### 2.4 Autenticación de Dos Factores (2FA)

La autenticación multifactor combina algo que el usuario **sabe** (contraseña) con algo que **posee** (acceso al email). Esto mitiga el riesgo de credenciales comprometidas.

**Flujo implementado:**
1. Usuario envía credenciales válidas.
2. Servidor genera código de 6 dígitos con `random_int()` (criptográficamente seguro).
3. Código se almacena hasheado con bcrypt en la base de datos.
4. Código se envía por email al usuario.
5. Usuario ingresa el código; servidor verifica con `Hash::check()`.
6. Si es válido, se genera token de acceso y token de dispositivo de confianza (30 días).

### 2.5 Control de Acceso Basado en Roles (RBAC)

RBAC asigna permisos según el rol del usuario, no individualmente. Yoltec define tres roles:

| Rol | Acceso |
|-----|--------|
| **Alumno** | Sus propias citas, perfil, pre-evaluaciones IA, recetas |
| **Doctor** | Todas las citas, bitácora, estadísticas, validar pre-evaluaciones, crear recetas |
| **Admin** | CRUD de alumnos y doctores, gestión de calendario |

### 2.6 Headers de Seguridad HTTP

Los headers de seguridad instruyen al navegador sobre cómo manejar el contenido de la respuesta:

| Header | Función | Ataque que mitiga |
|--------|---------|-------------------|
| `X-Frame-Options: DENY` | Prohíbe cargar la página en iframes | Clickjacking |
| `X-Content-Type-Options: nosniff` | Impide que el navegador infiera tipos MIME | MIME sniffing |
| `X-XSS-Protection: 1; mode=block` | Activa el filtro XSS del navegador | XSS reflejado |
| `Strict-Transport-Security` | Fuerza HTTPS durante 1 año | Downgrade a HTTP, MITM |
| `Referrer-Policy` | Controla qué info de referrer se envía | Fuga de información |
| `Permissions-Policy` | Restringe APIs del navegador (cámara, micrófono, geolocalización) | Acceso no autorizado a hardware |

### 2.7 CSRF (Cross-Site Request Forgery)

CSRF explota la confianza que un sitio tiene en el navegador del usuario. Si un usuario autenticado visita un sitio malicioso, este puede enviar requests al servidor legítimo usando las cookies del usuario.

**Mitigación:**
- Tokens CSRF en formularios web (Laravel los genera automáticamente).
- APIs REST protegidas por tokens Bearer (no cookies), por lo que no son vulnerables a CSRF.

### 2.8 Rate Limiting

El rate limiting restringe el número de peticiones que un cliente puede hacer en un periodo de tiempo, mitigando:
- Ataques de fuerza bruta contra login.
- Abuso de endpoints de reset de contraseña.
- DoS (Denial of Service) a nivel de aplicación.

### 2.9 OWASP Top 10 (2021)

Las 10 vulnerabilidades más críticas según OWASP, relevantes para este proyecto:

| # | Categoría | Relevancia en Yoltec |
|---|-----------|---------------------|
| A01 | Broken Access Control | RBAC, verificación de propiedad de recursos |
| A02 | Cryptographic Failures | Hashing bcrypt, HTTPS, 2FA hasheado |
| A03 | Injection | ORM Eloquent (parameterizado), validación de input |
| A04 | Insecure Design | Arquitectura segura desde el diseño |
| A05 | Security Misconfiguration | Headers de seguridad, CSRF, cookies seguras |
| A07 | Identification & Auth Failures | 2FA, rate limiting, contraseñas fuertes |
| A09 | Security Logging & Monitoring | Logs de intentos fallidos sin datos sensibles |

---

## 3. Metodología

### 3.1 Cronograma

| Semana | Actividad | Entregable |
|--------|-----------|-----------|
| 1 | Diagnóstico de seguridad y análisis de riesgos | Reporte de auditoría con hallazgos clasificados por severidad |
| 2 | Diseño de correcciones y arquitectura de seguridad | Plan de implementación con prioridades |
| 3 | Implementación de correcciones | Código committeado y verificado |
| 4 | Documentación y monografía | Este documento + presentación |

### 3.2 Herramientas Utilizadas

| Herramienta | Uso |
|-------------|-----|
| Laravel 12 (Sanctum, middleware) | Backend y autenticación |
| PHP 8.x (Hash, random_int) | Criptografía |
| Análisis estático de código | Auditoría de seguridad |
| OWASP Top 10 (2021) | Marco de referencia de vulnerabilidades |

### 3.3 Proceso de Auditoría

Se realizó un análisis exhaustivo del backend en 3 áreas paralelas:

1. **Auth y tokens**: Configuración de Sanctum, sesiones, CORS, rate limiting.
2. **Headers y middleware**: Protecciones HTTP, rutas expuestas, validación de input, SQL injection, XSS.
3. **Passwords y criptografía**: Hashing, 2FA, secrets, modelos expuestos, logging.

Cada hallazgo se clasificó por severidad (Crítica, Alta, Media, Baja) y se mapeó a la categoría OWASP correspondiente.

---

## 4. Resultados

### 4.1 Diagnóstico Inicial — Estado Antes de las Correcciones

#### Puntuación por Categoría (Pre-corrección)

| Categoría | Puntuación | Estado |
|-----------|-----------|--------|
| Autenticación (login, 2FA, tokens) | 8/10 | Bien |
| Autorización (RBAC) | 9/10 | Excelente |
| Validación de Input | 9/10 | Excelente |
| Criptografía (hashing) | 8/10 | Bien |
| Gestión de Sesiones | 7/10 | Aceptable |
| Headers de Seguridad | 2/10 | Crítico |
| Protección CSRF | 0/10 | Deshabilitado |
| Rate Limiting | 7/10 | Parcial |
| Logging | 5/10 | Datos sensibles expuestos |
| Protección SQL Injection | 10/10 | Excelente |
| **Promedio General** | **6.5/10** | |

#### Hallazgos Identificados

| # | Hallazgo | Severidad | OWASP | Riesgo |
|---|----------|-----------|-------|--------|
| 1 | CSRF deshabilitado globalmente con `'*'` | Crítica | A05 | Cualquier sitio externo puede ejecutar acciones en nombre del usuario |
| 2 | Sin headers de seguridad HTTP | Crítica | A05 | Vulnerable a clickjacking, MIME sniffing, downgrade HTTP |
| 3 | Código 2FA almacenado sin hash en BD | Alta | A02 | Si la BD es comprometida, los códigos activos quedan expuestos |
| 4 | Código 2FA y email logueados en texto plano | Alta | A09 | Acceso a logs expone códigos intentados y emails |
| 5 | Password mínimo de 6 caracteres en reset | Alta | A07 | Contraseñas débiles fáciles de adivinar |
| 6 | Sin rate limiting en `/reset-password` | Media | A07 | Posible fuerza bruta de tokens de reset |
| 7 | Enumeración de usuarios en login | Media | A01 | Verificado: ya está protegido con mensaje genérico |
| 8 | `SESSION_SECURE_COOKIE` no configurado | Media | A02 | Cookies pueden viajar por HTTP en producción |

### 4.2 Correcciones Implementadas

#### Corrección 1: CSRF Habilitado

**Archivo:** `backend/bootstrap/app.php`

```php
// ANTES (inseguro):
$middleware->validateCsrfTokens(except: ['*']);

// DESPUÉS (seguro):
$middleware->validateCsrfTokens(except: ['api/*']);
```

**Justificación:** Las rutas API (`api/*`) usan tokens Bearer en el header `Authorization`, no cookies, por lo que no son vulnerables a CSRF. Las rutas web sí necesitan protección CSRF. La excepción anterior (`*`) deshabilitaba CSRF para todo el sistema.

#### Corrección 2: Middleware de Headers de Seguridad

**Archivo creado:** `backend/app/Http/Middleware/SecurityHeaders.php`

```php
class SecurityHeaders
{
    public function handle(Request $request, Closure $next): Response
    {
        $response = $next($request);

        $response->headers->set('X-Frame-Options', 'DENY');
        $response->headers->set('X-Content-Type-Options', 'nosniff');
        $response->headers->set('X-XSS-Protection', '1; mode=block');
        $response->headers->set('Referrer-Policy', 'strict-origin-when-cross-origin');
        $response->headers->set('Permissions-Policy', 'geolocation=(), microphone=(), camera=()');

        if (config('app.env') === 'production') {
            $response->headers->set('Strict-Transport-Security',
                'max-age=31536000; includeSubDomains; preload');
        }

        return $response;
    }
}
```

**Registro:** Se agrega como middleware global con `$middleware->append()` para que aplique a todas las respuestas del sistema (web y API).

**HSTS condicionado:** Solo se agrega en producción para no bloquear el desarrollo local con HTTP.

#### Corrección 3: Código 2FA Hasheado con bcrypt

**Archivo:** `backend/app/Http/Controllers/AuthController.php`

```php
// ANTES (inseguro — código en texto plano):
TwoFactorCode::create([
    'code' => $code,  // "482937" almacenado directamente
    ...
]);

// Verificación directa:
TwoFactorCode::where('code', $request->code)->first();

// DESPUÉS (seguro — código hasheado):
TwoFactorCode::create([
    'code' => Hash::make($code),  // "$2y$12$..." almacenado
    ...
]);

// Verificación con Hash::check:
$pendingCodes = TwoFactorCode::where('user_id', $user->id)
    ->where('used', false)
    ->where('expires_at', '>', Carbon::now())
    ->get();

foreach ($pendingCodes as $pending) {
    if (Hash::check($request->code, $pending->code)) {
        $twoFactorCode = $pending;
        break;
    }
}
```

**Justificación:** El código 2FA es una credencial temporal. Si la base de datos es comprometida, los códigos activos (no expirados) quedan expuestos en texto plano. Al hashearlos, se garantiza que incluso con acceso a la BD, un atacante no puede usar los códigos.

**Trade-off:** La verificación requiere iterar sobre los códigos pendientes del usuario (máximo 1-3), lo cual tiene un costo computacional despreciable.

#### Corrección 4: Logs sin Datos Sensibles

**Archivo:** `backend/app/Http/Controllers/AuthController.php`

```php
// ANTES (inseguro):
\Log::warning('2FA fallido', [
    'user_id'        => $user->id,
    'email'          => $user->email,        // PII expuesto
    'code_attempted' => $code,               // Código 2FA en logs
    'ip'             => request()->ip(),
]);

\Log::info('Email 2FA enviado a: ' . $user->email);  // PII expuesto

// DESPUÉS (seguro):
\Log::warning('2FA fallido', [
    'user_id' => $user->id,
    'ip'      => request()->ip(),
]);

\Log::info('Email 2FA enviado', ['user_id' => $user->id]);
```

**Justificación:** Los logs son frecuentemente un vector de ataque subestimado. Si un atacante accede a los archivos de log (OWASP A09), no debe encontrar emails ni códigos de verificación. Se conserva el `user_id` y la IP para auditoría forense.

#### Corrección 5: Password Mínimo de 8 Caracteres

**Archivo:** `backend/app/Http/Controllers/PasswordResetController.php`

```php
// ANTES:
'password' => 'required|string|min:6|confirmed',

// DESPUÉS:
'password' => 'required|string|min:8|confirmed',
```

**Justificación:** OWASP recomienda un mínimo de 8 caracteres. Una contraseña de 6 caracteres tiene ~2^30 combinaciones posibles, mientras que 8 caracteres tiene ~2^40 — un factor de 1,000x más difícil de adivinar por fuerza bruta. El otro endpoint de cambio de contraseña (`PerfilController`) ya usaba `min:8`.

#### Corrección 6: Rate Limiting en `/reset-password`

**Archivo:** `backend/routes/api.php`

```php
// ANTES (sin protección):
Route::post('/reset-password', [PasswordResetController::class, 'resetPassword']);

// DESPUÉS (protegido):
Route::middleware('throttle:5,10')->post('/reset-password', ...);
```

**Justificación:** Aunque los tokens de reset son de 64 caracteres aleatorios (62^64 combinaciones), agregar rate limiting es defensa en profundidad. Limita a 5 intentos cada 10 minutos, consistente con `/forgot-password`.

#### Corrección 7: Cookies Seguras en Producción

**Archivo:** `backend/config/session.php`

```php
// ANTES:
'secure' => env('SESSION_SECURE_COOKIE'),  // null por defecto

// DESPUÉS:
'secure' => env('SESSION_SECURE_COOKIE', env('APP_ENV') === 'production'),
```

**Justificación:** En producción, las cookies de sesión deben tener el flag `Secure`, que instruye al navegador a enviarlas solo por HTTPS. Esto previene la interceptación de cookies en conexiones HTTP. En desarrollo local (`APP_ENV=local`) se permite HTTP.

### 4.3 Puntuación Post-corrección

| Categoría | Antes | Después | Mejora |
|-----------|-------|---------|--------|
| Autenticación | 8/10 | 9/10 | 2FA hasheado |
| Autorización | 9/10 | 9/10 | Ya estaba bien |
| Validación de Input | 9/10 | 9/10 | Ya estaba bien |
| Criptografía | 8/10 | 9/10 | 2FA hasheado, cookies seguras |
| Gestión de Sesiones | 7/10 | 9/10 | Cookies seguras en producción |
| Headers de Seguridad | 2/10 | 9/10 | Middleware SecurityHeaders |
| Protección CSRF | 0/10 | 9/10 | CSRF habilitado |
| Rate Limiting | 7/10 | 9/10 | `/reset-password` protegido |
| Logging | 5/10 | 8/10 | Sin datos sensibles |
| Protección SQL Injection | 10/10 | 10/10 | Ya estaba bien |
| **Promedio General** | **6.5/10** | **9.0/10** | **+2.5 puntos** |

### 4.4 Elementos de Seguridad que Ya Estaban Bien Implementados

El sistema ya contaba con controles robustos antes de la auditoría:

1. **Hashing bcrypt con 12 rounds** en todas las contraseñas y NIPs.
2. **Tokens Sanctum con expiración** de 24 horas.
3. **RBAC con middleware** `EnsureIsAdmin` y verificaciones por rol en controladores.
4. **Rate limiting en login** — 5 intentos/minuto + bloqueo 15 minutos.
5. **2FA para doctores** con dispositivos de confianza (30 días).
6. **Validación exhaustiva** de input con reglas de Laravel (`required`, `email`, `exists`, `in`, `max`).
7. **Eloquent ORM** que parametriza automáticamente todas las queries SQL.
8. **Campos sensibles ocultos** (`$hidden`) en el modelo User (password, NIP, tokens).
9. **Transacciones ACID con `lockForUpdate()`** para prevenir doble-booking de citas.
10. **Revocación de todos los tokens** al resetear contraseña.
11. **CORS con whitelist** de orígenes específicos (no `*`).
12. **Respuesta genérica en `/forgot-password`** — no revela si el email existe.

---

## 5. Discusión

### 5.1 Decisiones de Diseño

**¿Por qué tokens Bearer y no sesiones con cookies?**

Yoltec tiene tres clientes: web (Angular), móvil (Flutter) y potencialmente otros consumidores de la API. Los tokens Bearer son agnósticos al cliente — funcionan igual con `fetch()` en JavaScript, `http` en Dart, o `curl` en terminal. Las sesiones con cookies están atadas al navegador y complican la autenticación en apps móviles.

**¿Por qué hashear el código 2FA si expira en 10 minutos?**

Defensa en profundidad. Si la base de datos es comprometida (por ejemplo, por SQL injection en otro componente o backup mal protegido), un atacante con acceso a la tabla `two_factor_codes` podría usar un código activo para completar el 2FA de un doctor. Hashear el código elimina este vector con un costo computacional mínimo.

**¿Por qué HSTS solo en producción?**

HSTS indica al navegador que nunca use HTTP con ese dominio durante un año. Si se activa en desarrollo local, el navegador rechazaría `http://localhost:8000`. La condición `config('app.env') === 'production'` garantiza que HSTS solo se active donde HTTPS está configurado (Render/Vercel).

### 5.2 Limitaciones

1. **Sin Content-Security-Policy (CSP):** Este header es complejo de configurar correctamente con frameworks SPA (Angular) que usan inline scripts. Se recomienda implementarlo en una fase posterior.
2. **Sin WAF (Web Application Firewall):** Render y Vercel ofrecen protección DDoS básica, pero un WAF dedicado (como Cloudflare) agregaría una capa adicional.
3. **Sin auditoría de acceso a datos médicos:** El modelo `AuditLog` existe pero no está integrado en los controladores de perfil médico e historial.

### 5.3 Relación con OWASP Top 10

| OWASP | Estado Inicial | Estado Final | Corrección Aplicada |
|-------|---------------|-------------|-------------------|
| A01: Broken Access Control | Parcial | Resuelto | CSRF habilitado |
| A02: Cryptographic Failures | Parcial | Resuelto | 2FA hasheado, cookies seguras |
| A03: Injection | Protegido | Protegido | Ya usaba Eloquent ORM |
| A04: Insecure Design | Aceptable | Aceptable | Arquitectura ya era correcta |
| A05: Security Misconfiguration | Crítico | Resuelto | Headers de seguridad, CSRF |
| A07: Auth Failures | Parcial | Resuelto | Password min:8, rate limiting |
| A09: Logging Failures | Crítico | Resuelto | Sin datos sensibles en logs |

---

## 6. Conclusiones

### 6.1 Resultados Alcanzados

Se realizó un análisis de seguridad integral del backend del sistema Yoltec, identificando 8 hallazgos clasificados por severidad (2 críticos, 3 altos, 3 medios). Se implementaron 7 correcciones que elevaron la puntuación de seguridad de **6.5/10 a 9.0/10**.

Las correcciones se enfocaron en tres áreas clave del Proyecto 2:

1. **Autenticación segura**: Hasheo de códigos 2FA, contraseñas de mínimo 8 caracteres, rate limiting en reset.
2. **Control de acceso**: CSRF habilitado para rutas web, headers de seguridad contra clickjacking y MIME sniffing.
3. **Gestión segura de sesiones**: Cookies seguras en producción, logs sin datos sensibles, HSTS.

### 6.2 Lecciones Aprendidas

1. **La seguridad no es un complemento, es un requisito estructural.** Un sistema puede tener excelente funcionalidad y aun así ser vulnerable si la seguridad no se diseña desde el inicio.
2. **Defensa en profundidad.** Ninguna medida de seguridad es infalible por sí sola. La combinación de HTTPS + tokens Bearer + 2FA hasheado + rate limiting + headers de seguridad crea múltiples capas que un atacante debe superar.
3. **Los logs son un vector de ataque.** Registrar emails y códigos 2FA en archivos de log crea un punto de fuga de información que se suele ignorar.
4. **La auditoría periódica es esencial.** Vulnerabilidades como el CSRF deshabilitado (`'*'`) probablemente se introdujeron durante el desarrollo para simplificar pruebas y nunca se revertieron.

### 6.3 Trabajo Futuro

- Implementar Content-Security-Policy (CSP) compatible con Angular.
- Integrar el modelo `AuditLog` para rastrear accesos a datos médicos.
- Agregar notificaciones de login desde ubicaciones desconocidas.
- Evaluar la implementación de OAuth2 para integración con sistemas institucionales.
- Configurar un WAF (Cloudflare o similar) en producción.

---

## 7. Referencias

1. OWASP Foundation. (2021). *OWASP Top Ten*. https://owasp.org/www-project-top-ten/
2. OWASP Foundation. (2021). *Authentication Cheat Sheet*. https://cheatsheetseries.owasp.org/cheatsheets/Authentication_Cheat_Sheet.html
3. OWASP Foundation. (2021). *Session Management Cheat Sheet*. https://cheatsheetseries.owasp.org/cheatsheets/Session_Management_Cheat_Sheet.html
4. Laravel Documentation. (2025). *Sanctum — API Token Authentication*. https://laravel.com/docs/12.x/sanctum
5. Laravel Documentation. (2025). *CSRF Protection*. https://laravel.com/docs/12.x/csrf
6. Mozilla Developer Network. (2024). *HTTP Headers — Security*. https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers
7. NIST. (2024). *Digital Identity Guidelines — SP 800-63B*. https://pages.nist.gov/800-63-4/sp800-63b.html
8. Provos, N., & Mazières, D. (1999). *A Future-Adaptable Password Scheme*. USENIX Annual Technical Conference. (Artículo original de bcrypt)

---

## Anexo A: Diagrama de Flujo de Autenticación

```
┌──────────┐     ┌──────────────┐     ┌──────────────┐
│  Cliente  │────>│  POST /login │────>│  Validar     │
│ (Web/App) │     │              │     │  credenciales│
└──────────┘     └──────────────┘     └──────┬───────┘
                                              │
                                    ┌─────────┴─────────┐
                                    │                     │
                              ┌─────▼─────┐        ┌─────▼──────┐
                              │  Alumno/   │        │   Doctor   │
                              │  Admin     │        │ (producción)│
                              └─────┬─────┘        └─────┬──────┘
                                    │                     │
                              ┌─────▼─────┐        ┌─────▼──────┐
                              │  Token     │        │  Verificar │
                              │  Sanctum   │        │  dispositivo│
                              │  (24h)     │        │  confianza │
                              └───────────┘        └─────┬──────┘
                                                          │
                                                ┌─────────┴─────────┐
                                                │                     │
                                          ┌─────▼─────┐        ┌─────▼──────┐
                                          │ Confiable  │        │ No confiable│
                                          │ → Token    │        │ → Enviar   │
                                          │   directo  │        │   2FA email│
                                          └───────────┘        └─────┬──────┘
                                                                      │
                                                                ┌─────▼──────┐
                                                                │  Verificar │
                                                                │  código    │
                                                                │ Hash::check│
                                                                └─────┬──────┘
                                                                      │
                                                                ┌─────▼──────┐
                                                                │  Token +   │
                                                                │  device    │
                                                                │  token     │
                                                                └────────────┘
```

## Anexo B: Headers de Seguridad — Antes y Después

### Antes (sin middleware SecurityHeaders)

```http
HTTP/1.1 200 OK
Content-Type: application/json
```

### Después (con middleware SecurityHeaders)

```http
HTTP/1.1 200 OK
Content-Type: application/json
X-Frame-Options: DENY
X-Content-Type-Options: nosniff
X-XSS-Protection: 1; mode=block
Referrer-Policy: strict-origin-when-cross-origin
Permissions-Policy: geolocation=(), microphone=(), camera=()
Strict-Transport-Security: max-age=31536000; includeSubDomains; preload
```

## Anexo C: Archivos Modificados

| Archivo | Cambio |
|---------|--------|
| `bootstrap/app.php` | CSRF `api/*`, registro SecurityHeaders |
| `app/Http/Middleware/SecurityHeaders.php` | **Nuevo** — headers de seguridad |
| `app/Http/Controllers/AuthController.php` | 2FA hasheado, logs limpios |
| `app/Http/Controllers/PasswordResetController.php` | `min:8` en password |
| `routes/api.php` | `throttle:5,10` en `/reset-password` |
| `config/session.php` | `SESSION_SECURE_COOKIE` automático |

## Anexo D: Checklist de Verificación OWASP

- [x] A01: RBAC implementado con middleware y verificaciones por rol
- [x] A02: Contraseñas y códigos 2FA hasheados con bcrypt
- [x] A03: ORM Eloquent parametriza todas las queries
- [x] A04: Arquitectura diseñada con seguridad desde el inicio
- [x] A05: Headers de seguridad, CSRF, cookies seguras configurados
- [x] A07: Rate limiting en login, forgot-password, reset-password; min:8
- [x] A09: Logs sin datos sensibles (emails, códigos, contraseñas)
