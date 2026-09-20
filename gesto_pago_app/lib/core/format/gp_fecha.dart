import 'package:intl/intl.dart';

/// Da formato a fechas ISO-8601 (UTC) del backend en la zona local.
///
/// Valores difícilmente parseables se devuelven tal cual.
String formatFecha(String isoFecha) {
  final fecha = DateTime.tryParse(isoFecha)?.toLocal();
  if (fecha == null) {
    return isoFecha;
  }
  return DateFormat(
    'd MMM yyyy, HH:mm',
    Intl.getCurrentLocale(),
  ).format(fecha);
}