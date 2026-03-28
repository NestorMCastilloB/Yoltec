import 'package:flutter/foundation.dart';
import 'package:yoltec_mobile/services/api_service.dart';

class IAPriorityService extends ChangeNotifier {
  Map<String, dynamic>? _resumen;
  bool _isLoading = false;
  String? _error;

  Map<String, dynamic>? get resumen => _resumen;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<dynamic> get citasAlta =>
      (_resumen?['alta'] as List<dynamic>?) ?? [];
  List<dynamic> get citasMedia =>
      (_resumen?['media'] as List<dynamic>?) ?? [];
  List<dynamic> get citasBaja =>
      (_resumen?['baja'] as List<dynamic>?) ?? [];

  Future<void> cargarPrioridades(String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data =
          await ApiService.get('/ia/priority/pendientes', token: token);
      _resumen = data;
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Error al cargar clasificacion de prioridad.';
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
