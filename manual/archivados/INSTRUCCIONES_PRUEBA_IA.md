# 📄 INSTRUCCIONES DE PRUEBA - Sistema IA por Documentos

## 🎯 ¿Qué es esto?

Este documento contiene **datos médicos simulados** que puedes usar para probar el nuevo sistema de IA que analiza documentos médicos.

---

## 📋 Contenido del Archivo de Prueba

El archivo `PRUEBA_DATOS_MEDICOS.txt` contiene:

### Datos del Paciente Simulado
- **Nombre:** Juan Carlos Martínez
- **Edad:** 22 años
- **ID:** A12345678 (número de control tipo alumno)

### Datos Clínicos Incluidos

| Parámetro | Valor | Estado Esperado |
|-----------|-------|-----------------|
| **Glucosa** | 145 mg/dL | ⚠️ Alto (normal: 70-100) |
| **Presión Arterial** | 142/92 mmHg | ⚠️ Alto (normal: 120/80) |
| **Hemoglobina** | 10.5 g/dL | ⚠️ Bajo (normal: 12-16) |
| **Creatinina** | 1.4 mg/dL | ⚠️ Alto (normal: 0.7-1.3) |
| **Transaminasas (ALT)** | 52 U/L | ⚠️ Alto (normal: 10-40) |
| **Triglicéridos** | 185 mg/dL | ⚠️ Alto |
| **Colesterol LDL** | 145 mg/dL | ⚠️ Alto |
| **IMC** | 27.9 | ⚠️ Sobrepeso |

---

## 🤖 Diagnósticos que la IA Debería Sugerir

Al analizar este documento, la IA debería detectar y sugerir:

1. **Diabetes Mellitus Tipo 2** (por glucosa 145 mg/dL > 126)
2. **Hipertensión Arterial** (por PA 142/92 mmHg)
3. **Anemia** (por hemoglobina baja 10.5 g/dL)
4. **Dislipidemia** (por triglicéridos y colesterol elevados)
5. **Sobrepeso** (por IMC 27.9)
6. **Posible compromiso renal** (por creatinina elevada)

---

## 🧪 Cómo Probar el Sistema

### Paso 1: Crear el PDF
1. Copia el contenido de `PRUEBA_DATOS_MEDICOS.txt`
2. Pégalo en Word o Google Docs
3. Guarda como PDF: `prueba_juan_martinez.pdf`

### Paso 2: Subir al Sistema
1. Inicia sesión como **Doctor** o **Administrador**
2. Ve a: **📤 Subir Doc** (en el menú del dashboard)
3. Selecciona el paciente (crea uno con nombre "Juan Carlos Martínez")
4. Tipo de documento: **Laboratorio**
5. Selecciona el archivo PDF creado
6. Click en **Subir y Analizar**

### Paso 3: Revisar el Análisis de IA
- Espera 5-10 segundos mientras la IA procesa
- Revisa que haya detectado:
  - ✅ Glucosa: 145 mg/dL
  - ✅ Presión: 142/92 mmHg
  - ✅ Hemoglobina: 10.5 g/dL
  - ✅ Diagnóstico: Diabetes Tipo 2
  - ✅ Diagnóstico: Hipertensión
  - ✅ Diagnóstico: Anemia

### Paso 4: Validar como Doctor
1. Ve a: **✅ Validar IA** (en el menú del dashboard)
2. Verás el análisis pendiente de validación
3. Revisa el diagnóstico sugerido
4. Puedes:
   - **Aprobar** (si está correcto)
   - **Corregir** (cambiar diagnóstico)
   - **Rechazar** (con comentario)

---

## 📊 Resultados Esperados

### Si todo funciona correctamente:

```
✅ Documento subido exitosamente
✅ Texto extraído del PDF
✅ IA detectó 6 parámetros médicos
✅ IA sugiere 3 diagnósticos principales
✅ Doctor ve análisis pendiente
✅ Doctor valida diagnóstico
✅ Paciente puede ver resultado validado
```

---

## 🔧 Para Profesores/Evaluadores

### Demostración Académica:

1. **Subir Documento** (5 min)
   - Mostrar cómo el doctor sube el PDF
   - Explicar extracción automática de texto

2. **Análisis de IA** (5 min)
   - Ver datos detectados en tiempo real
   - Explicar algoritmo de pattern matching
   - Mostrar nivel de confianza calculado

3. **Validación Médica** (5 min)
   - Demostrar flujo de aprobación
   - Mostrar opción de corregir IA
   - Explicar importancia de supervisión humana

4. **Historial del Paciente** (3 min)
   - Ver todos sus documentos
   - Descargar PDF original
   - Consultar diagnósticos validados

---

## 📝 Notas para Documentación Académica

### Características del Sistema de IA:

| Aspecto | Implementación |
|---------|----------------|
| **Tipo de IA** | Sistema Experto Basado en Reglas |
| **Procesamiento** | NLP básico + Pattern Matching |
| **Datos de entrada** | Texto extraído de PDF/Word |
| **Salida** | Diagnósticos sugeridos + Confianza |
| **Validación** | Requerida por médico profesional |
| **Privacidad** | 100% local (sin APIs externas) |

### Justificación de "IA Propia":
- ✅ Algoritmos desarrollados desde cero
- ✅ Base de conocimiento personalizada
- ✅ No depende de OpenAI, Google, etc.
- ✅ Funciona offline
- ✅ Código completamente auditado

---

## 🎓 Competencias Académicas Demostradas

### Inteligencia Artificial:
- [x] Sistema experto implementado
- [x] Procesamiento de documentos
- [x] Extracción de entidades médicas
- [x] Algoritmo de inferencia
- [x] Cálculo de confianza probabilístico

### Seguridad Web:
- [x] 2FA implementado
- [x] Roles y permisos (Admin, Doctor, Paciente)
- [x] Auditoría de accesos
- [x] Validación médica obligatoria

### Multiplataforma:
- [x] Backend Laravel API
- [x] Frontend Angular Web
- [x] App Flutter Móvil (pendiente conectar)

---

## ⚠️ Limitaciones Conocidas

1. **Extracción de texto**: Depende de calidad del PDF
2. **Diagnósticos**: Solo cubre patologías comunes predefinidas
3. **Precisión**: Requiere validación médica obligatoria
4. **Formatos**: Solo PDF y Word soportados

---

**Archivo listo para pruebas:** ✅ `PRUEBA_DATOS_MEDICOS.txt`

¿Necesitas que cree más documentos de prueba con otros escenarios (ej. paciente sano, paciente con hepatitis, etc.)?
