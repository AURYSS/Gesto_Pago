import 'package:intl/intl.dart';

/// Formateo de cantidades monetarias del app.
abstract final class GpMoney {
  static final NumberFormat _formateador = NumberFormat.currency(
    locale: 'es_MX',
    symbol: r'$',
    decimalDigits: 2,
  );

  /// Convierte la cantidad (siempre string en el dominio) a moneda.
  static String format(String monto) {
    final valor = double.tryParse(monto);
    if (valor == null) {
      return monto;
    }
    return _formateador.format(valor);
  }

  /// Solo dígitos/decimal para entrada en campos de texto.
  static String sanitizarEntrada(String texto) {
    final limpiado = texto.replaceAll(',', '.').replaceAll(RegExp(r'[^0-9.]'), '');
    final partes = limpiado.split('.');
    if (partes.length > 2) {
      return '${partes.first}.${partes.sublist(1).join()}';
    }
    return limpiado;
  }
}