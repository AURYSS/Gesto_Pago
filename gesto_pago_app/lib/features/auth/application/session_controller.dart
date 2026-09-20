import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../domain/auth_repository.dart';
import '../domain/auth_session.dart';

enum SessionStatus { unknown, authenticated, unauthenticated }

/// Estado de sesión de la aplicación.
class SessionState {
  const SessionState({required this.status, this.session});

  const SessionState.unknown() : this(status: SessionStatus.unknown);
  const SessionState.unauthenticated() : this(status: SessionStatus.unauthenticated);

  final SessionStatus status;
  final AuthSession? session;

  bool get isAuthenticated => status == SessionStatus.authenticated;
}

/// Controla la sesión: restauración, login y logout.
class SessionController extends Notifier<SessionState> {
  @override
  SessionState build() {
    return const SessionState.unknown();
  }

  AuthRepository get _repository => ref.read(authRepositoryProvider);

  Future<void> restore() async {
    try {
      final session = await _repository.restoreSession();
      state = session != null && session.accessToken.isNotEmpty
          ? SessionState(status: SessionStatus.authenticated, session: session)
          : const SessionState.unauthenticated();
    } catch (_) {
      // Si falla la lectura del almacenamiento seguro, limpiar y salir a login:
      // nunca dejar la app atascada en "Restaurando sesión…".
      try {
        await _repository.clearSession();
      } catch (_) {}
      state = const SessionState.unauthenticated();
    }
  }

  Future<SessionState> login({required String email, required String password}) async {
    final session = await _repository.login(email: email, password: password);
    state = SessionState(status: SessionStatus.authenticated, session: session);
    return state;
  }

  Future<SessionState> register({
    required String nombre,
    required String email,
    required String password,
  }) async {
    final session = await _repository.register(
      nombre: nombre,
      email: email,
      password: password,
    );
    state = SessionState(status: SessionStatus.authenticated, session: session);
    return state;
  }

  Future<void> logout() async {
    try {
      await _repository.logout();
    } finally {
      state = const SessionState.unauthenticated();
    }
  }

  void onSessionExpired() {
    _repository.clearSession();
    state = const SessionState.unauthenticated();
  }
}

final sessionControllerProvider =
    NotifierProvider<SessionController, SessionState>(SessionController.new);