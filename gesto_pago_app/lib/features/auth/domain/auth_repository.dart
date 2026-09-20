import '../../../core/network/token_refresher.dart';
import 'auth_session.dart';

/// Contrato de acceso a la autenticación.
abstract interface class AuthRepository implements TokenRefresher {
  /// Inicia sesión y persiste la sesión en el almacenamiento seguro.
  Future<AuthSession> login({required String email, required String password});

  /// Registra una cuenta nueva y persiste la sesión resultante.
  Future<AuthSession> register({
    required String nombre,
    required String email,
    required String password,
  });

  /// Recupera la sesión persistida, si existe.
  Future<AuthSession?> restoreSession();

  /// Revoca el refresh token en el servidor y limpia el almacenamiento local.
  Future<void> logout();

  /// Limpia los datos locales de sesión.
  Future<void> clearSession();
}