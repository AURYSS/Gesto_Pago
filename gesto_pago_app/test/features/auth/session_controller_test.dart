import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gesto_pago_app/core/network/token_refresher.dart';
import 'package:gesto_pago_app/core/providers/app_providers.dart';
import 'package:gesto_pago_app/features/auth/application/session_controller.dart';
import 'package:gesto_pago_app/features/auth/domain/auth_repository.dart';
import 'package:gesto_pago_app/features/auth/domain/auth_session.dart';
import 'package:gesto_pago_app/features/auth/domain/persona_fisica_registro.dart';

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
  Future<LoginResult> login({required String email, required String password}) async {
    if (session != null) {
      return LoginResult(requiere2Fa: false, session: session);
    }
    return const LoginResult(
      requiere2Fa: true,
      tempToken: 'fake-temp-token',
      codigo2FaDev: '123456',
      correoEnmascarado: 'ce***@gmail.com',
    );
  }

  @override
  Future<AuthSession> verify2Fa({
    required String tempToken,
    required String codigo,
    required String email,
    bool forzarCierre = false,
  }) async {
    return AuthSession(
      email: email,
      nombre: 'Usuario Prueba',
      accessToken: 'access-2fa',
      refreshToken: 'refresh-2fa',
      roles: const ['CLIENTE'],
    );
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
  Future<AuthSession> registerPersonaFisica(PersonaFisicaRegistro datos) async {
    return AuthSession(
      email: datos.correo,
      nombre: datos.nombreCompleto,
      accessToken: 'access-pf',
      refreshToken: 'refresh-pf',
      roles: const ['CLIENTE'],
    );
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

  @override
  Future<bool> validateSession() async => true;
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

  test('login con requiere2Fa -> devuelve LoginResult y mantiene unauthenticated', () async {
    final container = containerWith(null, null);

    final result = await container
        .read(sessionControllerProvider.notifier)
        .login(email: 'test@example.com', password: 'password123');

    expect(result.requiere2Fa, isTrue);
    expect(result.tempToken, 'fake-temp-token');
    expect(container.read(sessionControllerProvider).status, SessionStatus.unauthenticated);
  });

  test('complete2Fa -> autentica la sesión en memoria', () async {
    final container = containerWith(null, null);

    final session = await container.read(sessionControllerProvider.notifier).complete2Fa(
          tempToken: 'fake-temp-token',
          codigo: '123456',
          email: 'test@example.com',
        );

    expect(session.accessToken, 'access-2fa');
    final state = container.read(sessionControllerProvider);
    expect(state.status, SessionStatus.authenticated);
    expect(state.session?.email, 'test@example.com');
  });

  test('onSessionExpired con razón -> registra mensaje de revocación', () {
    final container = containerWith(null, null);

    container.read(sessionControllerProvider.notifier).onSessionExpired(
          'Tu sesión fue cerrada porque se inició sesión en la plataforma Web.',
        );

    final state = container.read(sessionControllerProvider);
    expect(state.status, SessionStatus.unauthenticated);
    expect(
      state.revocationMessage,
      'Tu sesión fue cerrada porque se inició sesión en la plataforma Web.',
    );
  });

  test('registerPersonaFisica -> crea cliente y pasa a authenticated', () async {
    final container = containerWith(null, null);

    const datos = PersonaFisicaRegistro(
      nombre: 'Maria',
      apellidoPaterno: 'Lopez',
      apellidoMaterno: 'Sanchez',
      fechaNacimiento: '1998-08-20',
      curp: 'LOSM980820MDFRRN02',
      rfc: 'LOSM980820XX2',
      sexo: 'FEMENINO',
      estadoCivil: 'SOLTERO',
      correo: 'maria@dominio.com',
      telefonoMovil: '4189998877',
      calle: 'Juarez',
      numeroExterior: '25',
      colonia: 'Centro',
      municipio: 'Dolores Hidalgo',
      estado: 'Guanajuato',
      codigoPostal: '37800',
      ocupacion: 'Contadora',
      empresa: 'Finanzas SA',
      ingresoMensual: 30000,
      password: 'Password123!',
    );

    final state = await container.read(sessionControllerProvider.notifier).registerPersonaFisica(datos);

    expect(state.status, SessionStatus.authenticated);
    expect(state.session?.email, 'maria@dominio.com');
    expect(state.session?.nombre, 'Maria Lopez Sanchez');
    expect(state.session?.accessToken, 'access-pf');
  });
}
