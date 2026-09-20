import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gesto_pago_app/core/network/token_refresher.dart';
import 'package:gesto_pago_app/core/providers/app_providers.dart';
import 'package:gesto_pago_app/features/auth/application/session_controller.dart';
import 'package:gesto_pago_app/features/auth/domain/auth_repository.dart';
import 'package:gesto_pago_app/features/auth/domain/auth_session.dart';

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({this.session, this.restoreError});

  final AuthSession? session;
  final Object? restoreError;

  bool clearCalled = false;

  @override
  Future<AuthSession?> restoreSession() async {
    if (restoreError != null) {
      throw restoreError!;
    }
    return session;
  }

  @override
  Future<AuthSession> login({required String email, required String password}) {
    throw UnimplementedError();
  }

  @override
  Future<AuthSession> register({
    required String nombre,
    required String email,
    required String password,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<TokenRefreshResult?> refreshSession(String refreshToken) {
    throw UnimplementedError();
  }

  @override
  Future<void> logout() async {}

  @override
  Future<void> clearSession() async {
    clearCalled = true;
  }
}

void main() {
  ProviderContainer containerWith(Object? restoreError, AuthSession? session) {
    final repo = _FakeAuthRepository(restoreError: restoreError, session: session);
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('restore sin sesión persistida -> unauthenticated', () async {
    final container = containerWith(null, null);

    expect(container.read(sessionControllerProvider).status, SessionStatus.unknown);

    await container.read(sessionControllerProvider.notifier).restore();

    expect(
      container.read(sessionControllerProvider).status,
      SessionStatus.unauthenticated,
    );
  });

  test('restore con sesión persistida -> authenticated', () async {
    final container = containerWith(
      null,
      const AuthSession(
        email: 'a@b.com',
        nombre: 'Ana',
        accessToken: 'tok',
        refreshToken: 'ref',
        roles: [],
      ),
    );

    await container.read(sessionControllerProvider.notifier).restore();

    final state = container.read(sessionControllerProvider);
    expect(state.status, SessionStatus.authenticated);
    expect(state.session?.accessToken, 'tok');
  });

  test('restore con fallo del almacenamiento seguro -> unauthenticated y limpia', () async {
    final container = containerWith(StateError('keystore caído'), null);

    await container.read(sessionControllerProvider.notifier).restore();

    final state = container.read(sessionControllerProvider);
    expect(state.status, SessionStatus.unauthenticated);
    expect(state.session, isNull);
  });
}