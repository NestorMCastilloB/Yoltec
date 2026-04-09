<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <style>
    body { font-family: Arial, sans-serif; background: #f4f4f4; margin: 0; padding: 20px; }
    .container { max-width: 480px; margin: 0 auto; background: #fff; border-radius: 8px; padding: 32px; }
    h2 { color: #1a73e8; }
    .code { font-size: 36px; font-weight: bold; letter-spacing: 8px; color: #333; text-align: center;
            background: #f0f4ff; padding: 16px; border-radius: 8px; margin: 24px 0; }
    .footer { color: #999; font-size: 12px; margin-top: 24px; }
  </style>
</head>
<body>
  <div class="container">
    <h2>Código de verificación</h2>
    <p>Hola <strong>{{ $userName }}</strong>,</p>
    <p>Tu código de verificación para acceder al sistema Yoltec es:</p>
    <div class="code">{{ $code }}</div>
    <p>Este código expira en <strong>10 minutos</strong>.</p>
    <p>Si no solicitaste este código, ignora este correo.</p>
    <div class="footer">Consultorio Médico Universitario — Yoltec</div>
  </div>
</body>
</html>
