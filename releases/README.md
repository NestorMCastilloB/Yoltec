# APK — Yoltec

## APK actual

`yoltec-v1.0.apk` — generado el 2026-04-12, apunta a Railway (producción).

El archivo `.apk` está excluido de git por su tamaño (50MB). Para compartirlo:

### Opción 1 — Enviar el archivo directamente

El APK ya está generado en esta carpeta. Compártelo por WhatsApp, Drive o USB.

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
# El APK queda en: mobile/build/app/outputs/apk/release/app-release.apk
cp mobile/build/app/outputs/apk/release/app-release.apk releases/yoltec-v1.0.apk
```

## Credenciales para probar

| Rol | Usuario | Contraseña |
|-----|---------|-----------|
| Alumno | `22690495` | NIP: `740270` |
| Doctor | `doctorOmar` | `doctor123` |
