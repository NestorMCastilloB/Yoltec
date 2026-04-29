# Script de Demo — Yoltec
**Duración estimada:** 10-15 minutos
**Fecha:** 2026-04-19

---

## Antes de empezar

Levantar todos los servicios:

```bash
# Terminal 1 — Backend
cd /home/nestor/yoltec/backend && php artisan serve --host=0.0.0.0 --port=8000

# Terminal 2 — Frontend
cd /home/nestor/yoltec/frontend && ng serve --host=0.0.0.0 --port=4200

# Terminal 3 — IA
cd /home/nestor/yoltec/IA && source venv/bin/activate && uvicorn app:app --host=0.0.0.0 --port=5000
```

Abrir en el navegador: **http://localhost:4200**
Tener el APK instalado en el dispositivo: `releases/yoltec-v1.0.apk`

---

## Flujo de demo (orden recomendado)

### 1. Login del alumno (1 min)
1. Entrar a http://localhost:4200
2. Ingresar número de control `22690495` y NIP `740270`
3. **Mostrar:** redirige al dashboard del alumno

---

### 2. Alumno agenda una cita (2 min)
1. Ir a **Citas → Agendar**
2. **Mostrar:** calendario con colores (verde/amarillo/rojo), domingos bloqueados
3. Seleccionar una fecha próxima (lunes-sábado)
4. Seleccionar un slot disponible
5. Ingresar motivo: "Dolor de cabeza frecuente"
6. Confirmar
7. **Mostrar:** cita aparece en la lista con estatus "Programada"

---

### 3. IA — Pre-evaluación de síntomas (2 min)
1. Ir a **Pre-evaluación**
2. Escribir en el chat: "He tenido dolor de cabeza frecuente, náuseas y sensibilidad a la luz desde hace 3 días"
3. **Mostrar:** el chat de Groq responde en lenguaje natural
4. Completar el flujo de preguntas
5. **Mostrar:** diagnóstico preliminar con porcentaje de confianza (sklearn)

---

### 4. Login del doctor (1 min)
1. Cerrar sesión del alumno
2. Iniciar sesión como `doctorOmar` / `doctor123`
3. **Mostrar:** dashboard del doctor — citas del día, próxima cita, gráficas

---

### 5. Doctor atiende la cita (2 min)
1. Ir a **Citas → Citas del día**
2. Localizar la cita del alumno
3. Clic en el alumno → **Mostrar:** modal con foto, tipo de sangre, alergias, historial
4. Ir a Pre-evaluaciones → **Mostrar:** los síntomas que reportó el alumno
5. Validar el diagnóstico de la IA
6. Marcar la cita como "Atendida" → llenar diagnóstico y tratamiento

---

### 6. Doctor crea receta (1 min)
1. Ir a **Recetas → Nueva receta**
2. Buscar al alumno
3. Ingresar: Medicamento "Ibuprofeno 400mg", Dosis "1 cada 8 horas", Indicaciones "Tomar con comida por 5 días"
4. Guardar
5. **Mostrar:** receta en la lista

---

### 7. Historial médico — vista del alumno (1 min)
1. Cerrar sesión del doctor
2. Login como alumno `22690495`
3. Ir a **Historial**
4. **Mostrar:** consulta recién atendida con diagnóstico, tratamiento y receta
5. Ir a **Recetas** → **Mostrar:** la receta creada por el doctor

---

### 8. App móvil Flutter (2 min)
1. Abrir la app en el dispositivo (APK instalado)
2. Login con `22690495` / `740270`
3. **Mostrar:** splash screen animado → home
4. Ir a **Citas** → mostrar cita programada
5. Ir a **Pre-evaluación** → abrir chat IA
6. Ir a **Recetas** → mostrar la receta
7. Ir a **Mi Perfil** → mostrar foto, datos personales y médicos
8. Activar **Dark Mode** → mostrar cambio de tema
9. **Opcional:** apagar WiFi → mostrar banner naranja de modo offline

---

### 9. Panel Admin (1 min)
1. Cerrar sesión
2. Login como `admin` / `admin123`
3. **Mostrar:** /admin-dashboard con lista de alumnos y doctores
4. Buscar alumno en tiempo real con el buscador
5. Ir a **Días especiales** → marcar un día como festivo

---

## Puntos clave a destacar durante la demo

- Sistema multi-rol: alumno, doctor, admin
- IA real: Groq (LLM gratuito) + scikit-learn para diagnóstico
- App móvil funcional con modo offline y dark mode
- Notificaciones push (FCM) al agendar/cancelar citas
- Despliegue en producción: Vercel (Angular) + Render (Laravel + Python)
- Base de datos en Neon PostgreSQL (cloud)
- No se guardan PDFs — todo en pantalla

---

## URLs de producción (para demo en vivo)

| Servicio | URL |
|----------|-----|
| Frontend | https://yoltec.vercel.app |
| Backend API | https://yoltec-backend.onrender.com |
| IA | https://yoltec-ia.onrender.com |
