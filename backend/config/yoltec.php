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

];
