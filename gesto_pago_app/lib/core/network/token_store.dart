import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Acceso a tokens de sesión en el almacenamiento seguro del dispositivo
/// (Keychain / Keystore). Nunca en preferencias planas.
class TokenStore {
  const TokenStore(this._storage);

  static const _keyAccessToken = 'access_token';
  static const _keyRefreshToken = 'refresh_token';
  static const _keyNombre = 'session_nombre';
  static const _keyEmail = 'session_email';

  final FlutterSecureStorage _storage;

  Future<void> save({
    required String accessToken,
    required String refreshToken,
    required String nombre,
    required String email,
  }) async {
    await _storage.write(key: _keyAccessToken, value: accessToken);
    await _storage.write(key: _keyRefreshToken, value: refreshToken);
    await _storage.write(key: _keyNombre, value: nombre);
    await _storage.write(key: _keyEmail, value: email);
  }

  Future<String?> readAccessToken() => _storage.read(key: _keyAccessToken);

  Future<String?> readRefreshToken() => _storage.read(key: _keyRefreshToken);

  Future<String?> readNombre() => _storage.read(key: _keyNombre);

  Future<String?> readEmail() => _storage.read(key: _keyEmail);

  Future<void> clear() async {
    await _storage.delete(key: _keyAccessToken);
    await _storage.delete(key: _keyRefreshToken);
    await _storage.delete(key: _keyNombre);
    await _storage.delete(key: _keyEmail);
  }
}