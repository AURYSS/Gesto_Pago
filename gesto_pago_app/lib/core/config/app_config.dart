import 'package:flutter/foundation.dart';

class AppConfig {
  const AppConfig._();

  static const String _envUrl = String.fromEnvironment('API_BASE_URL');

  /// URL base de la API.
  /// Si se especifica API_BASE_URL por entorno, se respeta esa URL.
  /// En emulador Android por defecto conecta a 10.0.2.2:8080.
  /// En web o escritorio conecta a localhost:8080.
  static String get apiBaseUrl {
    if (_envUrl.isNotEmpty) {
      return _envUrl;
    }
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8080';
    }
    return 'http://localhost:8080';
  }

  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 60);
}