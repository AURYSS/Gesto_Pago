import '../../../core/network/app_exception.dart';

/// Categorías de pago de servicios soportadas por la app.
/// Valores compatibles con la clasificación del proveedor (idCatTipoServicio).
abstract final class CatalogoCategorias {
  static const int pagoServicios = 5;
  static const int pagoImpuestos = 7;
  static const int pagoDerechosAgua = 15;
}

/// Producto/servicio del catálogo autoritativo servido por el backend.
///
/// El `precio` se conserva como texto para no degradar precisión decimal
/// (el cliente solo muestra; el servidor es la fuente de verdad).
class CatalogoProducto {
  const CatalogoProducto({
    required this.idServicio,
    required this.idProducto,
    required this.servicio,
    required this.producto,
    required this.idCatTipoServicio,
    required this.tipoFront,
    required this.tipoReferencia,
    required this.precio,
    required this.legend,
    required this.hasDigitoVerificador,
    required this.showAyuda,
  });

  factory CatalogoProducto.fromJson(Map<String, dynamic> json) {
    final idServicio = json['idServicio'];
    final idProducto = json['idProducto'];
    if (idServicio is! num || idProducto is! num) {
      throw const SerializationException('Producto sin identificadores válidos.');
    }
    return CatalogoProducto(
      idServicio: idServicio.toInt(),
      idProducto: idProducto.toInt(),
      servicio: json['servicio'] as String? ?? '',
      producto: json['producto'] as String? ?? '',
      idCatTipoServicio: (json['idCatTipoServicio'] as num?)?.toInt() ?? 0,
      tipoFront: (json['tipoFront'] as num?)?.toInt() ?? 0,
      tipoReferencia: json['tipoReferencia'] as String? ?? '',
      precio: json['precio']?.toString() ?? '0',
      legend: json['legend'] as String?,
      hasDigitoVerificador: json['hasDigitoVerificador'] as bool? ?? false,
      showAyuda: json['showAyuda'] as bool? ?? false,
    );
  }

  final int idServicio;
  final int idProducto;
  final String servicio;
  final String producto;
  final int idCatTipoServicio;
  final int tipoFront;
  final String tipoReferencia;
  final String precio;
  final String? legend;
  final bool hasDigitoVerificador;
  final bool showAyuda;

  /// true cuando el precio es final (recargas); false cuando es comisión
  /// (pagos de servicio), según la documentación del proveedor.
  bool get esPrecioFinal => tipoFront == 1;

  /// true cuando la referencia del pago viene del recibo del servicio.
  bool get esPagoServicio => tipoFront == 2;

  @override
  String toString() => 'CatalogoProducto(idServicio: $idServicio, idProducto: $idProducto, '
      'producto: $producto, tipoFront: $tipoFront, tipoReferencia: $tipoReferencia)';
}