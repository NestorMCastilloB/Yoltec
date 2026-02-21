import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

@JsonSerializable()
class User {
  final int id;
  final String nombre;
  final String apellido;
  final String email;
  final String numeroControl;
  final String rol;
  final String? telefono;
  final String? carrera;
  final String? semestre;
  final String? especialidad;
  final String? cedulaProfesional;

  User({
    required this.id,
    required this.nombre,
    required this.apellido,
    required this.email,
    required this.numeroControl,
    required this.rol,
    this.telefono,
    this.carrera,
    this.semestre,
    this.especialidad,
    this.cedulaProfesional,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);

  String get nombreCompleto => '$nombre $apellido';
  
  bool get esDoctor => rol == 'doctor';
  bool get esAlumno => rol == 'alumno';
}
