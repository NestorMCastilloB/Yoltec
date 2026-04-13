<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <style>
    body { font-family: Arial, sans-serif; background: #f4f4f4; margin: 0; padding: 20px; }
    .container { max-width: 480px; margin: 0 auto; background: #fff; border-radius: 8px; padding: 32px; }
    h2 { color: #4CAF50; }
    .detalle { background: #f0f9f0; border-left: 4px solid #4CAF50; padding: 16px; border-radius: 4px; margin: 24px 0; }
    .detalle p { margin: 6px 0; font-size: 15px; }
    .footer { color: #999; font-size: 12px; margin-top: 24px; }
  </style>
</head>
<body>
  <div class="container">
    <h2>Recordatorio de cita médica</h2>
    <p>Hola <strong>{{ $nombreAlumno }}</strong>,</p>
    <p>Te recordamos que tienes una cita médica <strong>mañana</strong>:</p>
    <div class="detalle">
      <p>📅 <strong>Fecha:</strong> {{ $fechaCita }}</p>
      <p>🕐 <strong>Hora:</strong> {{ $horaCita }}</p>
      @if($motivo)
      <p>📋 <strong>Motivo:</strong> {{ $motivo }}</p>
      @endif
    </div>
    <p>Por favor preséntate puntualmente en el consultorio médico universitario.</p>
    <p>Si necesitas cancelar tu cita, hazlo con anticipación desde el sistema.</p>
    <div class="footer">Consultorio Médico Universitario — Yoltec</div>
  </div>
</body>
</html>
