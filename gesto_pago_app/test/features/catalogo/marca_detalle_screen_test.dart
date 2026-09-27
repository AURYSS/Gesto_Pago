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
import 'package:gesto_pago_app/features/catalogo/presentation/marca_detalle_screen.dart';
import 'package:gesto_pago_app/l10n/app_localizations.dart';

CatalogoProducto _p({
  required int idServicio,
  required int idProducto,
  required String servicio,
  required String producto,
  required String precio,
}) {
  return CatalogoProducto(
    idServicio: idServicio,
    idProducto: idProducto,
    servicio: servicio,
    producto: producto,
    idCatTipoServicio: 5,
    tipoFront: 1,
    tipoReferencia: '10 digitos',
    precio: precio,
    legend: null,
    hasDigitoVerificador: false,
    showAyuda: false,
  );
}

final _prods = <CatalogoProducto>[
  _p(idServicio: 133, idProducto: 403, servicio: 'Telcel', producto: 'Recarga 20', precio: '20.0'),
  _p(idServicio: 133, idProducto: 404, servicio: 'Telcel', producto: 'Recarga 50', precio: '50.0'),
  _p(idServicio: 500, idProducto: 900, servicio: 'Telcel Datos', producto: 'Paquete Internet 1GB', precio: '100.0'),
  _p(idServicio: 500, idProducto: 901, servicio: 'Telcel Datos', producto: 'Paquete Internet 2GB', precio: '200.0'),
];

CatalogoMarcas get _marcasFixture {
  final file = File('test/fixtures/marcas_catalogo.json');
  if (file.existsSync()) {
    final crudo = file.readAsStringSync();
    return CatalogoMarcas.fromJson(json.decode(crudo) as Map<String, dynamic>);
  }
  return CatalogoMarcas(
    categorias: const [
      CatalogoCategoria(slug: 'tiempo_aire', nombre: 'Tiempo Aire', orden: 1),
    ],
    marcas: const [
      CatalogoMarca(
        slug: 'telcel',
        nombre: 'Telcel',
        categoria: 'tiempo_aire',
        colorHex: '#002F6C',
        logoAsset: 'assets/images/marcas/telcel.png',
        destacada: true,
        orden: 1,
      ),
    ],
  );
}

class _CatalogoFake extends CatalogoController {
  _CatalogoFake(this._productos);

  final List<CatalogoProducto> _productos;

  @override
  Future<List<CatalogoProducto>> build() async => _productos;

  @override
  Future<void> refresh() async {}
}

class _MarcasFake extends MarcasController {
  _MarcasFake(this._marcas);

  final CatalogoMarcas _marcas;

  @override
  Future<CatalogoMarcas> build() async => _marcas;

  @override
  Future<void> refresh() async {}
}

Widget _construir(Widget child) {
  return ProviderScope(
    overrides: [
      catalogoControllerProvider.overrideWith(() => _CatalogoFake(_prods)),
      marcasControllerProvider.overrideWith(() => _MarcasFake(_marcasFixture)),
    ],
    child: MaterialApp(
      theme: GpTheme.dark(),
      darkTheme: GpTheme.dark(),
      locale: const Locale('es'),
      supportedLocales: const [Locale('es'), Locale('en')],
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: child,
    ),
  );
}

void main() {
  testWidgets('MarcaDetalleScreen muestra la cabecera con el nombre de la marca y sus productos agrupados', (tester) async {
    await tester.pumpWidget(_construir(const MarcaDetalleScreen(slug: 'telcel')));
    await tester.pumpAndSettle();

    expect(find.text('Telcel'), findsWidgets);
    expect(find.text('Recarga 20'), findsOneWidget);
    expect(find.text('Recarga 50'), findsOneWidget);
    expect(find.text('Paquete Internet 1GB'), findsOneWidget);
    expect(find.text('Paquete Internet 2GB'), findsOneWidget);
  });

  testWidgets('MarcaDetalleScreen permite buscar productos internamente', (tester) async {
    await tester.pumpWidget(_construir(const MarcaDetalleScreen(slug: 'telcel')));
    await tester.pumpAndSettle();

    final input = find.byType(TextField);
    await tester.enterText(input, 'Internet');
    await tester.pumpAndSettle();

    expect(find.text('Recarga 20'), findsNothing);
    expect(find.text('Paquete Internet 1GB'), findsOneWidget);
    expect(find.text('Paquete Internet 2GB'), findsOneWidget);
  });
}
