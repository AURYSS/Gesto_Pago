import 'package:flutter_test/flutter_test.dart';

import 'package:gesto_pago_app/features/pagos/domain/estado_transaccion.dart';

void main() {
  group('EstadoTransaccion.fromApi', () {
    test('mapea estados conocidos', () {
      expect(EstadoTransaccion.fromApi('APROBADA'), EstadoTransaccion.aprobada);
      expect(EstadoTransaccion.fromApi('APROBADO'), EstadoTransaccion.aprobada);
      expect(EstadoTransaccion.fromApi('EN_PROCESO'), EstadoTransaccion.enProceso);
      expect(EstadoTransaccion.fromApi('PROCESANDO'), EstadoTransaccion.enProceso);
      expect(EstadoTransaccion.fromApi('PENDIENTE'), EstadoTransaccion.pendiente);
    });

    test('desconocidos caen en fallida', () {
      expect(EstadoTransaccion.fromApi('XXXX'), EstadoTransaccion.fallida);
      expect(EstadoTransaccion.fromApi(''), EstadoTransaccion.fallida);
    });
  });
}