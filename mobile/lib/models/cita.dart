class Cita {
  final int id;
  final String claveCita;
  final String fechaCita;
  final String horaCita;
  final String motivo;
  final String estatus;
  final int? alumnoId;
  final Map<String, dynamic>? alumno;

  const Cita({
    required this.id,
    required this.claveCita,
    required this.fechaCita,
    required this.horaCita,
    required this.motivo,
    required this.estatus,
    this.alumnoId,
    this.alumno,
  });

  bool get isProgramada => estatus == 'programada';
  bool get isAtendida => estatus == 'atendida';
  bool get isCancelada => estatus == 'cancelada';

  String get fechaFormateada {
    final parts = fechaCita.split('-');
    if (parts.length == 3) {
      return '${parts[2]}/${parts[1]}/${parts[0]}';
    }
    return fechaCita;
  }

  String get horaFormateada {
    // Convierte "08:00:00" → "08:00"
    if (horaCita.length >= 5) {
      return horaCita.substring(0, 5);
    }
    return horaCita;
  }

  bool get isNoAsistio => estatus == 'no_asistio';

  String get estatusTexto {
    switch (estatus) {
      case 'programada':
        return 'Programada';
      case 'atendida':
        return 'Atendida';
      case 'cancelada':
        return 'Cancelada';
      case 'no_asistio':
        return 'No asistió';
      default:
        return estatus;
    }
  }

  String get nombreAlumno {
    if (alumno == null) return 'Sin información';
    final nombre = alumno!['nombre'] as String? ?? '';
    final apellido = alumno!['apellido'] as String? ?? '';
    return '$nombre $apellido'.trim();
  }

  factory Cita.fromJson(Map<String, dynamic> json) {
    return Cita(
      id: json['id'] as int,
      claveCita: json['clave_cita'] as String? ?? '',
      fechaCita: json['fecha_cita'] as String? ?? '',
      horaCita: json['hora_cita'] as String? ?? '',
      motivo: json['motivo'] as String? ?? '',
      estatus: json['estatus'] as String? ?? 'programada',
      alumnoId: json['alumno_id'] as int?,
      alumno: json['alumno'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clave_cita': claveCita,
      'fecha_cita': fechaCita,
      'hora_cita': horaCita,
      'motivo': motivo,
      'estatus': estatus,
      'alumno_id': alumnoId,
      'alumno': alumno,
    };
  }
}
