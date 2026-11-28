import '../../../core/network/token_refresher.dart';
import 'auth_session.dart';
import 'persona_fisica_registro.dart';

/// Contrato de acceso a la autenticación.
abstract interface class AuthRepository implements TokenRefresher {
  /// Inicia sesión (paso 1). Puede requerir 2FA o entregar la sesión directamente.
  Future<LoginResult> login({required String email, required String password});

  /// Completa el 2FA (paso 2) y persiste la sesión resultante.
  Future<AuthSession> verify2Fa({
    required String tempToken,
    required String codigo,
    required String email,
    bool forzarCierre = false,
  });

  /// Registra una cuenta nueva y persiste la sesión resultante.
  Future<AuthSession> register({
    required String nombre,
    required String email,
    required String password,
  });

  /// Registra un cliente Persona Física (onboarding completo de 3 pasos).
  Future<AuthSession> registerPersonaFisica(PersonaFisicaRegistro datos);

  /// Recupera la sesión persistida, si existe.
  Future<AuthSession?> restoreSession();

  /// Revoca el refresh token en el servidor y limpia el almacenamiento local.
  Future<void> logout();

  /// Limpia los datos locales de sesión.
  Future<void> clearSession();

  /// Valida si la sesión activa sigue siendo válida en el servidor.
  Future<bool> validateSession();
}