import 'package:flutter_test/flutter_test.dart';
import 'package:gesto_pago_app/core/validation/referencia_validator.dart';

void main() {
  group('ReferenciaValidator', () {
    test('rechaza referencia vacia o solo con signos', () {
      expect(ReferenciaValidator.validar('').mensaje, ReferenciaValidator.errorVacio);
      expect(ReferenciaValidator.validar('   ').mensaje, ReferenciaValidator.errorVacio);
      expect(ReferenciaValidator.validar('***').mensaje, ReferenciaValidator.errorFormato);
    });

    test('tipo a exige movil de 10 digitos', () {
      expect(ReferenciaValidator.validar('5512345678', tipoReferencia: 'a').valido, isTrue);
      expect(ReferenciaValidator.validar('551234567', tipoReferencia: 'a').mensaje,
          ReferenciaValidator.errorMovil);
      expect(ReferenciaValidator.validar('55123456789', tipoReferencia: 'a').mensaje,
          ReferenciaValidator.errorMovil);
    });

    test('tipo a ignora espacios y guiones al contar', () {
      expect(ReferenciaValidator.validar('551 234-5678', tipoReferencia: 'a').valido, isTrue);
    });

    test('tipo b exige 12 a 20 digitos y al menos dos letras', () {
      // CLABE: 18 digitos + digito de control en letra.
      expect(
        ReferenciaValidator.validar('012180001234567890AB', tipoReferencia: 'b').valido,
        isTrue,
      );
      expect(
        ReferenciaValidator.validar('CLABE123', tipoReferencia: 'b').mensaje,
        ReferenciaValidator.errorLargo,
      );
      expect(
        ReferenciaValidator.validar('12345678901234', tipoReferencia: 'b').mensaje,
        ReferenciaValidator.errorCuenta,
      );
    });

    test('tipo c solo admite letras entre 4 y 24', () {
      expect(ReferenciaValidator.validar('CORREO', tipoReferencia: 'c').valido, isTrue);
      expect(ReferenciaValidator.validar('ABC1', tipoReferencia: 'c').mensaje,
          ReferenciaValidator.errorCuenta);
      expect(ReferenciaValidator.validar('AB', tipoReferencia: 'c').mensaje,
          ReferenciaValidator.errorLargo);
    });

    test('tipo ab acepta movil de 10 o cuenta de 12 a 20', () {
      expect(ReferenciaValidator.validar('5512345678', tipoReferencia: 'ab').valido, isTrue);
      expect(ReferenciaValidator.validar('123456789012', tipoReferencia: 'ab').valido, isTrue);
      expect(ReferenciaValidator.validar('12345', tipoReferencia: 'ab').mensaje,
          ReferenciaValidator.errorCuenta);
    });

    test('tipo bc acepta recibos desde 6 digitos', () {
      expect(ReferenciaValidator.validar('123456', tipoReferencia: 'bc').valido, isTrue);
      expect(ReferenciaValidator.validar('12345', tipoReferencia: 'bc').mensaje,
          ReferenciaValidator.errorCorto);
    });

    test('tipo d acepta 4 a 24 caracteres', () {
      expect(ReferenciaValidator.validar('ABCD', tipoReferencia: 'd').valido, isTrue);
      expect(ReferenciaValidator.validar('ABC', tipoReferencia: 'd').mensaje,
          ReferenciaValidator.errorLargo);
      expect(ReferenciaValidator.validar('A' * 25, tipoReferencia: 'd').mensaje,
          ReferenciaValidator.errorLargo);
    });

    test('digito verificador exige la longitud exacta declarada', () {
      final referencia18 = '123456789012345678';
      expect(
        ReferenciaValidator.validar(referencia18, conDigitoVerificador: true).valido,
        isTrue,
      );
      expect(
        ReferenciaValidator.validar('12345678901234567', conDigitoVerificador: true).mensaje,
        ReferenciaValidator.errorDigito,
      );
      expect(
        ReferenciaValidator.validar(
          '1234567890123456789012',
          conDigitoVerificador: true,
          digitosEsperados: 22,
        ).valido,
        isTrue,
      );
    });

    test('el digito verificador tiene prioridad sobre el tipo', () {
      // 10 digitos no cumple tipo a, pero si la longitud de 18 con digito.
      expect(
        ReferenciaValidator.validar(
          '123456789012345678',
          tipoReferencia: 'a',
          conDigitoVerificador: true,
        ).valido,
        isTrue,
      );
    });
  });
}
