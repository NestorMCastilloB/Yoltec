import 'package:flutter/foundation.dart';
import 'package:yoltec_mobile/services/api_service.dart';

class RecetaService extends ChangeNotifier {
  List<Map<String, dynamic>> _recetas = [];
  bool _isLoading = false;
  String? _error;

  List<Map<String, dynamic>> get recetas => _recetas;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> cargarRecetas(String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await ApiService.get('/recetas', token: token);
      final lista = data['recetas'] as List<dynamic>? ?? [];
      _recetas = lista.cast<Map<String, dynamic>>();
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Error al cargar recetas.';
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
