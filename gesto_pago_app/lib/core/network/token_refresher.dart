/// Resultado de autenticación tras un refresh.
class TokenRefreshResult {
  const TokenRefreshResult({
    required this.accessToken,
    required this.refreshToken,
    required this.nombre,
  });

  final String accessToken;
  final String refreshToken;
  final String nombre;
}

/// Interfaz que implementa el repositorio de autenticación para permitir
/// renovar la sesión desde el interceptor HTTP (evita dependencias circulares).
abstract class TokenRefresher {
  Future<TokenRefreshResult?> refreshSession(String refreshToken);
}

/// Puente que entrega el [TokenRefresher] activo sin crear una referencia
/// circular estática entre ApiClient y AuthRepository. Se vincula una sola
/// vez al arrancar la aplicación y se consulta solo si un 401 exige refresh.
class TokenRefresherBridge {
  TokenRefresher Function()? _lookup;

  void bind(TokenRefresher Function() lookup) {
    _lookup = lookup;
  }

  TokenRefresher resolve() {
    final lookup = _lookup;
    if (lookup == null) {
      throw StateError('TokenRefresherBridge no ha sido inicializado.');
    }
    return lookup();
  }
}

/// Puente para notificar la expiración de sesión sin que [ApiClient] dependa
/// del [SessionController] (mismo patrón anti-circular que
/// [TokenRefresherBridge]). Se enlaza una vez al arrancar la aplicación.
class SessionExpiredBridge {
  void Function()? _lookup;

  void bind(void Function() lookup) {
    _lookup = lookup;
  }

  void resolve() {
    _lookup?.call();
  }
}