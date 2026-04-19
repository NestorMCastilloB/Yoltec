import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Servicio de caché offline — guarda y restaura respuestas JSON del API.
class OfflineCacheService {
  static const String _prefix = 'cache_';

  static Future<void> guardar(String clave, Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_prefix$clave', jsonEncode(data));
  }

  static Future<Map<String, dynamic>?> cargar(String clave) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_prefix$clave');
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static Future<void> limpiar(String clave) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_prefix$clave');
  }
}
