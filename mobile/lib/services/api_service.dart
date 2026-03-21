import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {
  // Para emulador Android: 10.0.2.2 apunta al localhost de la PC
  // Para celular físico (WiFi): usar IP local de la PC (ej: 192.168.1.73)
  static const String baseUrl = 'http://10.0.2.2:8000/api';

  static Map<String, String> _headers({String? token}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  static Future<Map<String, dynamic>> get(
    String endpoint, {
    String? token,
  }) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl$endpoint'),
            headers: _headers(token: token),
          )
          .timeout(const Duration(seconds: 15));

      return _handleResponse(response);
    } on SocketException {
      throw ApiException('Sin conexión a internet. Verifica tu red.');
    } on HttpException {
      throw ApiException('Error de servidor. Intenta más tarde.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Error inesperado: $e');
    }
  }

  static Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> body, {
    String? token,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl$endpoint'),
            headers: _headers(token: token),
            body: json.encode(body),
          )
          .timeout(const Duration(seconds: 15));

      return _handleResponse(response);
    } on SocketException {
      throw ApiException('Sin conexión a internet. Verifica tu red.');
    } on HttpException {
      throw ApiException('Error de servidor. Intenta más tarde.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Error inesperado: $e');
    }
  }

  static Map<String, dynamic> _handleResponse(http.Response response) {
    final body = utf8.decode(response.bodyBytes);
    Map<String, dynamic> data;

    try {
      data = json.decode(body);
    } catch (_) {
      throw ApiException('Respuesta inválida del servidor.');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    }

    final message = data['message'] as String?;

    switch (response.statusCode) {
      case 401:
        throw ApiException(message ?? 'Credenciales incorrectas o sesión expirada.');
      case 403:
        throw ApiException(message ?? 'No tienes permiso para realizar esta acción.');
      case 404:
        throw ApiException(message ?? 'Recurso no encontrado.');
      case 422:
        final errors = data['errors'];
        if (errors is Map) {
          final firstError = (errors.values.first as List).first as String;
          throw ApiException(firstError);
        }
        throw ApiException(message ?? 'Datos inválidos.');
      case 500:
        throw ApiException('Error interno del servidor. Intenta más tarde.');
      default:
        throw ApiException(message ?? 'Error desconocido (${response.statusCode}).');
    }
  }
}

class ApiException implements Exception {
  final String message;
  const ApiException(this.message);

  @override
  String toString() => message;
}
