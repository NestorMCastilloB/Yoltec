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
  User? _currentUser;
  bool _isLoading = false;

  // Getters
  String? get token => _token;
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _token != null && _currentUser != null;

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

  /// Login
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/login'),
        headers: ApiConfig.headers,
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['token'] != null) {
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

        notifyListeners();
        return {'success': true, 'message': 'Login exitoso'};
      } else {
        return {
          'success': false, 
          'message': data['message'] ?? 'Credenciales incorrectas'
        };
      }
    } catch (e) {
      return {
        'success': false, 
        'message': 'Error de conexión: $e'
      };
    }
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
      _currentUser = null;
      
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
