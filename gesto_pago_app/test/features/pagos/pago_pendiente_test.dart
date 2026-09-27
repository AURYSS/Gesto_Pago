import 'package:flutter_test/flutter_test.dart';
import 'package:gesto_pago_app/features/pagos/domain/estado_transaccion.dart';
import 'package:gesto_pago_app/features/pagos/domain/pago_pendiente.dart';

void main() {
  group('PagoPendiente.fromJson', () {
    test('mapea transaccion en proceso lista para confirmar', () {
      final json = {
        'id': 101,
        'idServicio': 166,
        'idProducto': 597,
        'servicio': 'CFE',
        'producto': 'Pago de recibo',
        'referencia': '1234567890',
        'monto': '1847.50',
        'comision': '10.00',
        'estado': 'EN_PROCESO',
        'fecha': '2026-09-26T12:00:00Z',
        'errorMensaje': null,
        'puedeConfirmar': true,
        'puedeReintentar': false,
      };

      final p = PagoPendiente.fromJson(json);

      expect(p.id, 101);
      expect(p.idServicio, 166);
      expect(p.idProducto, 597);
      expect(p.servicio, 'CFE');
      expect(p.producto, 'Pago de recibo');
      expect(p.monto, '1847.50');
      expect(p.estado, EstadoTransaccion.enProceso);
      expect(p.puedeConfirmar, isTrue);
      expect(p.puedeReintentar, isFalse);
    });

    test('mapea transaccion fallida reintentable', () {
      final json = {
        'id': 102,
        'idServicio': 85,
        'idProducto': 215,
        'servicio': 'Totalplay',
        'producto': 'Internet',
        'referencia': '987654321',
        'monto': '649.00',
        'comision': '0.00',
        'estado': 'FALLIDA',
        'fecha': '2026-09-26T12:05:00Z',
        'errorMensaje': 'El proveedor rechazo la operacion',
        'puedeConfirmar': false,
        'puedeReintentar': true,
      };

      final p = PagoPendiente.fromJson(json);

      expect(p.id, 102);
      expect(p.estado, EstadoTransaccion.fallida);
      expect(p.errorMensaje, 'El proveedor rechazo la operacion');
      expect(p.puedeConfirmar, isFalse);
      expect(p.puedeReintentar, isTrue);
    });

    test('serializa a json conservando campos', () {
      final p = PagoPendiente(
        id: 103,
        idServicio: 76,
        idProducto: 205,
        servicio: 'Telcel',
        producto: 'Recarga 100',
        referencia: '5512345678',
        monto: '100.00',
        estado: EstadoTransaccion.pendiente,
        puedeConfirmar: false,
        puedeReintentar: true,
      );

      final map = p.toJson();

      expect(map['id'], 103);
      expect(map['servicio'], 'Telcel');
      expect(map['monto'], '100.00');
      expect(map['estado'], 'pendiente');
      expect(map['puedeReintentar'], isTrue);
    });
  });
}
