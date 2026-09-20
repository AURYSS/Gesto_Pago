import '../../../core/network/app_exception.dart';
import 'estado_transaccion.dart';

/// Transacción de pago registrada por el backend.
///
/// Los montos se conservan como texto (precisión decimal). El estado lo
/// determina el proveedor vía el backend, nunca la interfaz.
class Transaccion {
  const Transaccion({
    required this.id,
    required this.upc,
    required this.idServicio,
    required this.idProducto,
    required this.servicio,
    required this.producto,
    required this.referencia,
    required this.monto,
    required this.comision,
    required this.estado,
    required this.numeroAutorizacion,
    required this.idTx,
    required this.pin,
    required this.legend,
    required this.errorMensaje,
    required this.fecha,
  });

  factory Transaccion.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    if (id is! num) {
      throw const SerializationException('Transacción sin id.');
    }
    return Transaccion(
      id: id.toInt(),
      upc: json['upc'] as String? ?? '',
      idServicio: (json['idServicio'] as num?)?.toInt() ?? 0,
      idProducto: (json['idProducto'] as num?)?.toInt() ?? 0,
      servicio: json['servicio'] as String? ?? '',
      producto: json['producto'] as String? ?? '',
      referencia: json['referencia'] as String? ?? '',
      monto: json['monto']?.toString() ?? '0',
      comision: json['comision']?.toString() ?? '0',
      estado: EstadoTransaccion.fromApi(json['estado'] as String? ?? ''),
      numeroAutorizacion: json['numeroAutorizacion'] as String? ?? '',
      idTx: json['idTx'] as String? ?? '',
      pin: json['pin'] as String? ?? '',
      legend: json['legend'] as String?,
      errorMensaje: json['errorMensaje'] as String?,
      fecha: json['fecha'] as String? ?? '',
    );
  }

  final int id;
  final String upc;
  final int idServicio;
  final int idProducto;
  final String servicio;
  final String producto;
  final String referencia;
  final String monto;
  final String comision;
  final EstadoTransaccion estado;
  final String numeroAutorizacion;
  final String idTx;
  final String pin;
  final String? legend;
  final String? errorMensaje;
  final String fecha;

  bool get esAprobada => estado == EstadoTransaccion.aprobada;
}

/// Referencia verificada contra el proveedor (monto autoritativo).
class VerificacionReferencia {
  const VerificacionReferencia({required this.valida, required this.monto, required this.mensaje});

  factory VerificacionReferencia.fromJson(Map<String, dynamic> json) {
    final codigo = (json['codigo'] as num?)?.toInt();
    return VerificacionReferencia(
      valida: codigo == 0,
      monto: json['monto']?.toString(),
      mensaje: json['mensaje'] as String? ?? '',
    );
  }

  final bool valida;
  final String? monto;
  final String mensaje;
}