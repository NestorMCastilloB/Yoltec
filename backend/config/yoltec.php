<?php

// Configuración propia de Yoltec. Todo lo que el código de aplicación necesite
// del entorno se lee aquí y nunca con env() directo: bajo `config:cache`
// (estándar en despliegue) env() devuelve null fuera de config/.
return [

    // Microservicio de IA (FastAPI + Groq). Sin valor por defecto de producción:
    // si falta, es preferible fallar a apuntar en silencio al servidor real.
    'ia_service_url' => env('IA_SERVICE_URL'),

    // Resend (free tier) solo entrega al correo del owner de la cuenta.
    // Sin valor por defecto a propósito: el seeder debe fallar, no usar el correo de alguien.
    'resend_verified_email' => env('RESEND_VERIFIED_EMAIL'),

    // URL pública del frontend (Angular en Vercel). La usa el correo de
    // recuperación para construir el enlace; sin ella apunta a una dirección
    // de desarrollo y el enlace no le sirve a nadie.
    'frontend_url' => rtrim(env('FRONTEND_URL', 'http://localhost:4200'), '/'),

    // Modo demostración. El plan gratuito de Resend solo entrega al correo
    // verificado de la cuenta, así que un visitante nunca recibe el código de 2FA
    // y se queda atrapado en la pantalla del segundo factor. Con esto encendido,
    // las cuentas listadas reciben el código en la propia respuesta del login y no
    // se les envía correo.
    //
    // No desactiva el segundo factor: el código se sigue guardando cifrado, sigue
    // caducando a los 10 minutos y sigue siendo de un solo uso. Lo único que
    // cambia es por dónde llega, y solo para las cuentas nombradas abajo.
    'demo_mode' => filter_var(env('DEMO_MODE', false), FILTER_VALIDATE_BOOLEAN),

    // Usernames de las cuentas de demostración, separados por comas. Vacío por
    // defecto: sin lista, DEMO_MODE no afecta a nadie.
    'demo_usuarios' => array_values(array_filter(array_map(
        'trim',
        explode(',', (string) env('DEMO_USUARIOS', ''))
    ))),

    // Proxies en los que se confía para leer la IP real del cliente desde
    // X-Forwarded-For. De ese IP dependen el rate-limiting y el bloqueo por
    // intentos fallidos, así que decidir en quién confiar es una decisión de
    // seguridad, no de infraestructura.
    //
    //   '*'          → (por defecto) se confía en cualquier proxy. Cómodo, pero
    //                  permite falsificar la IP mandando la cabecera a mano.
    //   'cloudflare' → se confía SOLO en los rangos oficiales de Cloudflare más
    //                  las redes privadas del proxy interno de Render. Cloudflare
    //                  reescribe X-Forwarded-For y descarta la que envíe el
    //                  cliente, así que la IP deja de ser falsificable. Actívalo
    //                  a la vez que pones el DNS del backend detrás de Cloudflare.
    //   lista CIDR   → "1.2.3.0/24,10.0.0.0/8" para otros montajes.
    'trusted_proxies' => (function () {
        $valor = trim((string) env('TRUSTED_PROXIES', '*'));

        if ($valor === '' || $valor === '*') {
            return '*';
        }

        // Redes privadas: el proxy interno de Render llega desde aquí.
        $privadas = ['10.0.0.0/8', '172.16.0.0/12', '192.168.0.0/16'];

        // Rangos oficiales de Cloudflare · https://www.cloudflare.com/ips
        // Cambian rara vez; revísalos si Cloudflare anuncia nuevos.
        $cloudflare = [
            '173.245.48.0/20', '103.21.244.0/22', '103.22.200.0/22',
            '103.31.4.0/22', '141.101.64.0/18', '108.162.192.0/18',
            '190.93.240.0/20', '188.114.96.0/20', '197.234.240.0/22',
            '198.41.128.0/17', '162.158.0.0/15', '104.16.0.0/13',
            '104.24.0.0/14', '172.64.0.0/13', '131.0.72.0/22',
            '2400:cb00::/32', '2606:4700::/32', '2803:f800::/32',
            '2405:b500::/32', '2405:8100::/32', '2a06:98c0::/29',
            '2c0f:f248::/32',
        ];

        if ($valor === 'cloudflare') {
            return array_merge($cloudflare, $privadas);
        }

        return array_values(array_filter(array_map('trim', explode(',', $valor))));
    })(),

];
