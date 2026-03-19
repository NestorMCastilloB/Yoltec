# 🤖 Documentación Técnica - Sistema Experto Médico Yoltec

## 📢 ACTUALIZACIÓN IMPORTANTE - Marzo 2026

### Nuevo Sistema: IA por Análisis de Documentos Médicos

**Versión anterior:** Análisis por selección de síntomas (Flutter)  
**Versión actual:** Análisis automático de documentos PDF/Word (Backend + Frontend Web)

### Cambios Principales

| Aspecto | Sistema Anterior | Nuevo Sistema |
|---------|------------------|---------------|
| **Entrada de datos** | Usuario selecciona síntomas manualmente | Doctor sube documento PDF/Word |
| **Procesamiento** | Dart/Flutter local | PHP/Laravel backend |
| **Extracción** | No aplica | OCR + Pattern matching para datos médicos |
| **Diagnóstico** | Basado en síntomas seleccionados | Basado en análisis de laboratorio/imágenes |
| **Validación** | Automático | Requiere validación médica obligatoria |
| **Roles** | Solo doctor/paciente | Admin, Doctor, Paciente |

---

## 1. Resumen Ejecutivo

**Proyecto:** Yoltec - Consultorio Médico con IA Local  
**Componente IA:** Sistema Experto Médico Basado en Reglas  
**Tipo de IA:** Inteligencia Artificial Simbólica (No conexionista)  
**Desarrollo:** 100% propio, sin dependencias de APIs externas (OpenAI, Anthropic, etc.)

---

## 2. Justificación de "IA Propia"

### ¿Por qué es IA propia?

| Característica | Yoltec IA | APIs Externas (ChatGPT, Claude) |
|----------------|-----------|--------------------------------|
| **Código** | Desarrollado desde cero en Dart | Código cerrado de terceros |
| **Algoritmos** | Motor de inferencia personalizado | Modelos pre-entrenados ajenos |
| **Base de conocimiento** | Reglas médicas definidas por nosotros | Dependencia de datos externos |
| **Funcionamiento** | 100% offline en dispositivo | Requiere conexión a internet |
| **Privacidad** | Datos médicos nunca salen del móvil | Datos enviados a servidores externos |

### Tipo de IA Implementada

**Sistema Experto Basado en Reglas (Rule-Based Expert System)**

- **Paradigma:** IA Simbólica / GOFAI (Good Old-Fashioned AI)
- **Arquitectura:** Base de conocimiento + Motor de inferencia
- **Razonamiento:** Encadenamiento hacia adelante (Forward Chaining)
- **Dominio:** Medicina general / Primer contacto médico

---

## 3. Arquitectura del Sistema Experto

### 3.1 Componentes Principales

```
┌─────────────────────────────────────────────────────────────┐
│                   SISTEMA EXPERTO MÉDICO                    │
│                      (Yoltec IA)                            │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────┐ │
│  │  BASE DE        │  │  MOTOR DE       │  │  INTERFAZ   │ │
│  │  CONOCIMIENTO   │◄─┤  INFERENCIA     │◄─┤  USUARIO    │ │
│  │                 │  │                 │  │             │ │
│  │  • Síntomas     │  │  • Matching     │  │  • Selección│ │
│  │  • Diagnósticos │  │  • Probabilidad │  │    síntomas │ │
│  │  • Reglas       │  │  • Ranking      │  │  • Resultados│ │
│  │  • Pesos        │  │  • Recomendac.  │  │             │ │
│  └─────────────────┘  └─────────────────┘  └─────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

### 3.2 Estructura de Clases

```dart
// 1. Representación de Síntomas
class Sintoma {
  String id;           // Identificador único
  String nombre;       // Nombre legible
  String descripcion;  // Descripción médica
  double peso;         // Importancia (1.0 - 3.5)
}

// 2. Representación de Diagnósticos
class Diagnostico {
  String id;                    // Identificador único
  String nombre;                // Nombre del diagnóstico
  String descripcion;         // Descripción médica
  List<String> sintomasClave; // Síntomas que lo identifican
  double probabilidadBase;      // Probabilidad inicial
  String nivelUrgencia;         // baja/media/alta/emergencia
  String recomendacion;         // Recomendación general
}

// 3. Motor de Inferencia
class SistemaExpertoMedico {
  List<Sintoma> sintomas;           // Base de síntomas
  List<Diagnostico> diagnosticos;  // Base de diagnósticos
  
  // Algoritmo principal
  List<ResultadoDiagnostico> analizarSintomas(
    List<String> sintomasIds,
    Map<String, dynamic> datosAdicionales
  ) {
    // 1. Calcular coincidencias
    // 2. Aplicar pesos
    // 3. Ajustar por datos demográficos
    // 4. Ordenar por probabilidad
    // 5. Retornar top 5
  }
}
```

---

## 4. Base de Conocimiento

### 4.1 Síntomas Médicos (20 síntomas)

| Categoría | Síntomas | Peso |
|-----------|----------|------|
| **Generales** | Fiebre, Fatiga, Dolor muscular | 1.5-2.0 |
| **Respiratorios** | Tos, Tos seca, Tos productiva, Congestión nasal, Dolor garganta, Dificultad respirar, Dolor pecho, Estornudos | 1.0-3.5 |
| **Digestivos** | Náuseas, Vómito, Diarrea, Dolor abdominal | 1.0-1.5 |
| **Cabeza** | Dolor de cabeza, Pérdida olfato, Pérdida gusto | 1.5-2.5 |
| **Piel** | Erupción cutánea, Dolor articulaciones | 1.0-1.5 |

### 4.2 Diagnósticos (12 diagnósticos)

| ID | Nombre | Urgencia | Síntomas Clave |
|----|--------|----------|----------------|
| resfriado_comun | Resfriado Común | Baja | Congestión, estornudos, dolor garganta |
| influenza | Influenza | Media | Fiebre, dolor muscular, fatiga |
| covid19 | COVID-19 | Alta | Fiebre, tos seca, pérdida olfato |
| faringitis | Faringitis | Media | Dolor garganta, fiebre |
| bronquitis | Bronquitis | Media | Tos productiva, fiebre |
| neumonia | Neumonía | **Emergencia** | Fiebre, dificultad respirar, dolor pecho |
| gastroenteritis | Gastroenteritis | Media | Náuseas, vómito, diarrea |
| migraña | Migraña | Media | Dolor cabeza, náuseas |
| alergia_estacional | Alergia | Baja | Estornudos, congestión nasal |
| dengue_sospecha | Dengue | **Emergencia** | Fiebre alta, erupción, dolor muscular |
| sinusitis | Sinusitis | Media | Dolor cabeza, congestión |
| insolacion | Insolación | Alta | Fiebre, náuseas, mareo |

---

## 5. Algoritmo del Motor de Inferencia

### 5.1 Proceso de Razonamiento

```
ENTRADA: Lista de síntomas seleccionados por usuario
         Datos adicionales (edad, temperatura, días con síntomas)

PASO 1: Inicializar lista de resultados vacía

PASO 2: Para cada diagnóstico en base de conocimiento:
        
        a) Calcular FACTOR DE COINCIDENCIA:
           - Identificar síntomas del usuario que coinciden 
             con síntomas clave del diagnóstico
           - Sumar pesos de síntomas coincidentes
           - Dividir entre peso total posible
           
        b) Calcular PROBABILIDAD:
           probabilidad = probabilidad_base × (0.5 + factor_coincidencia)
           
        c) Aplicar AJUSTES CONTEXTUALES:
           - Si edad > 60 y diagnóstico grave: +20%
           - Si temperatura > 39°C: +20% para emergencias
           - Si días > 7 y resfriado: -30% (no dura tanto)
           
        d) Si probabilidad > 20%:
           - Agregar a resultados

PASO 3: Ordenar resultados por probabilidad (descendente)

PASO 4: Retornar top 5 diagnósticos con:
        - Nombre y descripción
        - Probabilidad calculada
        - Síntomas coincidentes
        - Recomendaciones personalizadas
```

### 5.2 Fórmula de Probabilidad

```
Probabilidad = P_base × (0.5 + (Σ pesos_síntomas_coincidentes / Σ pesos_total_posibles))

Donde:
- P_base: Probabilidad base del diagnóstico (0.3 - 0.7)
- Pesos: Importancia de cada síntoma (0.5 - 3.5)
- Factor 0.5: Asegura probabilidad mínima cuando hay coincidencias
```

**Ejemplo de cálculo:**
- Diagnóstico: Influenza (P_base = 0.6)
- Síntomas clave: Fiebre (2.0), Dolor muscular (1.5), Tos seca (1.5), Fatiga (1.5)
- Usuario selecciona: Fiebre, Dolor muscular, Fatiga
- Peso coincidente: 2.0 + 1.5 + 1.5 = 5.0
- Peso total posible: 2.0 + 1.5 + 1.5 + 1.5 = 6.5
- Factor coincidencia: 5.0 / 6.5 = 0.77
- Probabilidad: 0.6 × (0.5 + 0.77) = 0.6 × 1.27 = 0.76 → **76%**

---

## 6. Implementación Técnica

### 6.1 Lenguaje y Framework

- **Lenguaje:** Dart
- **Framework:** Flutter
- **Arquitectura:** Programación Orientada a Objetos
- **Patrones:** Singleton (para sistema experto), Provider (para estado)

### 6.2 Funcionamiento Offline

El sistema experto está completamente contenido en el archivo:
```
mobile/lib/ia/sistema_experto.dart
```

- No requiere conexión a internet
- No envía datos a servidores externos
- Toda la inferencia ocurre localmente en el dispositivo
- Privacidad garantizada: datos médicos nunca salen del móvil

### 6.3 Integración con la App

```dart
// Crear instancia (Singleton)
final sistema = SistemaExpertoMedico();

// Obtener síntomas organizados por categoría
final sintomas = sistema.getSintomasPorCategoria();

// Analizar cuando usuario selecciona síntomas
final resultados = sistema.analizarSintomas(
  ['fiebre', 'tos_seca', 'perdida_olfato'],
  datosAdicionales: {'edad': 25, 'temperatura': 38.5, 'dias_sintomas': 2}
);

// Mostrar resultados ordenados por probabilidad
for (var resultado in resultados) {
  print('${resultado.diagnostico.nombre}: ${resultado.probabilidad}%');
}
```

---

## 7. Validación y Pruebas

### 7.1 Casos de Prueba

| Caso | Síntomas Ingresados | Resultado Esperado | Probabilidad |
|------|---------------------|-------------------|--------------|
| Resfriado común | Congestión, estornudos, dolor garganta | Resfriado Común | ~70% |
| COVID sospecha | Fiebre, tos seca, pérdida olfato | COVID-19 | ~75% |
| Emergencia respiratoria | Fiebre alta, dificultad respirar, dolor pecho | Neumonía | ~80%+ |
| Gastroenteritis | Náuseas, vómito, diarrea | Gastroenteritis | ~65% |
| Alergia | Estornudos, congestión nasal | Alergia estacional | ~75% |

### 7.2 Limitaciones Conocidas

- **No reemplaza médico real:** Es orientativo, no diagnóstico definitivo
- **Conocimiento estático:** No aprende de nuevos casos automáticamente
- **Dominio limitado:** 12 diagnósticos predefinidos
- **Sin procesamiento de lenguaje natural:** Requiere selección de síntomas manual

---

## 8. Ventajas del Enfoque Propuesto

### 8.1 vs APIs Externas (ChatGPT, Claude)

| Aspecto | Yoltec IA Propia | APIs Externas |
|---------|------------------|---------------|
| Costo | Gratuito | Pago por uso |
| Privacidad | Total (offline) | Datos en servidores externos |
| Latencia | Inmediata (~10ms) | Variable (red dependiente) |
| Control | Total sobre lógica | Limitado a prompts |
| Cumplimiento HIPAA/GDPR | Simplificado | Complejo |

### 8.2 vs Modelos de ML Tradicionales

| Aspecto | Sistema Experto | ML (TensorFlow, etc.) |
|---------|-----------------|----------------------|
| Transparencia | Total (reglas claras) | Caja negra |
| Explicabilidad | Alta (puede explicar razonamiento) | Baja (difícil interpretar) |
| Entrenamiento | No requiere datos etiquetados | Requiere grandes datasets |
| Mantenimiento | Reglas editables manualmente | Re-entrenamiento necesario |
| Precisión médica | Controlada por expertos | Depende de calidad de datos |

---

## 9. Trabajo Futuro

### 9.1 Mejoras Planificadas

1. **Expansión de base de conocimiento:**
   - Agregar más diagnósticos (20-30 total)
   - Incluir síntomas específicos por género/edad
   - Agregar medicamentos comunes por diagnóstico

2. **Motor de inferencia mejorado:**
   - Implementar encadenamiento hacia atrás (backward chaining)
   - Agregar factores de certeza (Certainty Factors)
   - Sistema de puntuación de riesgo más sofisticado

3. **Interfaz mejorada:**
   - Chat conversacional con procesamiento de texto simple
   - Diagrama de árbol de decisión visual
   - Exportar resultados a PDF

4. **Integración clínica:**
   - Conectar con historial médico del paciente
   - Recordar diagnósticos previos
   - Alertas de seguimiento

---

## 10. Conclusión

El sistema experto médico de Yoltec representa una **implementación completa de Inteligencia Artificial propia**, desarrollada sin dependencias de APIs externas ni modelos pre-entrenados de terceros.

### Cumplimiento de Requisitos Académicos:

✅ **IA Propia:** Sistema experto desde cero, algoritmos propios  
✅ **Multiplataforma:** Flutter permite Android, iOS, Web, Desktop  
✅ **Seguridad:** Funcionamiento offline garantiza privacidad de datos médicos  
✅ **Metodologías Ágiles:** Desarrollo iterativo documentado en commits  

### Impacto:

- Herramienta de orientación médica accesible 24/7
- Reducción de carga en sistema de salud para casos leves
- Educación médica para usuarios
- Demostración práctica de IA simbólica en medicina

---

**Documento técnico preparado para evaluación académica**  
**Proyecto Yoltec - Sistema Experto Médico**  
**Fecha:** Marzo 2026
