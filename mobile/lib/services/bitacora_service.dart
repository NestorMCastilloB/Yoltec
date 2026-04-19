import 'package:flutter/foundation.dart';
import 'package:yoltec_mobile/models/bitacora.dart';
import 'package:yoltec_mobile/services/api_service.dart';
import 'package:yoltec_mobile/services/offline_cache_service.dart';

class BitacoraService extends ChangeNotifier {
  List<Bitacora> _bitacoras = [];
  bool _isLoading = false;
  String? _error;
  bool _isOffline = false;

  List<Bitacora> get bitacoras => _bitacoras;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isOffline => _isOffline;

  Future<void> cargarBitacoras(String token,
      {String? fechaDesde, String? fechaHasta, String? alumno}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final params = <String, String>{};
      if (fechaDesde != null && fechaDesde.isNotEmpty) params['fecha_desde'] = fechaDesde;
      if (fechaHasta != null && fechaHasta.isNotEmpty) params['fecha_hasta'] = fechaHasta;
      if (alumno != null && alumno.isNotEmpty) params['alumno'] = alumno;

      final query = params.isEmpty
          ? '/bitacoras'
          : '/bitacoras?${params.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&')}';

      final data = await ApiService.get(query, token: token);
      final lista = data['bitacoras'] as List<dynamic>? ?? [];
      _bitacoras = lista.map((e) => Bitacora.fromJson(e as Map<String, dynamic>)).toList();
      _isOffline = false;
      if (params.isEmpty) await OfflineCacheService.guardar('bitacoras', data);
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      final cached = await OfflineCacheService.cargar('bitacoras');
      if (cached != null) {
        final lista = cached['bitacoras'] as List<dynamic>? ?? [];
        _bitacoras = lista.map((e) => Bitacora.fromJson(e as Map<String, dynamic>)).toList();
        _isOffline = true;
      } else {
        _error = 'Sin conexión y sin datos guardados.';
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
