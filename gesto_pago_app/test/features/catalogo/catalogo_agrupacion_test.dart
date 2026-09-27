import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gesto_pago_app/features/catalogo/domain/catalogo_agrupacion.dart';
import 'package:gesto_pago_app/features/catalogo/domain/catalogo_marca.dart';
import 'package:gesto_pago_app/features/catalogo/domain/catalogo_producto.dart';

CatalogoMarcas _cargarCatalogoMarcas() {
  final jsonStr = File('test/fixtures/marcas_catalogo.json').readAsStringSync();
  return CatalogoMarcas.fromJson(json.decode(jsonStr) as Map<String, dynamic>);
}

CatalogoProducto _p({
  required int idServicio,
  required int idProducto,
  required String servicio,
  required String producto,
  required String precio,
  int tipoFront = 1,
}) {
  return CatalogoProducto(
    idServicio: idServicio,
    idProducto: idProducto,
    servicio: servicio,
    producto: producto,
    idCatTipoServicio: 5,
    tipoFront: tipoFront,
    tipoReferencia: 'a',
    precio: precio,
    legend: null,
    hasDigitoVerificador: false,
    showAyuda: false,
  );
}

void main() {
  late CatalogoMarcas marcas;

  setUp(() {
    marcas = _cargarCatalogoMarcas();
  });

  group('resumenMarcas', () {
    test('agrupa los servicios de una misma marca', () {
      final productos = [
        _p(idServicio: 133, idProducto: 403, servicio: 'Telcel', producto: 'Recarga \$20', precio: '20.0'),
        _p(idServicio: 500, idProducto: 900, servicio: 'Telcel Datos', producto: '1GB', precio: '30.0'),
        _p(idServicio: 501, idProducto: 901, servicio: 'Telcel Pospago', producto: 'Pago', precio: '10.0'),
      ];

      final lista = resumenMarcas(productos, marcas);

      expect(lista, hasLength(1));
      expect(lista.single.slug, 'telcel');
      expect(lista.single.nombre, 'Telcel');
      expect(lista.single.cantidadProductos, 3);
    });

    test('toma el producto mas barato como punto de entrada', () {
      final productos = [
        _p(idServicio: 1, idProducto: 10, servicio: 'Telcel', producto: 'Recarga \$50', precio: '50.0'),
        _p(idServicio: 2, idProducto: 20, servicio: 'Telcel Datos', producto: 'Barato', precio: '5.5'),
        _p(idServicio: 3, idProducto: 30, servicio: 'Telcel Pospago', producto: 'Medio', precio: '25.0'),
      ];

      final marca = resumenMarcas(productos, marcas).single;

      expect(marca.precioDesde, '5.5');
      expect(marca.idServicio, 2);
      expect(marca.idProducto, 20);
    });

    test('compara precios como numero, no como texto', () {
      final productos = [
        _p(idServicio: 1, idProducto: 1, servicio: 'CFE', producto: 'Caro', precio: '100.0'),
        _p(idServicio: 1, idProducto: 2, servicio: 'CFE', producto: 'Barato', precio: '9.0'),
      ];

      expect(resumenMarcas(productos, marcas).single.precioDesde, '9.0');
    });

    test('ordena por cantidad de productos descendente', () {
      final productos = [
        _p(idServicio: 1, idProducto: 1, servicio: 'Televia', producto: 'a', precio: '10.0'),
        _p(idServicio: 2, idProducto: 2, servicio: 'Netflix', producto: 'b', precio: '10.0'),
        _p(idServicio: 3, idProducto: 3, servicio: 'Netflix', producto: 'c', precio: '10.0'),
        _p(idServicio: 4, idProducto: 4, servicio: 'Netflix', producto: 'd', precio: '10.0'),
      ];

      final lista = resumenMarcas(productos, marcas);

      expect(lista.first.slug, 'netflix');
      expect(lista.first.cantidadProductos, 3);
      expect(lista.last.slug, 'televia');
    });

    test('las marcas destacadas van primero en el orden de la BD', () {
      final productos = [
        _p(idServicio: 1, idProducto: 1, servicio: 'Netflix', producto: 'a', precio: '10.0'),
        _p(idServicio: 2, idProducto: 2, servicio: 'Netflix', producto: 'b', precio: '10.0'),
        _p(idServicio: 3, idProducto: 3, servicio: 'Netflix', producto: 'c', precio: '10.0'),
        _p(idServicio: 4, idProducto: 4, servicio: 'CFE', producto: 'd', precio: '10.0'),
      ];

      final slugs = resumenMarcas(productos, marcas).map((m) => m.slug).toList();

      expect(slugs.first, 'cfe');
    });

    test('filtra por categoria funcional (slug)', () {
      final productos = [
        _p(idServicio: 1, idProducto: 1, servicio: 'Telcel', producto: 'a', precio: '20.0'),
        _p(idServicio: 2, idProducto: 2, servicio: 'CFE', producto: 'b', precio: '10.0'),
      ];

      final tiempoAire = resumenMarcas(productos, marcas, categoriaSlug: 'tiempo_aire');
      final servicios = resumenMarcas(productos, marcas, categoriaSlug: 'servicios');

      expect(tiempoAire.single.slug, 'telcel');
      expect(servicios.single.slug, 'cfe');
    });

    test('descarta servicios sin marca en la BD', () {
      final productos = [
        _p(idServicio: 1, idProducto: 1, servicio: 'Kaspersky', producto: 'Antivirus', precio: '499.0'),
        _p(idServicio: 2, idProducto: 2, servicio: 'Oui Movil', producto: 'Recarga', precio: '10.0'),
      ];

      expect(resumenMarcas(productos, marcas), isEmpty);
    });

    test('catalogo vacio devuelve lista vacia', () {
      expect(resumenMarcas(const [], marcas), isEmpty);
    });
  });

  group('filtrarCatalogo', () {
    test('sin filtros devuelve el catalogo tal cual', () {
      final productos = [
        _p(idServicio: 1, idProducto: 1, servicio: 'Telcel', producto: 'a', precio: '20.0'),
        _p(idServicio: 2, idProducto: 2, servicio: 'CFE', producto: 'b', precio: '10.0'),
      ];

      expect(filtrarCatalogo(productos, marcas), hasLength(2));
    });

    test('busca en servicio y en producto ignorando acentos', () {
      final productos = [
        _p(idServicio: 1, idProducto: 1, servicio: 'Televia', producto: 'Recarga', precio: '10.0'),
        _p(idServicio: 2, idProducto: 2, servicio: 'Claro', producto: 'Plan', precio: '10.0'),
      ];

      expect(filtrarCatalogo(productos, marcas, busqueda: 'TELEVIA'), hasLength(1));
      expect(filtrarCatalogo(productos, marcas, busqueda: 'televía'), hasLength(1));
      expect(filtrarCatalogo(productos, marcas, busqueda: 'plan'), hasLength(1));
    });

    test('combina categoria y texto', () {
      final productos = [
        _p(idServicio: 1, idProducto: 1, servicio: 'Telcel', producto: 'Paquete', precio: '10.0'),
        _p(idServicio: 2, idProducto: 2, servicio: 'Netflix', producto: 'Paquete', precio: '10.0'),
      ];

      final ambos = filtrarCatalogo(
        productos,
        marcas,
        busqueda: 'paquete',
        categoriaSlug: 'entretenimiento',
      );

      expect(ambos, hasLength(1));
      expect(ambos.single.servicio, 'Netflix');
    });
  });

  group('conteoPorCategoria', () {
    test('cuenta productos por categoria y omite los sin marca', () {
      final productos = [
        _p(idServicio: 1, idProducto: 1, servicio: 'Telcel', producto: 'a', precio: '20.0'),
        _p(idServicio: 2, idProducto: 2, servicio: 'Telcel Datos', producto: 'b', precio: '20.0'),
        _p(idServicio: 3, idProducto: 3, servicio: 'CFE', producto: 'c', precio: '10.0'),
        _p(idServicio: 4, idProducto: 4, servicio: 'Cinepolis', producto: 'd', precio: '10.0'),
        _p(idServicio: 5, idProducto: 5, servicio: 'Oui Movil', producto: 'e', precio: '10.0'),
      ];

      final conteo = conteoPorCategoria(productos, marcas);

      expect(conteo['tiempo_aire'], 2);
      expect(conteo['servicios'], 1);
      expect(conteo['entretenimiento'], 1);
      expect(conteo.length, 3);
    });

    test('no incluye categorias con cero productos', () {
      expect(conteoPorCategoria(const [], marcas), isEmpty);
    });
  });
}
