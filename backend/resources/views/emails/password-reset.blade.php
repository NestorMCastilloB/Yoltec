<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <style>
    body { font-family: Arial, sans-serif; background: #f4f4f4; margin: 0; padding: 20px; }
    .container { max-width: 480px; margin: 0 auto; background: #fff; border-radius: 8px; padding: 32px; }
    h2 { color: #1B5E20; }
    .btn { display: inline-block; background: #4CAF50; color: #fff; text-decoration: none;
           padding: 14px 32px; border-radius: 8px; font-size: 16px; margin: 24px 0; }
    .url { word-break: break-all; font-size: 12px; color: #999; }
    .footer { color: #999; font-size: 12px; margin-top: 24px; }
  </style>
</head>
<body>
  <div class="container">
    <h2>Recuperación de contraseña</h2>
    <p>Hola <strong>{{ $userName }}</strong>,</p>
    <p>Recibimos una solicitud para restablecer tu contraseña. Haz clic en el botón para continuar:</p>
    <a href="{{ $resetUrl }}" class="btn">Restablecer contraseña</a>
    <p>Este enlace expira en <strong>30 minutos</strong>.</p>
    <p class="url">Si el botón no funciona, copia este enlace en tu navegador:<br>{{ $resetUrl }}</p>
    <p>Si no solicitaste este cambio, ignora este correo.</p>
    <div class="footer">Consultorio Médico Universitario — Yoltec</div>
  </div>
</body>
</html>
