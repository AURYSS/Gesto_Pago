/// Errores tipados de la capa de red/aplicación.
///
/// Se distinguen errores esperados (validación, negocio, autenticación,
/// límite de peticiones) de errores técnicos (red, timeout, servidor).
sealed class AppException implements Exception {
  const AppException(this.message, {this.code, this.statusCode});

  /// Mensaje humano, sin detalles internos.
  final String message;

  /// Código de error estable del backend (p. ej. `AUTH-001`).
  final String? code;

  /// Código HTTP de la respuesta, si aplica.
  final int? statusCode;

  @override
  String toString() => 'AppException($code, $statusCode): $message';
}

/// Fallo de red: sin conexión, DNS, TLS.
class NetworkException extends AppException {
  const NetworkException(super.message);
}

/// La petición agotó el tiempo de espera.
class TimeoutException extends AppException {
  const TimeoutException(super.message);
}

/// Error de validación o negocio devuelto por el backend.
class ApiException extends AppException {
  const ApiException(super.message, {super.code, super.statusCode});
}

/// Credenciales inválidas o sesión revocada/expirada (401).
class UnauthorizedException extends ApiException {
  const UnauthorizedException(super.message, {super.code, super.statusCode});
}

/// Sin permisos para el recurso (403).
class ForbiddenException extends ApiException {
  const ForbiddenException(super.message, {super.code, super.statusCode});
}

/// Demasiadas peticiones (429).
class RateLimitException extends ApiException {
  const RateLimitException(super.message, {super.code, super.statusCode});
}

/// El recurso no existe (404).
class NotFoundException extends ApiException {
  const NotFoundException(super.message, {super.code, super.statusCode});
}

/// Error técnico del servidor (5xx) no previsto.
class ServerException extends AppException {
  const ServerException(super.message, {super.statusCode});
}

/// El cliente no pudo interpretar la respuesta del servidor.
class SerializationException extends AppException {
  const SerializationException(super.message);
}