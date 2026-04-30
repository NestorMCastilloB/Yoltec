// Sistema Experto Médico - Yoltec IA
// Basado en reglas médicas predefinidas
// Funciona 100% offline sin APIs externas

class Sintoma {
  final String id;
  final String nombre;
  final String descripcion;
  final double peso;

  Sintoma({
    required this.id,
    required this.nombre,
    required this.descripcion,
    this.peso = 1.0,
  });
}

class Diagnostico {
  final String id;
  final String nombre;
  final String descripcion;
  final List<String> sintomasClave;
  final double probabilidadBase;
  final String recomendacion;
  final String nivelUrgencia; // 'baja', 'media', 'alta', 'emergencia'

  Diagnostico({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.sintomasClave,
    required this.probabilidadBase,
    required this.recomendacion,
    required this.nivelUrgencia,
  });
}

class ResultadoDiagnostico {
  final Diagnostico diagnostico;
  final double probabilidad;
  final List<String> sintomasDetectados;
  final List<String> recomendaciones;

  ResultadoDiagnostico({
    required this.diagnostico,
    required this.probabilidad,
    required this.sintomasDetectados,
    required this.recomendaciones,
  });
}

class SistemaExpertoMedico {
  // Singleton
  static final SistemaExpertoMedico _instance = SistemaExpertoMedico._internal();
  factory SistemaExpertoMedico() => _instance;
  SistemaExpertoMedico._internal();

  // Base de conocimiento de síntomas
  final Map<String, Sintoma> _sintomas = {
    'fiebre': Sintoma(
      id: 'fiebre',
      nombre: 'Fiebre',
      descripcion: 'Temperatura corporal elevada (>37.5°C)',
      peso: 2.0,
    ),
    'dolor_cabeza': Sintoma(
      id: 'dolor_cabeza',
      nombre: 'Dolor de cabeza',
      descripcion: 'Dolor en la cabeza de intensidad variable',
      peso: 1.5,
    ),
    'tos': Sintoma(
      id: 'tos',
      nombre: 'Tos',
      descripcion: 'Reflejo de expulsión de aire de los pulmones',
      peso: 1.0,
    ),
    'tos_seca': Sintoma(
      id: 'tos_seca',
      nombre: 'Tos seca',
      descripcion: 'Tos sin producción de flema',
      peso: 1.5,
    ),
    'tos_productiva': Sintoma(
      id: 'tos_productiva',
      nombre: 'Tos productiva',
      descripcion: 'Tos con flema o mucosidad',
      peso: 1.5,
    ),
    'dolor_garganta': Sintoma(
      id: 'dolor_garganta',
      nombre: 'Dolor de garganta',
      descripcion: 'Molestia o dolor al tragar',
      peso: 1.0,
    ),
    'congestion_nasal': Sintoma(
      id: 'congestion_nasal',
      nombre: 'Congestión nasal',
      descripcion: 'Nariz tapada o con moco',
      peso: 0.8,
    ),
    'estornudos': Sintoma(
      id: 'estornudos',
      nombre: 'Estornudos',
      descripcion: 'Expulsión repentina de aire por la nariz',
      peso: 0.5,
    ),
    'dolor_muscular': Sintoma(
      id: 'dolor_muscular',
      nombre: 'Dolor muscular',
      descripcion: 'Malestar general en músculos',
      peso: 1.5,
    ),
    'fatiga': Sintoma(
      id: 'fatiga',
      nombre: 'Fatiga',
      descripcion: 'Sensación de cansancio extremo',
      peso: 1.5,
    ),
    'dolor_pecho': Sintoma(
      id: 'dolor_pecho',
      nombre: 'Dolor de pecho',
      descripcion: 'Molestia en el tórax',
      peso: 3.0,
    ),
    'dificultad_respirar': Sintoma(
      id: 'dificultad_respirar',
      nombre: 'Dificultad para respirar',
      descripcion: 'Falta de aire o respiración agitada',
      peso: 3.5,
    ),
    'nauseas': Sintoma(
      id: 'nauseas',
      nombre: 'Náuseas',
      descripcion: 'Sensación de mareo o ganas de vomitar',
      peso: 1.0,
    ),
    'vomito': Sintoma(
      id: 'vomito',
      nombre: 'Vómito',
      descripcion: 'Expulsión de contenido estomacal',
      peso: 1.5,
    ),
    'diarrea': Sintoma(
      id: 'diarrea',
      nombre: 'Diarrea',
      descripcion: 'Evacuaciones líquidas frecuentes',
      peso: 1.5,
    ),
    'dolor_abdominal': Sintoma(
      id: 'dolor_abdominal',
      nombre: 'Dolor abdominal',
      descripcion: 'Malestar en el vientre',
      peso: 1.5,
    ),
    'perdida_olfato': Sintoma(
      id: 'perdida_olfato',
      nombre: 'Pérdida del olfato',
      descripcion: 'Incapacidad para percibir olores',
      peso: 2.5,
    ),
    'perdida_gusto': Sintoma(
      id: 'perdida_gusto',
      nombre: 'Pérdida del gusto',
      descripcion: 'Incapacidad para percibir sabores',
      peso: 2.5,
    ),
    'erupcion_cutanea': Sintoma(
      id: 'erupcion_cutanea',
      nombre: 'Erupción cutánea',
      descripcion: 'Aparición de manchas o granos en piel',
      peso: 1.5,
    ),
    'dolor_articulaciones': Sintoma(
      id: 'dolor_articulaciones',
      nombre: 'Dolor en articulaciones',
      descripcion: 'Malestar en rodillas, codos, muñecas, etc.',
      peso: 1.0,
    ),
  };

  // Base de conocimiento de diagnósticos
  final List<Diagnostico> _diagnosticos = [
    Diagnostico(
      id: 'resfriado_comun',
      nombre: 'Resfriado Común',
      descripcion: 'Infección viral leve del tracto respiratorio superior',
      sintomasClave: ['congestion_nasal', 'estornudos', 'dolor_garganta', 'tos'],
      probabilidadBase: 0.7,
      recomendacion: 'Descanso, hidratación abundante, paracetamol si hay fiebre. Generalmente mejora en 3-7 días.',
      nivelUrgencia: 'baja',
    ),
    Diagnostico(
      id: 'influenza',
      nombre: 'Influenza (Gripe)',
      descripcion: 'Infección viral respiratoria más severa que el resfriado',
      sintomasClave: ['fiebre', 'dolor_muscular', 'fatiga', 'tos_seca', 'dolor_cabeza'],
      probabilidadBase: 0.6,
      recomendacion: 'Descanso absoluto, mucha hidratación, antitérmicos. Consultar médico si empeora después de 3 días.',
      nivelUrgencia: 'media',
    ),
    Diagnostico(
      id: 'covid19',
      nombre: 'COVID-19 (Sospecha)',
      descripcion: 'Infección por coronavirus SARS-CoV-2',
      sintomasClave: ['fiebre', 'tos_seca', 'perdida_olfato', 'perdida_gusto', 'fatiga'],
      probabilidadBase: 0.5,
      recomendacion: 'IMPORTANTE: Realizar prueba COVID. Aislamiento inmediato. Consultar médico urgente si dificultad para respirar.',
      nivelUrgencia: 'alta',
    ),
    Diagnostico(
      id: 'faringitis',
      nombre: 'Faringitis (Amigdalitis)',
      descripcion: 'Inflamación de la garganta/amígdalas',
      sintomasClave: ['dolor_garganta', 'fiebre', 'dolor_cabeza'],
      probabilidadBase: 0.6,
      recomendacion: 'Gárgaras con agua tibia y sal, analgésicos, antibióticos solo si es bacteriana (prescripción médica).',
      nivelUrgencia: 'media',
    ),
    Diagnostico(
      id: 'bronquitis',
      nombre: 'Bronquitis',
      descripcion: 'Inflamación de los bronquios',
      sintomasClave: ['tos_productiva', 'fiebre', 'fatiga', 'dolor_pecho'],
      probabilidadBase: 0.5,
      recomendacion: 'Descanso, líquidos abundantes, evitar humo. Consultar médico si fiebre persiste más de 3 días.',
      nivelUrgencia: 'media',
    ),
    Diagnostico(
      id: 'neumonia',
      nombre: 'Neumonía (Sospecha)',
      descripcion: 'Infección grave de los pulmones',
      sintomasClave: ['fiebre', 'tos_productiva', 'dificultad_respirar', 'dolor_pecho', 'fatiga'],
      probabilidadBase: 0.4,
      recomendacion: 'URGENTE: Consultar médico inmediatamente. Requiere evaluación médica y posiblemente rayos X.',
      nivelUrgencia: 'emergencia',
    ),
    Diagnostico(
      id: 'gastroenteritis',
      nombre: 'Gastroenteritis',
      descripcion: 'Infección del tracto gastrointestinal',
      sintomasClave: ['nauseas', 'vomito', 'diarrea', 'dolor_abdominal', 'fiebre'],
      probabilidadBase: 0.6,
      recomendacion: 'Hidratación oral constante (suero), dieta blanda. Consultar médico si deshidratación severa.',
      nivelUrgencia: 'media',
    ),
    Diagnostico(
      id: 'migraña',
      nombre: 'Migraña',
      descripcion: 'Dolor de cabeza severo pulsátil',
      sintomasClave: ['dolor_cabeza', 'nauseas', 'sensibilidad_luz'],
      probabilidadBase: 0.5,
      recomendacion: 'Descanso en lugar oscuro y silencioso, analgésicos específicos si se tienen prescritos.',
      nivelUrgencia: 'media',
    ),
    Diagnostico(
      id: 'alergia_estacional',
      nombre: 'Alergia Estacional (Rinitis Alérgica)',
      descripcion: 'Reacción alérgica a polen, polvo u otros alérgenos',
      sintomasClave: ['estornudos', 'congestion_nasal', 'picazon_ojos', 'secrecion_nasal'],
      probabilidadBase: 0.7,
      recomendacion: 'Antihistamínicos, evitar alérgenos, lavado nasal con suero.',
      nivelUrgencia: 'baja',
    ),
    Diagnostico(
      id: 'dengue_sospecha',
      nombre: 'Dengue (Sospecha)',
      descripcion: 'Infección viral transmitida por mosquitos',
      sintomasClave: ['fiebre_alta', 'dolor_muscular_intenso', 'dolor_cabeza', 'erupcion_cutanea'],
      probabilidadBase: 0.3,
      recomendacion: 'URGENTE: Consultar médico inmediatamente. Evitar aspirina. Hidratación constante.',
      nivelUrgencia: 'emergencia',
    ),
    Diagnostico(
      id: 'sinusitis',
      nombre: 'Sinusitis',
      descripcion: 'Inflamación de los senos paranasales',
      sintomasClave: ['dolor_cabeza', 'congestion_nasal', 'secrecion_nasal', 'presion_facial'],
      probabilidadBase: 0.5,
      recomendacion: 'Descongestionantes, lavados nasales, analgésicos. Consultar si persiste más de 10 días.',
      nivelUrgencia: 'media',
    ),
    Diagnostico(
      id: 'insolacion',
      nombre: 'Insolación/Golpe de Calor',
      descripcion: 'Sobrecalentamiento del cuerpo por exposición solar',
      sintomasClave: ['fiebre', 'dolor_cabeza', 'nauseas', 'mareo', 'piel_caliente'],
      probabilidadBase: 0.6,
      recomendacion: 'Mover a lugar fresco, hidratación, ropa ligera. Consultar médico si confusión o desmayo.',
      nivelUrgencia: 'alta',
    ),
  ];

  /// Analiza síntomas y devuelve posibles diagnósticos ordenados por probabilidad
  List<ResultadoDiagnostico> analizarSintomas(List<String> sintomasIds, {Map<String, dynamic>? datosAdicionales}) {
    List<ResultadoDiagnostico> resultados = [];

    for (var diagnostico in _diagnosticos) {
      double probabilidad = _calcularProbabilidad(diagnostico, sintomasIds, datosAdicionales);
      
      if (probabilidad > 0.2) { // Umbral mínimo de relevancia
        List<String> sintomasDetectados = sintomasIds
            .where((s) => diagnostico.sintomasClave.contains(s))
            .toList();

        resultados.add(ResultadoDiagnostico(
          diagnostico: diagnostico,
          probabilidad: probabilidad,
          sintomasDetectados: sintomasDetectados,
          recomendaciones: _generarRecomendaciones(diagnostico, datosAdicionales),
        ));
      }
    }

    // Ordenar por probabilidad descendente
    resultados.sort((a, b) => b.probabilidad.compareTo(a.probabilidad));

    return resultados.take(5).toList(); // Top 5 diagnósticos
  }

  /// Calcula probabilidad basada en coincidencia de síntomas
  double _calcularProbabilidad(Diagnostico diagnostico, List<String> sintomasIds, Map<String, dynamic>? datos) {
    double probabilidad = diagnostico.probabilidadBase;
    
    // Síntomas coincidentes
    double pesoTotal = 0;
    double pesoCoincidente = 0;

    for (var sintomaId in diagnostico.sintomasClave) {
      var sintoma = _sintomas[sintomaId];
      if (sintoma != null) {
        pesoTotal += sintoma.peso;

        if (sintomasIds.contains(sintomaId)) {
          pesoCoincidente += sintoma.peso;
        }
      }
    }

    // Calcular factor de coincidencia
    if (pesoTotal > 0) {
      double factorCoincidencia = pesoCoincidente / pesoTotal;
      probabilidad *= (0.5 + factorCoincidencia);
    }

    // Ajustar por datos adicionales
    if (datos != null) {
      probabilidad = _ajustarPorDatosAdicionales(probabilidad, diagnostico, datos);
    }

    // Normalizar entre 0 y 1
    return probabilidad.clamp(0.0, 1.0);
  }

  /// Ajusta probabilidad según datos adicionales del paciente
  double _ajustarPorDatosAdicionales(double probabilidad, Diagnostico diagnostico, Map<String, dynamic> datos) {
    // Ajustes por edad
    if (datos.containsKey('edad')) {
      int edad = datos['edad'] as int;
      
      if (diagnostico.id == 'covid19' && edad > 60) {
        probabilidad *= 1.2; // Mayor riesgo en adultos mayores
      }
      
      if (diagnostico.id == 'dengue_sospecha' && edad < 15) {
        probabilidad *= 1.3; // Mayor riesgo en niños
      }
    }

    // Ajustes por temperatura
    if (datos.containsKey('temperatura')) {
      double temp = datos['temperatura'] as double;
      
      if (temp > 39.0) {
        // Fiebre alta aumenta probabilidad de infecciones severas
        if (diagnostico.nivelUrgencia == 'emergencia' || 
            diagnostico.nivelUrgencia == 'alta') {
          probabilidad *= 1.2;
        }
      }
    }

    // Ajustes por duración de síntomas
    if (datos.containsKey('dias_sintomas')) {
      int dias = datos['dias_sintomas'] as int;
      
      if (dias > 7 && diagnostico.id == 'resfriado_comun') {
        probabilidad *= 0.7; // Resfriado no dura tanto
      }
      
      if (dias > 3 && diagnostico.id == 'neumonia') {
        probabilidad *= 1.3; // Neumonía persistente es más probable
      }
    }

    return probabilidad.clamp(0.0, 1.0);
  }

  /// Genera recomendaciones personalizadas
  List<String> _generarRecomendaciones(Diagnostico diagnostico, Map<String, dynamic>? datos) {
    List<String> recomendaciones = [diagnostico.recomendacion];

    // Recomendaciones adicionales según datos
    if (datos != null) {
      if (datos.containsKey('temperatura')) {
        double temp = datos['temperatura'] as double;
        if (temp > 38.5) {
          recomendaciones.add('Fiebre alta detectada: Tomar líquidos abundantes y usar ropa ligera.');
        }
      }

      if (datos.containsKey('edad')) {
        int edad = datos['edad'] as int;
        if (edad > 60 || edad < 5) {
          recomendaciones.add('Edad de riesgo: Consultar médico incluso con síntomas leves.');
        }
      }
    }

    // Advertencias según nivel de urgencia
    switch (diagnostico.nivelUrgencia) {
      case 'emergencia':
        recomendaciones.add('⚠️ URGENCIA MÉDICA: Buscar atención médica inmediatamente.');
        break;
      case 'alta':
        recomendaciones.add('⚠️ Prioridad alta: Consultar médico hoy mismo.');
        break;
      case 'media':
        recomendaciones.add('Monitorear síntomas. Consultar médico si empeora en 24-48 horas.');
        break;
      case 'baja':
        recomendaciones.add('Cuidados en casa. Consultar si persiste más de una semana.');
        break;
    }

    return recomendaciones;
  }

  /// Obtiene todos los síntomas disponibles
  List<Sintoma> getSintomasDisponibles() {
    return _sintomas.values.toList();
  }

  /// Obtiene síntomas por categoría para facilitar la selección
  Map<String, List<Sintoma>> getSintomasPorCategoria() {
    return {
      'Generales': [
        _sintomas['fiebre']!,
        _sintomas['fatiga']!,
        _sintomas['dolor_muscular']!,
      ],
      'Respiratorios': [
        _sintomas['tos']!,
        _sintomas['tos_seca']!,
        _sintomas['tos_productiva']!,
        _sintomas['congestion_nasal']!,
        _sintomas['dolor_garganta']!,
        _sintomas['dificultad_respirar']!,
        _sintomas['dolor_pecho']!,
        _sintomas['estornudos']!,
      ],
      'Digestivos': [
        _sintomas['nauseas']!,
        _sintomas['vomito']!,
        _sintomas['diarrea']!,
        _sintomas['dolor_abdominal']!,
      ],
      'Cabeza': [
        _sintomas['dolor_cabeza']!,
        _sintomas['perdida_olfato']!,
        _sintomas['perdida_gusto']!,
      ],
      'Piel': [
        _sintomas['erupcion_cutanea']!,
        _sintomas['dolor_articulaciones']!,
      ],
    };
  }

  /// Valida que el análisis sea seguro (no reemplace médico real)
  String getDisclaimer() {
    return '''
⚠️ ADVERTENCIA IMPORTANTE:

Este sistema es una herramienta de orientación basada en reglas médicas generales. 
NO reemplaza la consulta con un profesional de la salud.

- Los resultados son estimaciones, no diagnósticos médicos oficiales
- Siempre consulte a un médico para diagnóstico y tratamiento adecuado
- En caso de emergencia, acuda inmediatamente al servicio de urgencias
- No ignore síntomas severos basándose solo en este análisis

Este sistema experto fue desarrollado para Yoltec como demostración de IA local.
    ''';
  }
}
