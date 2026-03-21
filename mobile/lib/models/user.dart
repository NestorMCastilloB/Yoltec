class User {
  final int id;
  final String nombre;
  final String apellido;
  final String email;
  final String tipo;
  final String? numeroControl;
  final String? username;

  const User({
    required this.id,
    required this.nombre,
    required this.apellido,
    required this.email,
    required this.tipo,
    this.numeroControl,
    this.username,
  });

  bool get esAlumno => tipo == 'alumno';
  bool get esDoctor => tipo == 'doctor';
  String get nombreCompleto => '$nombre $apellido';

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      nombre: json['nombre'] as String? ?? '',
      apellido: json['apellido'] as String? ?? '',
      email: json['email'] as String? ?? '',
      tipo: json['tipo'] as String? ?? 'alumno',
      numeroControl: json['numero_control'] as String?,
      username: json['username'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'apellido': apellido,
      'email': email,
      'tipo': tipo,
      'numero_control': numeroControl,
      'username': username,
    };
  }
}
