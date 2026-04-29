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
      final userJson = prefs.getString('user_data');
      final storedToken = prefs.getString('auth_token');

      if (storedToken != null && userJson != null) {
        final tokenValid = await _verifyToken(storedToken);
        if (!tokenValid) {
          await prefs.remove('user_data');
          await prefs.remove('auth_token');
        } else {
          _token = storedToken;
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

  /// Login con credenciales (usuario + contraseña).
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
        await prefs.setString(
            'user_data', json.encode(_currentUser!.toJson()));
        await prefs.setString('auth_token', _token!);

        // Registrar token FCM en el backend
        final fcmToken = await NotificationService.getToken();
        if (fcmToken != null) {
          try {
            await ApiService.post('/fcm-token', {'fcm_token': fcmToken},
                token: _token);
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

  Future<bool> _verifyToken(String token) async {
    try {
      await ApiService.get('/user', token: token);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> logout() async {
    _token = null;
    _currentUser = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_data');
    await prefs.remove('auth_token');

    notifyListeners();
  }
}
