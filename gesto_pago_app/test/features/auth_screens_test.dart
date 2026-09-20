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
  tester.view.physicalSize = const Size(1080, 2280);
  tester.view.devicePixelRatio = 3.0;
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

  testWidgets('registro muestra todos los campos', (tester) async {
    _usarPantallaTelefono(tester);
    await tester.pumpWidget(_app(const RegisterScreen()));

    expect(find.text('Crear cuenta'), findsWidgets);
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.byType(PasswordField), findsNWidgets(2));
  });

  testWidgets('registro rechaza contraseñas distintas', (tester) async {
    _usarPantallaTelefono(tester);
    await tester.pumpWidget(_app(const RegisterScreen()));

    await tester.enterText(find.byType(TextFormField).at(0), 'Juan Pérez');
    await tester.enterText(find.byType(TextFormField).at(1), 'juan@correo.com');
    await tester.enterText(find.byType(PasswordField).at(0), '123456');
    await tester.enterText(find.byType(PasswordField).at(1), '654321');

    await tester.tap(find.widgetWithText(FilledButton, 'Crear cuenta'));
    await tester.pumpAndSettle();

    expect(find.text('Las contraseñas no coinciden.'), findsOneWidget);
  });
}