import 'package:flutter/foundation.dart';
import 'package:yoltec_mobile/services/api_service.dart';
import 'package:yoltec_mobile/services/offline_cache_service.dart';

class RecetaService extends ChangeNotifier {
  List<Map<String, dynamic>> _recetas = [];
  bool _isLoading = false;
  String? _error;
  bool _isOffline = false;

  List<Map<String, dynamic>> get recetas => _recetas;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isOffline => _isOffline;

  Future<void> cargarRecetas(String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await ApiService.get('/recetas', token: token);
      final lista = data['recetas'] as List<dynamic>? ?? [];
      _recetas = lista.cast<Map<String, dynamic>>();
      _isOffline = false;
      await OfflineCacheService.guardar('recetas', data);
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      final cached = await OfflineCacheService.cargar('recetas');
      if (cached != null) {
        final lista = cached['recetas'] as List<dynamic>? ?? [];
        _recetas = lista.cast<Map<String, dynamic>>();
        _isOffline = true;
      } else {
        _error = 'Sin conexión y sin datos guardados.';
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> crearReceta(String token, {
    required int citaId,
    required List<Map<String, dynamic>> medicamentos,
    required String indicaciones,
    required String fechaEmision,
  }) async {
    try {
      final data = await ApiService.post('/recetas', {
        'cita_id': citaId,
        'medicamentos': medicamentos,
        'indicaciones': indicaciones,
        'fecha_emision': fechaEmision,
      }, token: token);
      final nueva = data['receta'] as Map<String, dynamic>?;
      if (nueva != null) {
        _recetas.insert(0, nueva);
        notifyListeners();
      }
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Error al crear la receta.';
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
