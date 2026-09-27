import 'package:flutter_test/flutter_test.dart';
import 'package:gesto_pago_app/core/text/texto_normalizado.dart';
import 'package:gesto_pago_app/features/catalogo/domain/catalogo_marca.dart';

void main() {
  group('normalizarTexto', () {
    test('quita acentos y baja a minusculas', () {
      expect(normalizarTexto('Televía'), 'televia');
      expect(normalizarTexto('CFE'), 'cfe');
      expect(normalizarTexto('Ñandú'), 'nandu');
    });

    test('mapea cada vocal acentuada a la vocal simple', () {
      // Regresion: el mapa anterior tenia un caracter menos del que deberia
      // y a partir del indice 17 todo se corria una posicion, asi que "õ" daba
      // "u", "û" daba "n" y "ñ" daba "c".
      const pares = {
        'á': 'a', 'à': 'a', 'ä': 'a', 'â': 'a', 'ã': 'a', 'å': 'a',
        'é': 'e', 'è': 'e', 'ë': 'e', 'ê': 'e',
        'í': 'i', 'ì': 'i', 'ï': 'i', 'î': 'i',
        'ó': 'o', 'ò': 'o', 'ö': 'o', 'ô': 'o', 'õ': 'o',
        'ú': 'u', 'ù': 'u', 'ü': 'u', 'û': 'u',
        'ñ': 'n', 'ç': 'c',
      };
      pares.forEach((con, sin) {
        expect(normalizarTexto(con), sin, reason: 'falla la vocal $con');
        expect(normalizarTexto(con.toUpperCase()), sin,
            reason: 'falla la vocal ${con.toUpperCase()}');
      });
    });

    test('acepta acentos combinantes, no solo los precompuestos', () {
      // El teclado de Android e iOS escribe "i" + U+0301 en vez de "í".
      expect(normalizarTexto('televi\u0301a'), 'televia');
      expect(normalizarTexto('n\u0303'), 'n');
    });

    test('colapsa espacios y recorta', () {
      expect(normalizarTexto('  cinemex   platino '), 'cinemex platino');
      expect(normalizarTexto(''), '');
      expect(normalizarTexto('   '), '');
    });

    test('deja intacto lo que no es letra', () {
      expect(normalizarTexto('100 MB'), '100 mb');
      expect(normalizarTexto(r'$20.00'), r'$20.00');
    });
  });

  group('slugify', () {
    test('une separadores en guiones bajos', () {
      expect(slugify('Virgin Mobile Paquetes'), 'virgin_mobile_paquetes');
      expect(slugify('AT-T'), 'at_t');
      expect(slugify('Naturgy (Gas Natural)'), 'naturgy_gas_natural');
    });

    test('recorta guiones de los extremos', () {
      expect(slugify('  Telcel  '), 'telcel');
      expect(slugify('!!!'), '');
    });

    test('normaliza acentos antes de convertir', () {
      expect(slugify('Añejo'), 'anejo');
    });

    test('CatalogoMarcas.normalizarSlug usa la misma regla', () {
      for (final nombre in ['Telcel', 'AT-T', 'CFE', 'IZZI Telecom']) {
        expect(CatalogoMarcas.normalizarSlug(nombre), slugify(nombre));
      }
    });
  });
}
