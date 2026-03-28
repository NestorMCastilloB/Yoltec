# Yoltec — Frontend (Angular 20)

Aplicación web SPA del sistema de consultorio médico universitario.

## Tecnologías
- Angular 20
- TypeScript
- Comunicación con backend vía HTTP (API REST)

## Correr en local

```bash
npm install
ng serve --host=0.0.0.0 --port=4200
```

Acceder en: `http://localhost:4200`

## Build para producción

```bash
ng build --configuration production
# Output en: dist/
```

## Estructura

```
src/app/
├── login/                  # Pantalla de login (alumno y doctor)
├── splash-screen/          # Pantalla de carga inicial
├── student-dashboard/      # Panel del alumno (citas, IA, bitácora, recetas)
├── doctor-dashboard/       # Panel del doctor (dashboard, pre-eval, prioridad)
├── components/             # Componentes reutilizables
└── services/               # Servicios HTTP (auth, citas, IA, bitácora, recetas)
```

## Variables de entorno

Configurar la URL del backend en `src/app/services/api-config.ts`.
