import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yoltec_mobile/models/user.dart';
import 'package:yoltec_mobile/services/api_service.dart';
import 'package:yoltec_mobile/services/notification_service.dart';

class AuthService extends ChangeNotifier {
  String? _token;
  User? _currentUser;
  bool _isLoading = false;

  String? get token => _token;
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _token != null && _currentUser != null;

  AuthService() {
    _loadStoredAuth();
  }

  Future<void> _loadStoredAuth() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('auth_token');

      if (_token != null) {
        final userJson = prefs.getString('user_data');
        if (userJson != null) {
          _currentUser = User.fromJson(
              json.decode(userJson) as Map<String, dynamic>);
        }
      }
    } catch (e) {
      _token = null;
      _currentUser = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Login para alumno o doctor.
  /// [identificador] es el numero de control (alumno) o username (doctor).
  /// [tipoUsuario] es 'alumno' o 'doctor'.
  Future<Map<String, dynamic>> login(
    String identificador,
    String password,
    String tipoUsuario,
  ) async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await ApiService.post('/login', {
        'identificador': identificador,
        'password': password,
        'tipo_usuario': tipoUsuario,
      });

      if (data['token'] != null) {
        _token = data['token'] as String;
        _currentUser =
            User.fromJson(data['user'] as Map<String, dynamic>);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', _token!);
        await prefs.setString(
            'user_data', json.encode(_currentUser!.toJson()));

        // Registrar token FCM en el backend
        final fcmToken = await NotificationService.getToken();
        if (fcmToken != null) {
          try {
            await ApiService.post('/fcm-token', {'fcm_token': fcmToken});
          } catch (_) {}
        }

        _isLoading = false;
        notifyListeners();
        return {
          'success': true,
          'message': data['message'] ?? 'Sesion iniciada'
        };
      }

      _isLoading = false;
      notifyListeners();
      return {
        'success': false,
        'message': data['message'] ?? 'Credenciales incorrectas',
      };
    } on ApiException catch (e) {
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': e.message};
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return {
        'success': false,
        'message': 'Error de conexion. Verifica tu red.',
      };
    }
  }

  Future<void> logout() async {
    _token = null;
    _currentUser = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_data');

    notifyListeners();
  }
}
