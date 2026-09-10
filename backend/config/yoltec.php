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

];
