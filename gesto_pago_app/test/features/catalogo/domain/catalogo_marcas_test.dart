import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gesto_pago_app/features/catalogo/domain/catalogo_marca.dart';

CatalogoMarcas _cargarCatalogoDePrueba() {
  final jsonStr = File('test/fixtures/marcas_catalogo.json').readAsStringSync();
  final map = json.decode(jsonStr) as Map<String, dynamic>;
  return CatalogoMarcas.fromJson(map);
}

void main() {
  late CatalogoMarcas catalogo;

  setUp(() {
    catalogo = _cargarCatalogoDePrueba();
  });

  group('CatalogoMarcas.slugDe', () {
    test('resuelve coincidencia exacta', () {
      expect(catalogo.slugDe('Telcel'), 'telcel');
      expect(catalogo.slugDe('CFE'), 'cfe');
      expect(catalogo.slugDe('netflix'), 'netflix');
    });

    test('resuelve sufijos y afijos del catalogo real', () {
      expect(catalogo.slugDe('Telcel Datos'), 'telcel');
      expect(catalogo.slugDe('Telcel Paquetes Amigo'), 'telcel');
      expect(catalogo.slugDe('Telcel Paquetes de Datos'), 'telcel');
      expect(catalogo.slugDe('Bait Internet Portatil'), 'bait');
      expect(catalogo.slugDe('IZZI Telecom'), 'izzi');
      expect(catalogo.slugDe('SKY - VeTv'), 'sky');
      expect(catalogo.slugDe('Naturgy (Gas Natural)'), 'naturgy');
    });

    test('resuelve la marca partida en varios tokens', () {
      expect(catalogo.slugDe('AT-T'), 'att');
      expect(catalogo.slugDe('AT-T Pospago'), 'att');
    });

    test('NO resuelve marcas que solo aparecen como subcadena', () {
      expect(catalogo.slugDe('Kaspersky'), isNull);
      expect(catalogo.slugDe('Kaspersky Internet Security'), isNull);
      expect(catalogo.slugDe('Kaspersky Cloud Password Manager'), isNull);
    });

    test('devuelve null cuando no hay logo o marca', () {
      expect(catalogo.slugDe('Oui Movil'), isNull);
      expect(catalogo.slugDe('BigCel'), isNull);
      expect(catalogo.slugDe(''), isNull);
      expect(catalogo.slugDe('!!!'), isNull);
    });

    test('la clave corta "sat" no se cuelga de cualquier prefijo', () {
      expect(catalogo.slugDe('Sasa Movil'), isNull);
      expect(catalogo.slugDe('Satelite TV'), isNull);
      expect(catalogo.slugDe('SAT'), 'sat');
    });

    test('cubre las marcas que solo trae el paquete grande de logos', () {
      expect(catalogo.slugDe('Cinepolis'), 'cinepolis');
      expect(catalogo.slugDe('Virgin Mobile Paquetes'), 'virgin_mobile');
      expect(catalogo.slugDe('Cinemex'), 'cinemex');
      expect(catalogo.slugDe('StarTV'), 'startv');
      expect(catalogo.slugDe('Engie MaxiGas'), 'engie');
    });

    test('todo logoAsset de las marcas existe en disco', () {
      for (final marca in catalogo.marcas) {
        if (marca.logoAsset != null) {
          expect(
            marca.logoAsset,
            anyOf(
              startsWith('assets/images/marcas/'),
              startsWith('assets/logos/'),
            ),
            reason: 'ruta inesperada para ${marca.slug}',
          );
          expect(marca.logoAsset!.endsWith('.png'), isTrue,
              reason: 'no es png: ${marca.slug}');
          expect(File(marca.logoAsset!).existsSync(), isTrue,
              reason: 'el archivo no existe: ${marca.logoAsset}');
        }
      }
    });
  });

  group('CatalogoMarcas consultas de dominio', () {
    test('slug, color y nombre salen de la misma marca', () {
      expect(catalogo.slugDe('Telcel Datos'), 'telcel');
      expect(catalogo.nombreDe('Telcel Datos'), 'Telcel');
      expect(catalogo.colorDe('Telcel Datos'), isNotNull);
    });

    test('sin marca no inventa color', () {
      expect(catalogo.slugDe('Oui Movil'), isNull);
      expect(catalogo.colorDe('Oui Movil'), isNull);
      expect(catalogo.nombreDe('Oui Movil'), 'Oui Movil');
      expect(catalogo.categoriaDe('Oui Movil'), isNull);
    });

    test('marca con logo pero sin color oficial devuelve null', () {
      expect(catalogo.slugDe('Tupperware'), 'tupperware');
      expect(catalogo.categoriaDe('Tupperware'), 'servicios');
      expect(catalogo.colorDe('Tupperware'), isNull);
    });

    test('clasifica marcas en categorias funcionales por slug', () {
      expect(catalogo.categoriaDe('Telcel'), 'tiempo_aire');
      expect(catalogo.categoriaDe('IZZI Telecom'), 'internet');
      expect(catalogo.categoriaDe('SKY - VeTv'), 'television');
      expect(catalogo.categoriaDe('Netflix'), 'entretenimiento');
      expect(catalogo.categoriaDe('CFE'), 'servicios');
      expect(catalogo.categoriaDe('Pase'), 'transporte');
    });

    test('las marcas destacadas vienen en su orden declarado', () {
      final destacadas = catalogo.destacadas();
      expect(destacadas.isNotEmpty, isTrue);
      expect(destacadas.map((m) => m.slug).toList(), [
        'telcel',
        'cfe',
        'izzi',
        'sky',
        'att',
      ]);
    });
  });
}
