class Bitacora {
  final int id;
  final String fechaConsulta;
  final String? diagnostico;
  final String? tratamiento;
  final String? observaciones;
  final String? peso;
  final String? talla;
  final String? presionArterial;
  final String? temperatura;
  final Map<String, dynamic>? alumno;
  final Map<String, dynamic>? doctor;

  const Bitacora({
    required this.id,
    required this.fechaConsulta,
    this.diagnostico,
    this.tratamiento,
    this.observaciones,
    this.peso,
    this.talla,
    this.presionArterial,
    this.temperatura,
    this.alumno,
    this.doctor,
  });

  String get fechaFormateada {
    final parts = fechaConsulta.split('-');
    if (parts.length == 3) {
      return '${parts[2]}/${parts[1]}/${parts[0]}';
    }
    return fechaConsulta;
  }

  String get nombreDoctor {
    if (doctor == null) return 'Sin asignar';
    final nombre = doctor!['nombre'] as String? ?? '';
    final apellido = doctor!['apellido'] as String? ?? '';
    return '$nombre $apellido'.trim();
  }

  factory Bitacora.fromJson(Map<String, dynamic> json) {
    return Bitacora(
      id: json['id'] as int,
      fechaConsulta: json['fecha_consulta'] as String? ??
          json['created_at'] as String? ?? '',
      diagnostico: json['diagnostico'] as String?,
      tratamiento: json['tratamiento'] as String?,
      observaciones: json['observaciones'] as String?,
      peso: json['peso']?.toString(),
      talla: json['talla']?.toString(),
      presionArterial: json['presion_arterial'] as String?,
      temperatura: json['temperatura']?.toString(),
      alumno: json['alumno'] as Map<String, dynamic>?,
      doctor: json['doctor'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fecha_consulta': fechaConsulta,
      'diagnostico': diagnostico,
      'tratamiento': tratamiento,
      'observaciones': observaciones,
      'peso': peso,
      'talla': talla,
      'presion_arterial': presionArterial,
      'temperatura': temperatura,
      'alumno': alumno,
      'doctor': doctor,
    };
  }
}
