import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yoltec_mobile/models/user.dart';
import 'package:yoltec_mobile/services/api_service.dart';
import 'package:yoltec_mobile/services/biometric_service.dart';
import 'package:yoltec_mobile/services/notification_service.dart';

class AuthService extends ChangeNotifier {
  String? _token;
  User? _currentUser;
  bool _isLoading = false;
  bool _requiresBiometricUnlock = false;

  String? get token => _token;
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _token != null && _currentUser != null;

  /// True cuando hay token guardado pero el acceso biométrico está activado y
  /// el usuario aún no se ha autenticado con huella en esta sesión.
  bool get requiresBiometricUnlock => _requiresBiometricUnlock;

  AuthService() {
    _loadStoredAuth();
  }

  Future<void> _loadStoredAuth() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('user_data');

      final biometricEnabled = await BiometricService.isEnabled();
      final secureToken = await BiometricService.getStoredToken();

      if (secureToken != null && userJson != null) {
        if (biometricEnabled) {
          // Hay token guardado pero biometría activa: requiere autenticación
          _requiresBiometricUnlock = true;
          _currentUser = User.fromJson(
              json.decode(userJson) as Map<String, dynamic>);
        } else {
          // Biometría inactiva: restaurar sesión automáticamente
          _token = secureToken;
          _currentUser = User.fromJson(
              json.decode(userJson) as Map<String, dynamic>);
        }
      }
    } catch (e) {
      _token = null;
      _currentUser = null;
      _requiresBiometricUnlock = false;
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
        _requiresBiometricUnlock = false;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
            'user_data', json.encode(_currentUser!.toJson()));

        // Guardar token en almacenamiento seguro
        await BiometricService.storeToken(_token!);

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

  /// Restaura la sesión tras autenticación biométrica exitosa.
  Future<bool> loginWithBiometric() async {
    try {
      final secureToken = await BiometricService.getStoredToken();
      if (secureToken == null) return false;

      _token = secureToken;
      _requiresBiometricUnlock = false;
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> logout() async {
    _token = null;
    _currentUser = null;
    _requiresBiometricUnlock = false;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_data');

    await BiometricService.clearToken();

    notifyListeners();
  }
}
