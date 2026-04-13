import 'package:flutter/foundation.dart';
import 'package:yoltec_mobile/models/bitacora.dart';
import 'package:yoltec_mobile/services/api_service.dart';

class BitacoraService extends ChangeNotifier {
  List<Bitacora> _bitacoras = [];
  bool _isLoading = false;
  String? _error;

  List<Bitacora> get bitacoras => _bitacoras;
  bool get isLoading => _isLoading;
  String? get error => _error;

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
      _bitacoras = lista
          .map((e) => Bitacora.fromJson(e as Map<String, dynamic>))
          .toList();
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Error al cargar bitacoras.';
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
