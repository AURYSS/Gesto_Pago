import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gesto_pago_app/core/theme/gp_theme.dart';
import 'package:gesto_pago_app/core/widgets/theme_toggle.dart';
import 'package:gesto_pago_app/features/catalogo/application/catalogo_controller.dart';
import 'package:gesto_pago_app/features/catalogo/application/marcas_controller.dart';
import 'package:gesto_pago_app/features/catalogo/domain/catalogo_marca.dart';
import 'package:gesto_pago_app/features/catalogo/domain/catalogo_producto.dart';
import 'package:gesto_pago_app/features/catalogo/presentation/inicio_screen.dart';
import 'package:gesto_pago_app/features/catalogo/presentation/widgets/category_chip.dart';
import 'package:gesto_pago_app/features/catalogo/presentation/widgets/gp_search_bar.dart';
import 'package:gesto_pago_app/features/catalogo/presentation/widgets/service_card.dart';
import 'package:gesto_pago_app/features/catalogo/presentation/widgets/servicio_card.dart';
import 'package:gesto_pago_app/features/pagos/application/pendientes_controller.dart';
import 'package:gesto_pago_app/features/pagos/domain/estado_transaccion.dart';
import 'package:gesto_pago_app/features/pagos/domain/pago_pendiente.dart';
import 'package:gesto_pago_app/features/pagos/presentation/widgets/pending_payment_item.dart';
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
    tipoReferencia: 'a',
    precio: precio,
    legend: null,
    hasDigitoVerificador: false,
    showAyuda: false,
  );
}

final _catalogo = <CatalogoProducto>[
  _p(idServicio: 133, idProducto: 403, servicio: 'Telcel', producto: 'Recarga 20', precio: '20.0'),
  _p(idServicio: 500, idProducto: 900, servicio: 'Telcel Datos', producto: 'Internet 1GB', precio: '30.0'),
  _p(idServicio: 124, idProducto: 373, servicio: 'Movistar', producto: 'Recarga 10', precio: '10.0'),
  _p(idServicio: 166, idProducto: 597, servicio: 'CFE', producto: 'CFE', precio: '10.0'),
  _p(idServicio: 85, idProducto: 215, servicio: 'Totalplay', producto: 'TotalPlay', precio: '10.0'),
  _p(idServicio: 178, idProducto: 7030, servicio: 'Netflix', producto: 'Netflix 300', precio: '300.0'),
  _p(idServicio: 38, idProducto: 5266, servicio: 'Televia', producto: 'Televia 100', precio: '100.0'),
  _p(idServicio: 900, idProducto: 9000, servicio: 'Cinepolis', producto: 'Boletos', precio: '10.0'),
];

List<CatalogoProducto> get _catalogoReal {
  final crudo = File('test/fixtures/catalogo_servicios.json').readAsStringSync();
  final productos = <CatalogoProducto>[];
  for (final fila in json.decode(crudo) as List<dynamic>) {
    final m = fila as Map<String, dynamic>;
    for (var i = 0; i < (m['cantidad'] as int); i++) {
      productos.add(_p(
        idServicio: m['idServicio'] as int,
        idProducto: (m['idProducto'] as int) + i,
        servicio: m['servicio'] as String,
        producto: m['producto'] as String,
        precio: m['precio'] as String,
      ));
    }
  }
  return productos;
}

CatalogoMarcas get _marcasFixture {
  final crudo = File('test/fixtures/marcas_catalogo.json').readAsStringSync();
  return CatalogoMarcas.fromJson(json.decode(crudo) as Map<String, dynamic>);
}

final _pendientes = <PagoPendiente>[
  PagoPendiente(
    id: 1,
    idServicio: 166,
    idProducto: 597,
    servicio: 'CFE',
    producto: 'Pago de recibo',
    referencia: '12345678',
    monto: '1847.50',
    estado: EstadoTransaccion.enProceso,
    puedeConfirmar: true,
  ),
  PagoPendiente(
    id: 2,
    idServicio: 85,
    idProducto: 215,
    servicio: 'Totalplay',
    producto: 'Internet',
    referencia: '87654321',
    monto: '649.00',
    estado: EstadoTransaccion.fallida,
    puedeReintentar: true,
  ),
  PagoPendiente(
    id: 3,
    idServicio: 128,
    idProducto: 5265,
    servicio: 'Zeta Gas',
    producto: 'Gas',
    referencia: '11223344',
    monto: '312.40',
    estado: EstadoTransaccion.pendiente,
    puedeReintentar: true,
  ),
];

Widget _app(
  Widget home, {
  Brightness brightness = Brightness.dark,
  List<CatalogoProducto>? productos,
}) {
  return ProviderScope(
    overrides: [
      catalogoControllerProvider.overrideWith(
        () => _CatalogoFake(productos ?? _catalogo),
      ),
      marcasControllerProvider.overrideWith(
        () => _MarcasFake(_marcasFixture),
      ),
      pendientesControllerProvider.overrideWith(
        () => _PendientesFake(_pendientes),
      ),
    ],
    child: MaterialApp(
      theme: GpTheme.dark(),
      darkTheme: GpTheme.dark(),
      themeMode: brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
      locale: const Locale('es'),
      supportedLocales: const [Locale('es'), Locale('en')],
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: home,
    ),
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

class _PendientesFake extends PendientesController {
  _PendientesFake(this._pendientes);

  final List<PagoPendiente> _pendientes;

  @override
  Future<List<PagoPendiente>> build() async => _pendientes;

  @override
  Future<void> refresh() async {}
}

void _usarTamano(WidgetTester tester, Size tamano) {
  tester.view.physicalSize = tamano;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  group('InicioScreen', () {
    testWidgets('la portada no arrastra la lista vertical del catalogo',
        (tester) async {
      _usarTamano(tester, const Size(420, 2400));
      await tester.pumpWidget(_app(const InicioScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Pagos pendientes'), findsOneWidget);
      expect(find.text('Servicios populares'), findsOneWidget);
      expect(find.text('Ver todos'), findsOneWidget);
      expect(find.byType(ServicioCard), findsNothing);
      expect(find.text('Todos los servicios'), findsNothing);
    });

    testWidgets('la portada no desborda con el catalogo real completo',
        (tester) async {
      _usarTamano(tester, const Size(420, 900));
      await tester.pumpWidget(_app(
        const InicioScreen(),
        productos: _catalogoReal,
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(ServicioCard), findsNothing);
    });

    testWidgets('la cuadricula de populares usa el logo de la marca', (tester) async {
      _usarTamano(tester, const Size(420, 2400));
      await tester.pumpWidget(_app(const InicioScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(ServiceCard), findsWidgets);
      expect(find.text('Telcel'), findsWidgets);
    });

    testWidgets('los chips de categoria se pintan', (tester) async {
      _usarTamano(tester, const Size(420, 2400));
      await tester.pumpWidget(_app(const InicioScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(CategoryChip), findsWidgets);
      expect(find.text('Todos'), findsOneWidget);
    });

    testWidgets('las transacciones pendientes muestran monto, estado y accion',
        (tester) async {
      _usarTamano(tester, const Size(420, 2400));
      await tester.pumpWidget(_app(const InicioScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(PendingPaymentItem), findsNWidgets(3));
      expect(find.text('CFE'), findsWidgets);
      expect(find.text('Confirmar'), findsOneWidget);
      expect(find.text('Reintentar'), findsNWidgets(2));
    });

    testWidgets('la busqueda sustituye la portada por resultados', (tester) async {
      _usarTamano(tester, const Size(420, 2400));
      await tester.pumpWidget(_app(const InicioScreen()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(GpSearchBar), 'netflix');
      await tester.pumpAndSettle();

      expect(find.byType(ServiceCard), findsNothing);
      expect(find.byType(PendingPaymentItem), findsNothing);
      expect(find.text('1 resultado'), findsOneWidget);
    });

    testWidgets('la cuadricula no desborda en pantalla angosta', (tester) async {
      _usarTamano(tester, const Size(320, 2400));
      await tester.pumpWidget(_app(const InicioScreen()));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('la cuadricula no desborda en pantalla ancha', (tester) async {
      _usarTamano(tester, const Size(1000, 1400));
      await tester.pumpWidget(_app(const InicioScreen()));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('sin resultados muestra el estado vacio', (tester) async {
      _usarTamano(tester, const Size(420, 2400));
      await tester.pumpWidget(_app(const InicioScreen()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(GpSearchBar), 'zzzzz-no-existe');
      await tester.pumpAndSettle();

      expect(find.text('No hay servicios disponibles.'), findsOneWidget);
    });

    testWidgets('el toggle de tema sigue disponible', (tester) async {
      _usarTamano(tester, const Size(420, 2400));
      await tester.pumpWidget(_app(const InicioScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(ThemeToggle), findsOneWidget);
    });
  });
}
