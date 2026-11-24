import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gesto_pago_app/features/auth/presentation/login_screen.dart';
import 'package:gesto_pago_app/features/auth/presentation/register_screen.dart';
import 'package:gesto_pago_app/core/widgets/password_field.dart';
import 'package:gesto_pago_app/l10n/app_localizations.dart';

Widget _app(Widget home) {
  return ProviderScope(
    child: MaterialApp(
      locale: const Locale('es'),
      supportedLocales: const [Locale('es'), Locale('en')],
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: home,
    ),
  );
}

void _usarPantallaTelefono(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  testWidgets('login muestra campos y botón', (tester) async {
    _usarPantallaTelefono(tester);
    await tester.pumpWidget(_app(const LoginScreen()));

    expect(find.text('Bienvenido de nuevo'), findsOneWidget);
    expect(find.byType(TextFormField), findsOneWidget);
    expect(find.byType(PasswordField), findsOneWidget);
    expect(
      find.widgetWithText(FilledButton, 'Iniciar sesión'),
      findsOneWidget,
    );
  });

  testWidgets('login valida campos vacíos', (tester) async {
    _usarPantallaTelefono(tester);
    await tester.pumpWidget(_app(const LoginScreen()));

    await tester.tap(find.widgetWithText(FilledButton, 'Iniciar sesión'));
    await tester.pumpAndSettle();

    expect(find.text('Ingresa tu correo'), findsOneWidget);
  });

  testWidgets('registro muestra el paso 1 de datos personales', (tester) async {
    _usarPantallaTelefono(tester);
    await tester.pumpWidget(_app(const RegisterScreen()));

    expect(find.text('Paso 1: Datos Personales'), findsOneWidget);
    expect(find.text('Gesto Pago Mobile'), findsOneWidget);
    expect(find.text('Siguiente'), findsOneWidget);
    expect(find.text('Nombre *'), findsOneWidget);
    expect(find.text('CURP (18 caracteres) *'), findsOneWidget);
    expect(find.text('RFC (12 o 13 caracteres) *'), findsOneWidget);
  });

  testWidgets('registro valida campos vacíos en el paso 1', (tester) async {
    _usarPantallaTelefono(tester);
    await tester.pumpWidget(_app(const RegisterScreen()));

    final botonSiguiente = find.widgetWithText(FilledButton, 'Siguiente');
    await tester.ensureVisible(botonSiguiente);
    await tester.tap(botonSiguiente);
    await tester.pumpAndSettle();

    expect(find.text('Por favor completa y corrige los campos de Datos Personales'), findsOneWidget);
    expect(find.text('El nombre es obligatorio'), findsOneWidget);
  });

  testWidgets('registro avanza a paso 2 y paso 3 y valida contraseñas', (tester) async {
    _usarPantallaTelefono(tester);
    await tester.pumpWidget(_app(const RegisterScreen()));

    // Llenar Paso 1: Datos Personales
    await tester.enterText(find.widgetWithText(TextFormField, 'Nombre *'), 'Carlos');
    await tester.enterText(find.widgetWithText(TextFormField, 'Apellido paterno *'), 'Hernandez');
    await tester.enterText(find.widgetWithText(TextFormField, 'Apellido materno *'), 'Gomez');
    await tester.enterText(find.widgetWithText(TextFormField, 'Fecha de nacimiento (AAAA-MM-DD) *'), '1995-04-12');
    await tester.enterText(find.widgetWithText(TextFormField, 'CURP (18 caracteres) *'), 'HEGC950412HDFRRN01');
    await tester.enterText(find.widgetWithText(TextFormField, 'RFC (12 o 13 caracteres) *'), 'HEGC950412XX1');

    // Avanzar a Paso 2
    final botonSiguiente1 = find.widgetWithText(FilledButton, 'Siguiente');
    await tester.ensureVisible(botonSiguiente1);
    await tester.tap(botonSiguiente1);
    await tester.pumpAndSettle();

    expect(find.text('Paso 2: Domicilio y Contacto'), findsOneWidget);

    // Llenar Paso 2: Domicilio y Contacto
    await tester.enterText(find.widgetWithText(TextFormField, 'Correo electrónico (Usuario y 2FA) *'), 'carlos@dominio.com');
    await tester.enterText(find.widgetWithText(TextFormField, 'Teléfono móvil (10 dígitos) *'), '4181234567');
    await tester.enterText(find.widgetWithText(TextFormField, 'Calle *'), 'Av. Insurgentes');
    await tester.enterText(find.widgetWithText(TextFormField, 'Núm. exterior *'), '100');
    await tester.enterText(find.widgetWithText(TextFormField, 'Colonia *'), 'Centro');
    await tester.enterText(find.widgetWithText(TextFormField, 'C.P. (5 dígitos) *'), '37800');
    await tester.enterText(find.widgetWithText(TextFormField, 'Municipio *'), 'Dolores Hidalgo');

    // Avanzar a Paso 3
    final botonSiguiente2 = find.widgetWithText(FilledButton, 'Siguiente');
    await tester.ensureVisible(botonSiguiente2);
    await tester.tap(botonSiguiente2);
    await tester.pumpAndSettle();

    expect(find.text('Paso 3: Información Laboral y Acceso'), findsOneWidget);
    expect(find.text('Requisitos de contraseña:'), findsOneWidget);

    // Llenar Paso 3 con contraseñas distintas
    await tester.enterText(find.widgetWithText(TextFormField, 'Ocupación *'), 'Desarrollador');
    await tester.enterText(find.widgetWithText(TextFormField, 'Empresa / Empleador *'), 'Software Inc');
    await tester.enterText(find.widgetWithText(TextFormField, 'Ingreso mensual (MXN) *'), '25000');
    await tester.enterText(find.byType(PasswordField).at(0), 'Password123!');
    await tester.enterText(find.byType(PasswordField).at(1), 'DifferentPassword456!');

    // Intentar registrar
    final botonRegistrar = find.widgetWithText(FilledButton, 'Registrar y Abrir Cuenta');
    await tester.ensureVisible(botonRegistrar);
    await tester.tap(botonRegistrar);
    await tester.pumpAndSettle();

    expect(find.text('Las contraseñas no coinciden.'), findsOneWidget);
  });
}
