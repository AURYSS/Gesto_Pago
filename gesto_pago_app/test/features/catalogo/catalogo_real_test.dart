import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gesto_pago_app/features/catalogo/domain/catalogo_agrupacion.dart';
import 'package:gesto_pago_app/features/catalogo/domain/catalogo_marca.dart';
import 'package:gesto_pago_app/features/catalogo/domain/catalogo_producto.dart';

List<CatalogoProducto> _catalogoReal() {
  final crudo = File('test/fixtures/catalogo_servicios.json').readAsStringSync();
  final filas = json.decode(crudo) as List<dynamic>;
  final productos = <CatalogoProducto>[];
  for (final fila in filas) {
    final m = fila as Map<String, dynamic>;
    final cantidad = m['cantidad'] as int;
    for (var i = 0; i < cantidad; i++) {
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

CatalogoMarcas _marcasCatalogo() {
  final crudo = File('test/fixtures/marcas_catalogo.json').readAsStringSync();
  return CatalogoMarcas.fromJson(json.decode(crudo) as Map<String, dynamic>);
}

void main() {
  final catalogo = _catalogoReal();
  final marcas = _marcasCatalogo();

  group('catalogo real del proveedor', () {
    test('el fixture reproduce el catalogo real', () {
      expect(catalogo, hasLength(900), reason: 'productos en /catalogo/productos');
      expect(catalogo.map((p) => p.servicio).toSet(), hasLength(272),
          reason: 'servicios unicos del proveedor');
    });

    test('la portada muestra las cinco marcas destacadas', () {
      final portada = resumenMarcas(catalogo, marcas);

      expect(portada.length, 6);
      expect(
        portada.take(5).map((m) => m.slug).toList(),
        ['telcel', 'cfe', 'izzi', 'sky', 'att'],
      );
      // La sexta plaza la gana la marca con mas cobertura que no este destacada.
      expect(portada.last.slug, 'bait');
      expect(portada.last.cantidadProductos, greaterThan(0));
    });

    test('cada marca de la portada trae logo y color', () {
      for (final marca in resumenMarcas(catalogo, marcas)) {
        expect(marca.slug, isNotNull, reason: 'sin logo: ${marca.slug}');
        expect(marcas.colorDe(marca.nombre), isNotNull,
            reason: 'sin color: ${marca.nombre}');
        expect(marcas.porSlug(marca.slug)?.logoAsset, isNotNull,
            reason: 'logo sin archivo: ${marca.slug}');
      }
    });

    test('ninguna ficha de la portada es un monograma', () {
      final portada = resumenMarcas(catalogo, marcas);
      for (final marca in portada) {
        expect(marca.slug, isNotEmpty);
        expect(marca.slug.length, greaterThan(1),
            reason: 'slug vacio para ${marca.nombre}');
      }
    });

    test('la cobertura de logos cubre la mayor parte del catalogo', () {
      final servicios = catalogo.map((p) => p.servicio).toSet();
      final conLogo = servicios.where((s) => marcas.slugDe(s) != null);
      final productosConLogo =
          catalogo.where((p) => marcas.slugDe(p.servicio) != null).length;
      expect(conLogo.length, 59);
      expect(productosConLogo, 320);
    });

    test('las categorias con productos son las esperadas', () {
      final conteo = conteoPorCategoria(catalogo, marcas);

      expect(conteo.keys, containsAll(marcas.categorias.map((c) => c.slug)));
      final mayor = conteo.entries.reduce((a, b) => a.value >= b.value ? a : b);
      expect(mayor.key, 'tiempo_aire');
      for (final entrada in conteo.entries) {
        expect(entrada.value, greaterThan(0));
      }
    });

    test('el buscador encuentra marcas por nombre parcial', () {
      int filtrar(String texto) => catalogo
          .where((p) =>
              p.servicio.toLowerCase().contains(texto) ||
              p.producto.toLowerCase().contains(texto))
          .length;

      expect(filtrar('netflix'), greaterThan(0));
      expect(filtrar('cin'), greaterThan(0), reason: 'cubre Cinepolis y Cinemex');
      expect(filtrar('zzzz'), 0);
    });
  });
}
