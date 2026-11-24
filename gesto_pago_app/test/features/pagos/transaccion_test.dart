import 'package:flutter_test/flutter_test.dart';
import 'package:gesto_pago_app/features/pagos/domain/estado_transaccion.dart';
import 'package:gesto_pago_app/features/pagos/domain/pago_pendiente.dart';
import 'package:gesto_pago_app/features/pagos/domain/transaccion.dart';

void main() {
  group('Transaccion', () {
    test('fromJson deserializa transaccion exitosa', () {
      final json = {
        'id': 101,
        'upc': '123456',
        'idServicio': 1,
        'idProducto': 2,
        'servicio': 'CFE',
        'producto': 'Pago de Luz',
        'referencia': '012345678901',
        'monto': '250.00',
        'comision': '12.00',
        'estado': 'APROBADA',
        'numeroAutorizacion': 'AUT-999',
        'idTx': 'TX-888',
        'pin': '',
        'legend': 'Transaccion exitosa',
        'fecha': '2026-11-23T10:00:00Z',
      };

      final tx = Transaccion.fromJson(json);

      expect(tx.id, 101);
      expect(tx.estado, EstadoTransaccion.aprobada);
      expect(tx.esAprobada, isTrue);
      expect(tx.numeroAutorizacion, 'AUT-999');
      expect(tx.codigoError, isNull);
      expect(tx.errorMensaje, isNull);
    });

    test('fromJson deserializa transaccion rechazada con codigoError y errorMensaje', () {
      final json = {
        'id': 102,
        'upc': '123456',
        'idServicio': 1,
        'idProducto': 2,
        'servicio': 'Telcel',
        'producto': 'Recarga 100',
        'referencia': '5512345678',
        'monto': '100.00',
        'comision': '0.00',
        'estado': 'RECHAZADA',
        'numeroAutorizacion': '',
        'idTx': 'TX-777',
        'pin': '',
        'codigoError': 'GP-4001',
        'errorMensaje': 'Fondos insuficientes en el distribuidor',
        'fecha': '2026-11-23T10:05:00Z',
      };

      final tx = Transaccion.fromJson(json);

      expect(tx.id, 102);
      expect(tx.estado, EstadoTransaccion.fallida);
      expect(tx.esAprobada, isFalse);
      expect(tx.codigoError, 'GP-4001');
      expect(tx.errorMensaje, 'Fondos insuficientes en el distribuidor');
    });

    test('fromJson toma codigoMensaje como fallback de codigoError', () {
      final json = {
        'id': 103,
        'servicio': 'Izzi',
        'producto': 'Internet',
        'referencia': '99887766',
        'monto': '500.00',
        'estado': 'FALLIDA',
        'codigoMensaje': '105',
        'mensaje': 'Servicio temporalmente no disponible',
        'fecha': '2026-11-23T10:10:00Z',
      };

      final tx = Transaccion.fromJson(json);

      expect(tx.id, 103);
      expect(tx.estado, EstadoTransaccion.fallida);
      expect(tx.codigoError, '105');
      expect(tx.errorMensaje, 'Servicio temporalmente no disponible');
    });
  });

  group('PagoPendiente', () {
    test('fromJson deserializa correctamente codigoError y errorMensaje', () {
      final json = {
        'id': 201,
        'idServicio': 3,
        'idProducto': 4,
        'servicio': 'Naturgy',
        'producto': 'Gas Natural',
        'referencia': '11223344',
        'monto': '320.50',
        'estado': 'FALLIDA',
        'codigoError': 'ERR-99',
        'errorMensaje': 'Referencia no encontrada',
        'puedeReintentar': true,
      };

      final pendiente = PagoPendiente.fromJson(json);

      expect(pendiente.id, 201);
      expect(pendiente.estado, EstadoTransaccion.fallida);
      expect(pendiente.codigoError, 'ERR-99');
      expect(pendiente.errorMensaje, 'Referencia no encontrada');
      expect(pendiente.puedeReintentar, isTrue);

      final map = pendiente.toJson();
      expect(map['codigoError'], 'ERR-99');
      expect(map['errorMensaje'], 'Referencia no encontrada');
    });
  });
}
