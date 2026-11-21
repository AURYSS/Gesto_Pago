import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/app_exception.dart';
import '../../../core/providers/app_providers.dart';
import '../domain/auth_repository.dart';
import '../domain/auth_session.dart';

enum SessionStatus { unknown, authenticated, unauthenticated }

/// Estado de sesión de la aplicación.
class SessionState {
  const SessionState({
    required this.status,
    this.session,
    this.revocationMessage,
  });

  const SessionState.unknown() : this(status: SessionStatus.unknown);
  const SessionState.unauthenticated({String? revocationMessage})
      : this(status: SessionStatus.unauthenticated, revocationMessage: revocationMessage);

  final SessionStatus status;
  final AuthSession? session;
  final String? revocationMessage;

  bool get isAuthenticated => status == SessionStatus.authenticated;

  SessionState copyWith({
    SessionStatus? status,
    AuthSession? session,
    String? revocationMessage,
    bool clearRevocationMessage = false,
  }) {
    return SessionState(
      status: status ?? this.status,
      session: session ?? this.session,
      revocationMessage: clearRevocationMessage ? null : (revocationMessage ?? this.revocationMessage),
    );
  }
}

/// Controla la sesión: restauración, login, logout y detección de concurrencia.
class SessionController extends Notifier<SessionState> {
  Timer? _heartbeatTimer;

  @override
  SessionState build() {
    ref.onDispose(() {
      _stopHeartbeat();
    });
    return const SessionState.unknown();
  }

  AuthRepository get _repository => ref.read(authRepositoryProvider);

  void _startHeartbeat() {
    _stopHeartbeat();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      if (!state.isAuthenticated) {
        _stopHeartbeat();
        return;
      }
      try {
        final ok = await _repository.validateSession();
        if (!ok) {
          onSessionExpired('Se inicio sesion en otro dispositivo.');
        }
      } on AppException catch (e) {
        if (e is UnauthorizedException && (e.code == 'AUTH-009' || e.message.contains('otro dispositivo'))) {
          onSessionExpired(
            e.message.isNotEmpty ? e.message : 'Se inicio sesion en otro dispositivo.',
          );
        }
      } catch (_) {
        // Ignorar fallos de red esporádicos
      }
    });
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  Future<void> restore() async {
    try {
      final session = await _repository.restoreSession();
      if (session != null && session.accessToken.isNotEmpty) {
        state = SessionState(status: SessionStatus.authenticated, session: session);
        _startHeartbeat();
      } else {
        state = const SessionState.unauthenticated();
      }
    } catch (_) {
      try {
        await _repository.clearSession();
      } catch (_) {}
      state = const SessionState.unauthenticated();
    }
  }

  Future<LoginResult> login({required String email, required String password}) async {
    _stopHeartbeat();
    state = const SessionState.unauthenticated();
    final result = await _repository.login(email: email, password: password);
    if (!result.requiere2Fa && result.session != null) {
      state = SessionState(status: SessionStatus.authenticated, session: result.session);
      _startHeartbeat();
    }
    return result;
  }

  Future<AuthSession> complete2Fa({
    required String tempToken,
    required String codigo,
    required String email,
    bool forzarCierre = false,
  }) async {
    final session = await _repository.verify2Fa(
      tempToken: tempToken,
      codigo: codigo,
      email: email,
      forzarCierre: forzarCierre,
    );
    state = SessionState(status: SessionStatus.authenticated, session: session);
    _startHeartbeat();
    return session;
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
    _startHeartbeat();
    return state;
  }

  Future<void> logout() async {
    _stopHeartbeat();
    try {
      await _repository.logout();
    } finally {
      state = const SessionState.unauthenticated();
    }
  }

  void onSessionExpired([String? reason]) {
    _stopHeartbeat();
    _repository.clearSession();
    state = SessionState.unauthenticated(revocationMessage: reason);
  }

  void clearRevocationMessage() {
    if (state.revocationMessage != null) {
      state = state.copyWith(clearRevocationMessage: true);
    }
  }
}

final sessionControllerProvider =
    NotifierProvider<SessionController, SessionState>(SessionController.new);
