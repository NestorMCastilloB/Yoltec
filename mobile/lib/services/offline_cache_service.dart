import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Servicio de caché offline — guarda y restaura respuestas JSON del API.
/// Cada entrada expira después de [_ttlHours] horas.
class OfflineCacheService {
  static const String _prefix = 'cache_';
  static const String _tsPrefix = 'cache_ts_';
  static const int _ttlHours = 24;

  static Future<void> guardar(String clave, Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_prefix$clave', jsonEncode(data));
    await prefs.setInt(
        '$_tsPrefix$clave', DateTime.now().millisecondsSinceEpoch);
  }

  static Future<Map<String, dynamic>?> cargar(String clave) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_prefix$clave');
    if (raw == null) return null;

    // Verificar expiración
    final ts = prefs.getInt('$_tsPrefix$clave');
    if (ts != null) {
      final guardado = DateTime.fromMillisecondsSinceEpoch(ts);
      if (DateTime.now().difference(guardado).inHours > _ttlHours) {
        await limpiar(clave);
        return null;
      }
    }

    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static Future<void> limpiar(String clave) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_prefix$clave');
    await prefs.remove('$_tsPrefix$clave');
  }
}
