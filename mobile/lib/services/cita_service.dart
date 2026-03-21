import 'package:flutter/foundation.dart';
import 'package:yoltec_mobile/models/cita.dart';
import 'package:yoltec_mobile/services/api_service.dart';

class CitaService extends ChangeNotifier {
  List<Cita> _citas = [];
  bool _isLoading = false;
  String? _error;

  List<Cita> get citas => _citas;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<Cita> get citasProgramadas =>
      _citas.where((c) => c.isProgramada).toList();

  Cita? get proximaCita {
    final programadas = citasProgramadas;
    if (programadas.isEmpty) return null;
    programadas.sort((a, b) {
      final fechaA = '${a.fechaCita} ${a.horaCita}';
      final fechaB = '${b.fechaCita} ${b.horaCita}';
      return fechaA.compareTo(fechaB);
    });
    return programadas.first;
  }

  Future<void> cargarCitas(String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await ApiService.get('/citas', token: token);
      final lista = data['citas'] as List<dynamic>? ?? [];
      _citas = lista
          .map((e) => Cita.fromJson(e as Map<String, dynamic>))
          .toList();
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Error al cargar citas.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Cita?> crearCita(
    String token, {
    required String fechaCita,
    required String horaCita,
    required String motivo,
  }) async {
    try {
      final data = await ApiService.post(
        '/citas',
        {
          'fecha_cita': fechaCita,
          'hora_cita': horaCita,
          'motivo': motivo,
        },
        token: token,
      );
      final cita = Cita.fromJson(data['cita'] as Map<String, dynamic>);
      _citas.add(cita);
      notifyListeners();
      return cita;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return null;
    } catch (e) {
      _error = 'Error al crear la cita.';
      notifyListeners();
      return null;
    }
  }

  Future<bool> cancelarCita(String token, int citaId) async {
    try {
      await ApiService.post('/citas/$citaId/cancelar', {}, token: token);
      final idx = _citas.indexWhere((c) => c.id == citaId);
      if (idx != -1) {
        final original = _citas[idx];
        _citas[idx] = Cita(
          id: original.id,
          claveCita: original.claveCita,
          fechaCita: original.fechaCita,
          horaCita: original.horaCita,
          motivo: original.motivo,
          estatus: 'cancelada',
          alumnoId: original.alumnoId,
          alumno: original.alumno,
        );
        notifyListeners();
      }
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Error al cancelar la cita.';
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
