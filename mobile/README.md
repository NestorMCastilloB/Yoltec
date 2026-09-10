# Yoltec — App Móvil (Flutter)

Aplicación móvil multiplataforma del sistema de consultorio médico universitario.

## Tecnologías
- Flutter / Dart
- Provider (gestión de estado)
- HTTP (comunicación con backend Laravel)
- Compatible con Android, iOS, Linux y Windows

## Correr en local

```bash
flutter pub get
flutter run             # requiere emulador o dispositivo conectado
```

### Emulador Android (Linux)
```bash
~/Android/Sdk/emulator/emulator -avd Medium_Phone_API_33 -gpu swiftshader_indirect
flutter run
```

## Generar APK

```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

## Configuración de red

La URL base de la API se sobreescribe al ejecutar o compilar la app con el flag
`--dart-define=API_BASE_URL=...`, sin tocar el código fuente:

```bash
# Emulador Android
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api

# Celular físico (WiFi) — usar la IP local de la PC
flutter run --dart-define=API_BASE_URL=http://192.168.x.x:8000/api
```

Sin el flag, por defecto apunta a producción (`https://yoltec-backend.onrender.com/api`).

## Estructura

```
lib/
├── main.dart               # Punto de entrada + Providers
├── models/                 # Cita, Bitacora, Receta
├── screens/
│   ├── login_screen.dart
│   ├── student/            # Dashboard alumno (inicio, citas, bitácora, recetas)
│   └── doctor/             # Dashboard doctor (inicio, citas, bitácoras, pre-eval, prioridad)
├── services/               # API, Auth, Citas, Bitácora, Recetas, PreEvaluación, IAPrioridad
└── utils/
    └── app_theme.dart      # Colores y estilos globales
```
