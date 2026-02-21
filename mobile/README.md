# 📱 Yoltec Mobile - App Flutter con IA Local

## 🎯 Estado Actual - ✅ COMPLETADO

Se ha creado la app Flutter con **Sistema Experto de IA propia**, 100% offline y funcional.

### ✅ Implementado:
- [x] Sistema experto médico basado en reglas (IA propia)
- [x] Estructura Flutter completa
- [x] Login con API Laravel
- [x] Pantalla principal con menú
- [x] Asistente médico IA integrado
- [x] UI Material 3 moderna
- [x] Conexión a backend Laravel

## 🧠 Sistema Experto de IA - FUNCIONANDO

La IA está implementada en `lib/ia/sistema_experto.dart`

### Características:
- **12 diagnósticos médicos** predefinidos
- **20+ síntomas** organizados por categorías
- **Análisis probabilístico** basado en coincidencias
- **100% offline** - no requiere internet
- **Niveles de urgencia**: baja, media, alta, emergencia

### Cómo Usar:
1. Abrir app y hacer login
2. Tocar "🤖 Asistente Médico IA"
3. Seleccionar síntomas por categoría
4. Presionar "Analizar Síntomas"
5. Ver resultados ordenados por probabilidad

### Diagnósticos Disponibles:
- Resfriado Común
- Influenza
- COVID-19 (sospecha)
- Faringitis
- Bronquitis
- Neumonía (emergencia)
- Gastroenteritis
- Migraña
- Alergia Estacional
- Dengue (sospecha)
- Sinusitis
- Insolación

## 🚀 Cómo Ejecutar

### 1. Pre-requisitos
```bash
sudo snap install flutter --classic
flutter doctor
```

### 2. Instalar Dependencias
```bash
cd /home/nestor/yoltec/mobile
flutter pub get
```

### 3. Configurar IP del Backend
Editar `lib/services/auth_service.dart`:
```dart
// Cambiar a tu IP local
static const String baseUrl = 'http://192.168.1.X:8000/api';
```

### 4. Ejecutar
```bash
flutter run
```

## 📁 Estructura del Proyecto

```
mobile/
├── lib/
│   ├── main.dart                    # Punto de entrada
│   ├── ia/
│   │   └── sistema_experto.dart    # 🧠 IA LOCAL - Sistema experto médico
│   ├── models/
│   │   ├── user.dart               # Modelo usuario
│   │   ├── cita.dart               # Modelo cita
│   │   └── bitacora.dart           # Modelo bitácora
│   ├── services/
│   │   └── auth_service.dart       # Conexión API Laravel
│   ├── screens/
│   │   ├── login_screen.dart       # Login
│   │   ├── home_screen.dart        # Pantalla principal
│   │   └── ia_assistant_screen.dart # 🤖 Asistente IA
│   ├── widgets/
│   │   ├── custom_button.dart
│   │   └── custom_text_field.dart
│   └── utils/
│       └── app_theme.dart          # Tema de la app
├── pubspec.yaml                    # Dependencias
└── README.md                       # Este archivo
```

## 🔧 Backend Laravel (Intacto)

El backend funciona igual que antes:
- ✅ Autenticación Sanctum
- ✅ API REST completa
- ✅ Gestión citas, bitácoras, recetas
- ✅ Middleware CORS configurado

## 📱 Plan de Desarrollo

### ✅ Fase 1: COMPLETADA
- [x] Sistema experto IA propia
- [x] Estructura Flutter
- [x] Login y autenticación
- [x] Pantalla asistente IA

### 🚧 Fase 2: PENDIENTE
- [ ] Pantalla de citas completa
- [ ] Pantalla de bitácoras
- [ ] Pantalla de recetas
- [ ] Perfil de usuario
- [ ] Notificaciones push

## 🎯 Testing de la IA

### Caso 1: Resfriado
**Síntomas**: Congestión nasal, estornudos, dolor garganta  
**Esperado**: Resfriado común (alta probabilidad)

### Caso 2: COVID
**Síntomas**: Fiebre, tos seca, pérdida olfato  
**Esperado**: COVID-19 sospecha (nivel alto)

### Caso 3: Emergencia
**Síntomas**: Fiebre alta, dificultad respirar, dolor pecho  
**Esperado**: Neumonía (emergencia)

## �️ Solución de Problemas

### Error: `Connection refused`
**Solución**: Usar IP local (192.168.1.X), no `localhost`

### Error: `CORS`
**Solución**: Verificar middleware CORS en Laravel

## ⚠️ Disclaimer

**IMPORTANTE**: Este sistema es orientativo. No reemplaza médicos reales. En emergencias, acude a urgencias.

## 🎉 ¡LISTO!

La app Flutter con IA propia está completa y funcional. El sistema experto médico trabaja 100% offline analizando síntomas y dando recomendaciones.

**Desarrollado para Yoltec - 2024**
