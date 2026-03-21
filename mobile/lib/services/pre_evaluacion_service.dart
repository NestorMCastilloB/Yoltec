import 'package:flutter/foundation.dart';
import 'package:yoltec_mobile/services/api_service.dart';

class PreEvaluacionService extends ChangeNotifier {
  List<Map<String, dynamic>> _preguntas = [];
  bool _isLoading = false;
  String? _error;

  List<Map<String, dynamic>> get preguntas => _preguntas;
  bool get isLoading => _isLoading;
  String? get error => _error;

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
