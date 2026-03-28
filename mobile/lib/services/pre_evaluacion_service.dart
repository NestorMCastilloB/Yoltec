import 'package:flutter/foundation.dart';
import 'package:yoltec_mobile/services/api_service.dart';

class PreEvaluacionService extends ChangeNotifier {
  List<Map<String, dynamic>> _preguntas = [];
  List<Map<String, dynamic>> _pendientes = [];
  Map<int, Map<String, dynamic>> _porCita = {};
  bool _isLoading = false;
  String? _error;

  List<Map<String, dynamic>> get preguntas => _preguntas;
  List<Map<String, dynamic>> get pendientes => _pendientes;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Map<String, dynamic>? getPreEvaluacionDeCita(int citaId) =>
      _porCita[citaId];

  Future<void> cargarPreguntas(String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data =
          await ApiService.get('/pre-evaluacion/preguntas', token: token);
      final lista = data['preguntas'] as List<dynamic>? ?? [];
      _preguntas = lista.cast<Map<String, dynamic>>();
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Error al cargar preguntas.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> cargarPendientes(String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data =
          await ApiService.get('/pre-evaluacion/pendientes', token: token);
      final lista = data['pendientes'] as List<dynamic>? ?? [];
      _pendientes = lista.cast<Map<String, dynamic>>();
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Error al cargar pre-evaluaciones.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> buscarPreEvaluacionDeCita(
      String token, int citaId) async {
    try {
      final data = await ApiService.get('/pre-evaluacion', token: token);
      final lista = data['pre_evaluaciones'] as List<dynamic>? ?? [];
      for (final item in lista) {
        final map = item as Map<String, dynamic>;
        if (map['cita_id'] == citaId) return map;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<bool> validarPreEvaluacion(
      String token, int preEvaluacionId, String accion) async {
    try {
      await ApiService.post(
        '/pre-evaluacion/$preEvaluacionId/validar',
        {'accion': accion},
        token: token,
      );
      _pendientes.removeWhere((p) => p['id'] == preEvaluacionId);
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Error al validar la pre-evaluacion.';
      notifyListeners();
      return false;
    }
  }

  Future<Map<String, dynamic>?> enviarRespuestas(
    String token,
    int citaId,
    Map<String, dynamic> respuestas,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await ApiService.post(
        '/pre-evaluacion',
        {
          'cita_id': citaId,
          'respuestas': respuestas,
        },
        token: token,
      );
      _isLoading = false;
      notifyListeners();
      return data;
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      _error = 'Error al enviar respuestas.';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
