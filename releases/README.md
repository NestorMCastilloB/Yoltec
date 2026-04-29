# APK — Yoltec

## APK actual

`yoltec-v1.0.apk` — apunta a producción (Render).

El archivo `.apk` está excluido de git por su tamaño (~50MB). Para compartirlo:

### Opción 1 — Enviar el archivo directamente

Compártelo por WhatsApp, Drive o USB.

### Opción 2 — GitHub Releases (recomendado)

```bash
gh release create v1.0 releases/yoltec-v1.0.apk \
  --title "Yoltec v1.0" \
  --notes "App móvil Yoltec — Consultorio médico universitario con IA"
```

Esto publica el APK en: https://github.com/elnemito001/Yoltec/releases

### Opción 3 — Regenerar el APK

```bash
cd mobile
flutter build apk --release
cp build/app/outputs/flutter-apk/app-release.apk ../releases/yoltec-v1.0.apk
```

## Credenciales para probar

| Rol | Usuario | Contraseña |
|-----|---------|-----------|
| Alumno | `22690495` | NIP: `740270` |
| Doctor | `doctorOmar` | `doctor123` |
| Doctor 2 | `doctorCarlos` | `doctor123` |
