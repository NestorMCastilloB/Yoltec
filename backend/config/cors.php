<?php

return [
    'paths' => ['api/*', 'sanctum/csrf-cookie'],
    'allowed_methods' => ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    'allowed_origins' => [
        'http://localhost:4200',
        'http://127.0.0.1:4200',
        'https://yoltec.vercel.app',
        'https://frontend-nu-weld-77.vercel.app',
    ],
    'allowed_origins_patterns' => [],
    'allowed_headers' => ['Content-Type', 'Authorization', 'Accept', 'X-Requested-With'],
    'exposed_headers' => [],
    'max_age' => 3600,

    // La autenticación es por Bearer token (Sanctum sin modo stateful): el
    // navegador no manda cookies ni el frontend usa withCredentials. Habilitar
    // credenciales en CORS era superficie innecesaria (M-5 de la auditoría).
    'supports_credentials' => false,
];
