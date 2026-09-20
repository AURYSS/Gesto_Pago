import 'transaccion.dart';

/// Parámetros para iniciar un pago de servicio.
class PagoRequest {
  const PagoRequest({
    required this.idServicio,
    required this.idProducto,
    required this.referencia,
    required this.monto,
    required this.idempotencyKey,
  });

  final int idServicio;
  final int idProducto;
  final String referencia;
  final String monto;

  /// Identificador único de la intención de pago: estable entre reintentos
  /// para no duplicar cargos (idempotencia).
  final String idempotencyKey;

  Map<String, dynamic> toJson() => {
        'idServicio': idServicio,
        'idProducto': idProducto,
        'referencia': referencia,
        'monto': monto,
        'idempotencyKey': idempotencyKey,
      };
}

abstract interface class PagosRepository {
  Future<VerificacionReferencia> verificarReferencia({
    required int idServicio,
    required int idProducto,
    required String referencia,
  });

  Future<Transaccion> crearTransaccion(PagoRequest request);

  Future<Transaccion> confirmarTransaccion(int id);

  Future<List<Transaccion>> historial();
}