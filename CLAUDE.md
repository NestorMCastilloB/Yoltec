# CLAUDE.md — Instrucciones del proyecto Yoltec

Este archivo se carga automáticamente en cada conversación con Claude Code.
Contiene el contexto completo del proyecto para no repetir explicaciones.

---

## Qué es este proyecto

Sistema de consultorio médico universitario con IA integrada.
Desarrollado por Nestor (alumno universitario).
**Deadline: abril 2026** (lo antes posible).

---

## Stack tecnológico (NO cambiar sin consultar)

| Capa | Tecnología |
|------|-----------|
| Backend | Laravel 12 |
| Frontend web | Angular 20 |
| App móvil | Flutter / Dart |
| Base de datos | PostgreSQL (local ahora, Neon después) |
| IA | Python + scikit-learn (modelos propios, sin APIs de pago) |

**IMPORTANTE**: No usar APIs de IA de pago (OpenAI, Anthropic, etc.). Todo debe funcionar con herramientas open source / gratuitas.

---

## Credenciales de prueba

- **Alumno**: número_control `22690495` / NIP `740270`
- **Doctor**: username `doctorOmar` / password `doctor123`
- **Doctor 2**: username `doctorCarlos` / password `doctor123`

---

## Cómo correr el proyecto (desarrollo local)

```bash
# Backend Laravel
cd /home/nestor/yoltec/backend
php artisan serve --host=127.0.0.1 --port=8000

# Frontend Angular
cd /home/nestor/yoltec/frontend
ng serve --host=0.0.0.0 --port=4200

# Base de datos: SQLite local en backend/database/database.sqlite
# Migraciones ya ejecutadas. Si hay problemas:
php artisan migrate:fresh --seed
```

---

## Módulos del sistema

### 1. Login
- **Alumno**: número_control + NIP (ej: 22690495 / 740270)
- **Doctor**: username + password (hash bcrypt)
- 2FA desactivado en local (APP_ENV=local salta el 2FA directo al token)
- En producción se activa 2FA

### 2. Calendario de citas (alumno y doctor)
- Lunes a sábado (domingos SIEMPRE inhabilitados)
- Horario: 8:00am - 5:00pm, intervalos de 15 minutos
- Colores: verde (mucha disponibilidad), amarillo (poca), rojo (no disponible/festivo)
- Tiempo pasado: inhabilitado automáticamente
- Slots exclusivos: si alguien aparta un horario, nadie más puede tomarlo
- Cancelaciones liberan el slot
- Motivo obligatorio al agendar
- Doctor puede agendar Y cancelar citas a nombre de alumnos

### 3. Dashboard Doctor (inicio)
- Citas del día actual
- Cita más próxima
- Total de citas pendientes
- Se actualiza dinámicamente

### 4. IA Pre-evaluación de síntomas (alumno, después de agendar)
- Preguntas con opciones definidas (NO lenguaje natural — demasiado riesgoso para el deadline)
- Genera diagnóstico preliminar con % de confianza
- Visible para alumno y doctor
- Doctor puede validar o descartar
- Implementación: Python + scikit-learn, modelo entrenado con dataset sintético generado por nosotros
- Dataset objetivo: ~200k registros sintéticos síntoma→enfermedad

### 5. IA Clasificación de prioridad (solo visible al doctor)
- Clasifica alumnos por historial de citas
- Alta prioridad: asiste siempre, puntual
- Baja prioridad: cancela frecuentemente o no asiste
- Solo notifica al doctor, NO mueve ni cancela citas automáticamente
- Implementación: reglas + modelo ML simple

### 6. Recetas
- ~~PDF~~ **ELIMINADO** — no se usará PDF
- Doctor crea receta, alumno la puede ver en pantalla

### 7. Bitácora
- Historial de citas: atendidas, canceladas, no asistidas
- Base de datos para la IA de clasificación de prioridad
- Visible para doctor; alumno ve solo sus propias citas

### 8. App móvil (Flutter)
- Misma funcionalidad que la web
- Consume el mismo backend Laravel (mismos endpoints API)
- Carpeta: `/home/nestor/yoltec/mobile` (actualmente vacía — hay que crear el proyecto)
- Multiplataforma: Android, iOS, Windows, Linux

---

## Estructura de carpetas

```
/home/nestor/yoltec/
├── backend/          # Laravel 12
├── frontend/         # Angular 20
├── mobile/           # Flutter (por crear)
├── IA/               # Python + scikit-learn
├── manual/           # Documentación
└── docker-compose.yml
```

---

## Decisiones de arquitectura tomadas

1. **Sin 2FA en local** — solo en producción
2. **Sin PDFs** — eliminados, no son útiles
3. **IA sin APIs de pago** — scikit-learn + dataset sintético propio
4. **Sin lenguaje natural en IA** — preguntas con opciones (más confiable, más rápido)
5. **PostgreSQL** — local por ahora, migrar a Neon después

---

## Lo que NO funciona / está incompleto (estado 2026-03-21)

- App móvil Flutter: carpeta vacía, hay que crear el proyecto desde cero
- Dataset de IA: hay que generarlo (sintético, ~200k registros)
- Modelo IA: hay que entrenarlo (actualmente solo hay reglas PHP)
- Dashboard del doctor: estructura básica, falta dinamismo
- Muchas cosas del código existente pueden estar mal o incompletas — verificar antes de asumir que funciona

---

## Preferencias de trabajo

- Comunicación siempre en español
- Priorizar que funcione sobre que sea perfecto
- Eliminar código que no sirve, no acumular deuda técnica
- No usar APIs de pago
- Siempre verificar que el backend esté corriendo antes de probar el frontend
