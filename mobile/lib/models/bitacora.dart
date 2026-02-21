import 'package:json_annotation/json_annotation.dart';
import 'package:yoltec_mobile/models/cita.dart';
import 'package:yoltec_mobile/models/user.dart';

part 'bitacora.g.dart';

@JsonSerializable()
class Bitacora {
  final int id;
  final int citaId;
  final String? diagnostico;
  final String? tratamiento;
  final String? observaciones;
  final String? peso;
  final String? altura;
  final String? temperatura;
  final String? presionArterial;
  final User? alumno;
  final User? doctor;
  final Cita? cita;
  final DateTime createdAt;

  Bitacora({
    required this.id,
    required this.citaId,
    this.diagnostico,
    this.tratamiento,
    this.observaciones,
    this.peso,
    this.altura,
    this.temperatura,
    this.presionArterial,
    this.alumno,
    this.doctor,
    this.cita,
    required this.createdAt,
  });

  factory Bitacora.fromJson(Map<String, dynamic> json) => _$BitacoraFromJson(json);
  Map<String, dynamic> toJson() => _$BitacoraToJson(this);

  String get fechaFormateada {
    return '${createdAt.day.toString().padLeft(2, '0')}/'
           '${createdAt.month.toString().padLeft(2, '0')}/'
           '${createdAt.year}';
  }
}
