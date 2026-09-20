import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gesto_pago_app/core/format/message_de_error.dart';
import 'package:gesto_pago_app/core/network/app_exception.dart';
import 'package:gesto_pago_app/l10n/app_localizations.dart';

void main() {
  Future<BuildContext> contextoEs(WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('es'),
        supportedLocales: [Locale('es'), Locale('en')],
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Scaffold(body: Placeholder()),
      ),
    );
    return tester.element(find.byType(Placeholder));
  }

  testWidgets('traduce errores de red', (tester) async {
    final ctx = await contextoEs(tester);
    expect(
      messageDeError(ctx, const NetworkException('x')),
      'No se pudo conectar con el servidor. Revisa tu conexión.',
    );
  });

  testWidgets('traduce timeout', (tester) async {
    final ctx = await contextoEs(tester);
    expect(
      messageDeError(ctx, const TimeoutException('x')),
      'El servidor tardó demasiado en responder. Intenta de nuevo.',
    );
  });

  testWidgets('errores de negocio muestran su mensaje', (tester) async {
    final ctx = await contextoEs(tester);
    expect(
      messageDeError(ctx, const ApiException('Correo ya registrado', code: 'AUTH-006')),
      'Correo ya registrado',
    );
  });

  testWidgets('error desconocido sin mensaje usa genérico', (tester) async {
    final ctx = await contextoEs(tester);
    expect(
      messageDeError(ctx, const SerializationException('')),
      'Ocurrió un error inesperado. Intenta de nuevo.',
    );
  });
}