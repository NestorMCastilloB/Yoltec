import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

class BiometricService {
  static final _auth = LocalAuthentication();
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _keyEnabled = 'biometric_enabled';
  static const _keyToken = 'secure_auth_token';

  /// Verifica si el dispositivo soporta biometría y tiene alguna registrada.
  static Future<bool> isAvailable() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      return canCheck && isSupported;
    } catch (_) {
      return false;
    }
  }

  /// Verifica si el usuario activó el acceso biométrico.
  static Future<bool> isEnabled() async {
    final val = await _storage.read(key: _keyEnabled);
    return val == 'true';
  }

  /// Activa o desactiva el acceso biométrico.
  static Future<void> setEnabled(bool enabled) async {
    await _storage.write(key: _keyEnabled, value: enabled.toString());
  }

  /// Guarda el token de forma segura.
  static Future<void> storeToken(String token) async {
    await _storage.write(key: _keyToken, value: token);
  }

  /// Obtiene el token guardado.
  static Future<String?> getStoredToken() async {
    return _storage.read(key: _keyToken);
  }

  /// Elimina el token guardado.
  static Future<void> clearToken() async {
    await _storage.delete(key: _keyToken);
  }

  /// Muestra el diálogo de autenticación biométrica.
  /// Retorna true si el usuario se autenticó exitosamente.
  static Future<bool> authenticate() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Usa tu huella para acceder a Yoltec',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
    } catch (_) {
      return false;
    }
  }
}
