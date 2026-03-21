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

  Future<void> cargarBitacoras(String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await ApiService.get('/bitacoras', token: token);
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
