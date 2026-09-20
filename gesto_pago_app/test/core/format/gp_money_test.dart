import 'package:flutter_test/flutter_test.dart';

import 'package:gesto_pago_app/core/format/gp_money.dart';

void main() {
  group('GpMoney.format', () {
    test('formatea con símbolo y separadores', () {
      expect(GpMoney.format('1234.5'), contains('1,234.50'));
      expect(GpMoney.format('1234.5'), startsWith(r'$'));
    });

    test('cero y decimales', () {
      expect(GpMoney.format('0'), contains('0.00'));
    });

    test('valores inválidos pasan tal cual', () {
      expect(GpMoney.format('abc'), 'abc');
    });
  });

  group('GpMoney.sanitizarEntrada', () {
    test('quita caracteres no numéricos', () {
      expect(GpMoney.sanitizarEntrada('abc12.3.4'), '12.34');
    });

    test('convierte coma a punto', () {
      expect(GpMoney.sanitizarEntrada('1,50'), '1.50');
    });
  });
}