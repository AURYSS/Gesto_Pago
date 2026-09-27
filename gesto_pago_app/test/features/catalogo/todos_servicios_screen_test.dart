import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gesto_pago_app/core/theme/gp_theme.dart';
import 'package:gesto_pago_app/features/catalogo/application/catalogo_controller.dart';
import 'package:gesto_pago_app/features/catalogo/application/marcas_controller.dart';
import 'package:gesto_pago_app/features/catalogo/domain/catalogo_marca.dart';
import 'package:gesto_pago_app/features/catalogo/domain/catalogo_producto.dart';
import 'package:gesto_pago_app/features/catalogo/presentation/todos_servicios_screen.dart';
import 'package:gesto_pago_app/features/catalogo/presentation/widgets/category_chip.dart';
import 'package:gesto_pago_app/features/catalogo/presentation/widgets/gp_search_bar.dart';
import 'package:gesto_pago_app/features/catalogo/presentation/widgets/servicio_card.dart';
import 'package:gesto_pago_app/l10n/app_localizations.dart';

List<CatalogoProducto> _catalogoReal() {
  final crudo = File('test/fixtures/catalogo_servicios.json').readAsStringSync();
  final productos = <CatalogoProducto>[];
  for (final fila in json.decode(crudo) as List<dynamic>) {
    final m = fila as Map<String, dynamic>;
    for (var i = 0; i < (m['cantidad'] as int); i++) {
      productos.add(CatalogoProducto(
        idServicio: m['idServicio'] as int,
        idProducto: (m['idProducto'] as int) + i,
        servicio: m['servicio'] as String,
        producto: m['producto'] as String,
        idCatTipoServicio: 5,
        tipoFront: 1,
        tipoReferencia: 'a',
        precio: m['precio'] as String,
        legend: null,
        hasDigitoVerificador: false,
        showAyuda: false,
      ));
    }
  }
  return productos;
}

CatalogoMarcas _marcasFixture() {
  final crudo = File('test/fixtures/marcas_catalogo.json').readAsStringSync();
  return CatalogoMarcas.fromJson(json.decode(crudo) as Map<String, dynamic>);
}

Widget _app({String? categoriaInicial}) {
  return ProviderScope(
    overrides: [
      catalogoControllerProvider.overrideWith(() => _CatalogoFake()),
      marcasControllerProvider.overrideWith(() => _MarcasFake()),
    ],
    child: MaterialApp(
      theme: GpTheme.dark(),
      darkTheme: GpTheme.dark(),
      themeMode: ThemeMode.dark,
      locale: const Locale('es'),
      supportedLocales: const [Locale('es'), Locale('en')],
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: TodosServiciosScreen(categoriaInicial: categoriaInicial),
    ),
  );
}

class _CatalogoFake extends CatalogoController {
  @override
  Future<List<CatalogoProducto>> build() async => _catalogoReal();

  @override
  Future<void> refresh() async {}
}

class _MarcasFake extends MarcasController {
  @override
  Future<CatalogoMarcas> build() async => _marcasFixture();

  @override
  Future<void> refresh() async {}
}

/// Escribe en el buscador de la pantalla y deja el frame asentado.
Future<void> _buscar(WidgetTester tester, String texto) async {
  await tester.enterText(
    find.descendant(
      of: find.byType(GpSearchBar),
      matching: find.byType(EditableText),
    ),
    texto,
  );
  await tester.pumpAndSettle();
}

void main() {
  group('TodosServiciosScreen', () {
    testWidgets('lista el catalogo completo con el titulo de la pantalla',
        (tester) async {
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();

      expect(find.text('Todos los servicios'), findsOneWidget);
      expect(find.byType(GpSearchBar), findsOneWidget);
      expect(find.byType(ServicioCard), findsWidgets);
    });

    testWidgets('filtra por categoria al abrir con una categoria inicial',
        (tester) async {
      await tester.pumpWidget(_app(categoriaInicial: 'television'));
      await tester.pumpAndSettle();

      await _buscar(tester, 'sky');
      expect(find.textContaining('SKY'), findsWidgets);
      expect(find.textContaining('Telcel'), findsNothing);
      expect(find.textContaining('Netflix'), findsNothing);
    });

    testWidgets('la busqueda acota la lista', (tester) async {
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();

      await _buscar(tester, 'jafra');
      expect(find.byType(ServicioCard), findsOneWidget);
      expect(find.textContaining('Jafra'), findsOneWidget);
    });

    testWidgets('un filtro sin coincidencias muestra el estado vacio',
        (tester) async {
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();

      await _buscar(tester, 'zzzz');

      expect(find.byType(ServicioCard), findsNothing);
      expect(find.text('No hay servicios disponibles.'), findsOneWidget);
    });

    testWidgets('los chips de categoria siguen disponibles', (tester) async {
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();

      expect(find.byType(CategoryChip), findsWidgets);
      expect(find.text('Todos'), findsOneWidget);
    });
  });
}
