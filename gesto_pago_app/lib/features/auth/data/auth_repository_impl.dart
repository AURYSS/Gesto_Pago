import '../../../core/network/token_refresher.dart';
import '../../../core/network/token_store.dart';
import '../domain/auth_repository.dart';
import '../domain/auth_session.dart';
import '../domain/persona_fisica_registro.dart';
import 'auth_remote.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remote, this._tokenStore);

  final AuthRemote _remote;
  final TokenStore _tokenStore;

  @override
  Future<LoginResult> login({required String email, required String password}) async {
    final result = await _remote.login(email: email, password: password);
    if (!result.requiere2Fa && result.session != null) {
      await _persistIgnorandoErrores(result.session!);
    }
    return result;
  }

  @override
  Future<AuthSession> verify2Fa({
    required String tempToken,
    required String codigo,
    required String email,
    bool forzarCierre = false,
  }) async {
    final response = await _remote.verify2Fa(
      tempToken: tempToken,
      codigo: codigo,
      forzarCierre: forzarCierre,
    );
    final session = response.toSession(email.trim().toLowerCase());
    await _persistIgnorandoErrores(session);
    return session;
  }

  @override
  Future<AuthSession> register({
    required String nombre,
    required String email,
    required String password,
  }) async {
    final response = await _remote.register(
      nombre: nombre,
      email: email,
      password: password,
    );
    final session = response.toSession(email.trim().toLowerCase());
    await _persistIgnorandoErrores(session);
    return session;
  }

  @override
  Future<AuthSession> registerPersonaFisica(PersonaFisicaRegistro datos) async {
    final response = await _remote.registerPersonaFisica(datos);
    final session = response.toSession(datos.correo.trim().toLowerCase());
    await _persistIgnorandoErrores(session);
    return session;
  }

  @override
  Future<AuthSession?> restoreSession() async {
    final access = await _tokenStore.readAccessToken();
    final email = await _tokenStore.readEmail();
    if (access == null || email == null) {
      return null;
    }
    final nombre = await _tokenStore.readNombre();
    final refresh = await _tokenStore.readRefreshToken();
    return AuthSession(
      email: email,
      nombre: nombre ?? '',
      accessToken: access,
      refreshToken: refresh ?? '',
      roles: const [],
    );
  }

  @override
  Future<TokenRefreshResult?> refreshSession(String refreshToken) async {
    final response = await _remote.refresh(refreshToken: refreshToken);
    return TokenRefreshResult(
      accessToken: response.accessToken,
      refreshToken: response.refreshToken,
      nombre: response.nombre,
    );
  }

  @override
  Future<void> logout() async {
    try {
      final refresh = await _tokenStore.readRefreshToken();
      if (refresh != null && refresh.isNotEmpty) {
        await _remote.logout(refreshToken: refresh);
      }
    } finally {
      await _tokenStore.clear();
    }
  }

  @override
  Future<void> clearSession() => _tokenStore.clear();

  @override
  Future<bool> validateSession() async {
    try {
      return await _remote.validateSession();
    } catch (_) {
      return false;
    }
  }

  /// Persiste la sesión; si el almacenamiento seguro falla (p. ej. keystore
  /// disponible a medias) NO rompe un login/registro ya autorizado por el
  /// backend: la sesión sigue activa en memoria y se re-persiste en el
  /// siguiente refresh. Al reiniciar la app el usuario volvería a entrar.
  Future<void> _persistIgnorandoErrores(AuthSession session) async {
    try {
      await _persist(session);
    } catch (_) {
      // Se mantiene la sesión en memoria; el interceptor deja tokens al refrescar.
    }
  }

  Future<void> _persist(AuthSession session) {
    return _tokenStore.save(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
      nombre: session.nombre,
      email: session.email,
    );
  }
}