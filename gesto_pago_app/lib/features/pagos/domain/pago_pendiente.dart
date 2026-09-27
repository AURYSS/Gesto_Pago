import 'estado_transaccion.dart';

/// Transaccion o pago pendiente de resolucion para el usuario.
///
/// No es un recibo con fecha de vencimiento inventada: son las transacciones
/// que el usuario envio y siguen sin concluirse (EN_PROCESO, PENDIENTE o FALLIDA
/// reintentable).
class PagoPendiente {
  const PagoPendiente({
    required this.id,
    required this.idServicio,
    required this.idProducto,
    required this.servicio,
    required this.producto,
    required this.referencia,
    required this.monto,
    this.comision,
    required this.estado,
    this.fecha,
    this.errorMensaje,
    this.puedeConfirmar = false,
    this.puedeReintentar = false,
  });

  final int id;
  final int idServicio;
  final int idProducto;
  final String servicio;
  final String producto;
  final String referencia;
  final String monto;
  final String? comision;
  final EstadoTransaccion estado;
  final String? fecha;
  final String? errorMensaje;
  final bool puedeConfirmar;
  final bool puedeReintentar;

  factory PagoPendiente.fromJson(Map<String, dynamic> json) {
    return PagoPendiente(
      id: (json['id'] as num?)?.toInt() ?? 0,
      idServicio: (json['idServicio'] as num?)?.toInt() ?? 0,
      idProducto: (json['idProducto'] as num?)?.toInt() ?? 0,
      servicio: json['servicio'] as String? ?? '',
      producto: json['producto'] as String? ?? '',
      referencia: json['referencia'] as String? ?? '',
      monto: json['monto'] as String? ?? '0.00',
      comision: json['comision'] as String?,
      estado: EstadoTransaccion.fromApi(json['estado'] as String? ?? ''),
      fecha: json['fecha'] as String?,
      errorMensaje: json['errorMensaje'] as String?,
      puedeConfirmar: json['puedeConfirmar'] as bool? ?? false,
      puedeReintentar: json['puedeReintentar'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'idServicio': idServicio,
        'idProducto': idProducto,
        'servicio': servicio,
        'producto': producto,
        'referencia': referencia,
        'monto': monto,
        'comision': comision,
        'estado': estado.name,
        'fecha': fecha,
        'errorMensaje': errorMensaje,
        'puedeConfirmar': puedeConfirmar,
        'puedeReintentar': puedeReintentar,
      };

  @override
  String toString() =>
      'PagoPendiente(id: $id, servicio: $servicio, producto: $producto, monto: $monto, estado: $estado)';
}
