class Receta {
  final int id;
  final int citaId;
  final int doctorId;
  final List<Medicamento> medicamentos;
  final String indicaciones;
  final String fechaEmision;
  final String? doctorNombre;

  const Receta({
    required this.id,
    required this.citaId,
    required this.doctorId,
    required this.medicamentos,
    required this.indicaciones,
    required this.fechaEmision,
    this.doctorNombre,
  });

  factory Receta.fromJson(Map<String, dynamic> json) {
    final meds = json['medicamentos'];
    List<Medicamento> medicamentos = [];
    if (meds is List) {
      medicamentos = meds
          .map((m) => Medicamento.fromJson(m as Map<String, dynamic>))
          .toList();
    }

    final doctor = json['doctor'] as Map<String, dynamic>?;
    String? doctorNombre;
    if (doctor != null) {
      final nombre = doctor['nombre'] as String? ?? '';
      final apellido = doctor['apellido'] as String? ?? '';
      doctorNombre = '$nombre $apellido'.trim();
    }

    return Receta(
      id: json['id'] as int,
      citaId: json['cita_id'] as int? ?? 0,
      doctorId: json['doctor_id'] as int? ?? 0,
      medicamentos: medicamentos,
      indicaciones: json['indicaciones'] as String? ?? '',
      fechaEmision: json['fecha_emision'] as String? ?? '',
      doctorNombre: doctorNombre,
    );
  }

  String get fechaFormateada {
    final parts = fechaEmision.split('-');
    if (parts.length == 3) {
      return '${parts[2]}/${parts[1]}/${parts[0]}';
    }
    return fechaEmision;
  }
}

class Medicamento {
  final String nombre;
  final String dosis;
  final String frecuencia;
  final String duracion;

  const Medicamento({
    required this.nombre,
    required this.dosis,
    required this.frecuencia,
    required this.duracion,
  });

  factory Medicamento.fromJson(Map<String, dynamic> json) {
    return Medicamento(
      nombre: json['nombre'] as String? ?? '',
      dosis: json['dosis'] as String? ?? '',
      frecuencia: json['frecuencia'] as String? ?? '',
      duracion: json['duracion'] as String? ?? '',
    );
  }
}
