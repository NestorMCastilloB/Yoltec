import 'package:json_annotation/json_annotation.dart';
import 'package:yoltec_mobile/models/user.dart';

part 'cita.g.dart';

@JsonSerializable()
class Cita {
  final int id;
  final String fechaCita;
  final String horaCita;
  final String? motivo;
  final String estatus;
  final User? alumno;
  final User? doctor;
  final DateTime? createdAt;

  Cita({
    required this.id,
    required this.fechaCita,
    required this.horaCita,
    this.motivo,
    required this.estatus,
    this.alumno,
    this.doctor,
    this.createdAt,
  });

  factory Cita.fromJson(Map<String, dynamic> json) => _$CitaFromJson(json);
  Map<String, dynamic> toJson() => _$CitaToJson(this);

  bool get isPendiente => estatus == 'programada';
  bool get isAtendida => estatus == 'atendida';
  bool get isCancelada => estatus == 'cancelada';

  String get fechaFormateada {
    final parts = fechaCita.split('-');
    if (parts.length == 3) {
      return '${parts[2]}/${parts[1]}/${parts[0]}';
    }
    return fechaCita;
  }
}
