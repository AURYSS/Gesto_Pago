import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/app_exception.dart';
import '../../auth/domain/auth_session.dart';

class LoginResponse {
  const LoginResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.expiresIn,
    required this.nombre,
    required this.roles,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    final accessToken = json['accessToken'];
    final refreshToken = json['refreshToken'];
    final nombre = json['nombre'] ?? '';
    if (accessToken is! String || refreshToken is! String) {
      throw const SerializationException('Respuesta de login inválida.');
    }
    return LoginResponse(
      accessToken: accessToken,
      refreshToken: refreshToken,
      tokenType: json['tokenType'] as String? ?? 'Bearer',
      expiresIn: (json['expiresIn'] as num?)?.toInt() ?? 0,
      nombre: nombre is String ? nombre : '',
      roles: (json['roles'] as List?)?.whereType<String>().toList() ?? const [],
    );
  }

  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final int expiresIn;
  final String nombre;
  final List<String> roles;

  AuthSession toSession(String email) => AuthSession(
        email: email,
        nombre: nombre,
        accessToken: accessToken,
        refreshToken: refreshToken,
        roles: roles,
      );
}

/// Llamadas HTTP de autenticación contra el backend de la aplicación.
class AuthRemote {
  AuthRemote(this._dio);

  final Dio _dio;

  Future<LoginResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {'email': email.trim().toLowerCase(), 'password': password},
      );
      return LoginResponse.fromJson(_mapJson(response.data, 'login'));
    } catch (e) {
      throw ApiClient.unwrap(e);
    }
  }

  Future<LoginResponse> register({
    required String nombre,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/register',
        data: {'nombre': nombre, 'email': email.trim().toLowerCase(), 'password': password},
      );
      return LoginResponse.fromJson(_mapJson(response.data, 'registro'));
    } catch (e) {
      throw ApiClient.unwrap(e);
    }
  }

  Future<LoginResponse> refresh({required String refreshToken}) async {
    try {
      final response = await _dio.post(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );
      return LoginResponse.fromJson(_mapJson(response.data, 'refresh'));
    } catch (e) {
      throw ApiClient.unwrap(e);
    }
  }

  /// Convierte el body a mapa de autenticación. Si el servidor respondió con
  /// algo que no es un JSON objeto (HTML, texto, error de proxy/CORS), se
  /// lanza una [SerializationException] tipada en lugar de un TypeError crudo.
  static Map<String, dynamic> _mapJson(Object? data, String accion) {
    if (data is Map<String, dynamic>) {
      return data;
    }
    throw SerializationException('Respuesta de $accion inválida.');
  }

  Future<void> logout({required String refreshToken}) async {
    await _dio.post<void>(
      '/auth/logout',
      options: Options(headers: {'Authorization': 'Refresh $refreshToken'}),
    );
  }
}