import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yoltec_mobile/models/user.dart';

class ApiConfig {
  // Para desarrollo local
  static const String baseUrl = 'http://localhost:8000/api';
  
  // Para producción con ngrok (cambiar cuando se use)
  // static const String baseUrl = 'https://shara-isospondylous-capitally.ngrok-free.dev/api';
  
  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
}

class AuthService extends ChangeNotifier {
  String? _token;
  String? _tempToken; // Token temporal para 2FA
  User? _currentUser;
  bool _isLoading = false;
  bool _requires2FA = false;
  String? _maskedEmail;

  // Getters
  String? get token => _token;
  String? get tempToken => _tempToken;
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _token != null && _currentUser != null;
  bool get requires2FA => _requires2FA;
  String? get maskedEmail => _maskedEmail;

  AuthService() {
    _loadStoredAuth();
  }

  /// Carga autenticación guardada
  Future<void> _loadStoredAuth() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('auth_token');
      
      if (_token != null) {
        final userJson = prefs.getString('user_data');
        if (userJson != null) {
          _currentUser = User.fromJson(json.decode(userJson));
        }
      }
    } catch (e) {
      print('Error cargando auth: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Login con soporte para 2FA
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      _isLoading = true;
      _requires2FA = false;
      notifyListeners();

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/login'),
        headers: ApiConfig.headers,
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        // Verificar si requiere 2FA
        if (data['requires_2fa'] == true) {
          _requires2FA = true;
          _tempToken = data['temp_token'];
          _maskedEmail = data['masked_email'];
          _isLoading = false;
          notifyListeners();
          return {
            'success': true,
            'requires_2fa': true,
            'message': data['message'] ?? 'Se ha enviado un código de verificación'
          };
        }

        // Login directo (sin 2FA)
        if (data['token'] != null) {
          await _completeLogin(data);
          return {'success': true, 'requires_2fa': false, 'message': 'Login exitoso'};
        }
      }

      _isLoading = false;
      notifyListeners();
      return {
        'success': false,
        'message': data['message'] ?? 'Credenciales incorrectas'
      };
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return {
        'success': false,
        'message': 'Error de conexión: $e'
      };
    }
  }

  /// Verificar código 2FA
  Future<Map<String, dynamic>> verify2FA(String code) async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/verify-2fa'),
        headers: ApiConfig.headers,
        body: json.encode({
          'temp_token': _tempToken,
          'code': code,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['token'] != null) {
        await _completeLogin(data);
        _requires2FA = false;
        _tempToken = null;
        _maskedEmail = null;
        return {'success': true, 'message': 'Verificación exitosa'};
      } else {
        _isLoading = false;
        notifyListeners();
        return {
          'success': false,
          'message': data['message'] ?? 'Código incorrecto o expirado'
        };
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return {
        'success': false,
        'message': 'Error de conexión: $e'
      };
    }
  }

  /// Reenviar código 2FA
  Future<Map<String, dynamic>> resend2FA() async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/resend-2fa'),
        headers: ApiConfig.headers,
        body: json.encode({
          'temp_token': _tempToken,
        }),
      );

      final data = json.decode(response.body);

      return {
        'success': response.statusCode == 200,
        'message': data['message'] ?? 'Error al reenviar código'
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión: $e'
      };
    }
  }

  /// Completar login después de verificación
  Future<void> _completeLogin(Map<String, dynamic> data) async {
    _token = data['token'];
    
    if (data['user'] != null) {
      _currentUser = User.fromJson(data['user']);
    }

    // Guardar en almacenamiento local
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', _token!);
    if (_currentUser != null) {
      await prefs.setString('user_data', json.encode(_currentUser!.toJson()));
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Logout
  Future<void> logout() async {
    try {
      if (_token != null) {
        await http.post(
          Uri.parse('${ApiConfig.baseUrl}/logout'),
          headers: {
            ...ApiConfig.headers,
            'Authorization': 'Bearer $_token',
          },
        );
      }
    } catch (e) {
      print('Error en logout: $e');
    } finally {
      _token = null;
      _tempToken = null;
      _currentUser = null;
      _requires2FA = false;
      _maskedEmail = null;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('user_data');
      
      notifyListeners();
    }
  }

  /// Obtener headers con autorización
  Map<String, String> getAuthHeaders() {
    return {
      ...ApiConfig.headers,
      if (_token != null) 'Authorization': 'Bearer $_token',
    };
  }
}
