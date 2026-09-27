/// Modelo de un plan de pago a plazos.
///
/// Es una simulación de cálculo pensada para que el usuario compare
/// opciones antes de pagar. El importe final siempre lo determina el
/// proveedor: aqui solo se proyecta el costo de financiar el monto.
class PlanPago {
  const PlanPago({
    required this.meses,
    required this.monto,
    required this.tasaAnual,
    required this.cuota,
    required this.totalPagar,
    required this.costoFinanciero,
  });

  /// Numero de meses del plan.
  final int meses;

  /// Monto a financiar (sin financiamiento).
  final double monto;

  /// Tasa anual aplicada, en porcentaje.
  final double tasaAnual;

  /// Cuota mensual resultante.
  final double cuota;

  /// Suma de todas las cuotas.
  final double totalPagar;

  /// [totalPagar] menos [monto]: el costo extra del financiamiento.
  final double costoFinanciero;

  /// true cuando el plan no tiene costo adicional.
  bool get sinCosto => costoFinanciero <= 0.01;
}

/// Calcula cuotas y costos de un pago a plazos.
///
/// Usa amortización con interés compuesto sobre el saldo insoluto:
/// cuota = monto * (i(1+i)^n) / ((1+i)^n - 1), donde `i` es la tasa
/// mensual equivalente a la anual.
///
/// El redondeo se hace a dos decimales porque es la unidad que ve y
/// compara el usuario; los cálculos intermedios conservan precisión.
abstract final class PlanCalculo {
  /// Meses ofrecidos por defecto.
  static const List<int> plazosDisponibles = [3, 6, 12];

  /// Tasa anual por defecto para la simulación.
  static const double tasaAnualPorDefecto = 12.0;

  /// Tasa anual sugerida por plazo. A menor plazo, menor tasa.
  static const Map<int, double> tasaSugeridaPorPlazo = {
    3: 6.0,
    6: 9.0,
    12: 12.0,
  };

  /// Calcula el plan para [monto] a [meses] con [tasaAnual] por ciento.
  ///
  /// Devuelve null si el monto no es positivo o el plazo no es valido.
  static PlanPago? calcular({
    required double monto,
    required int meses,
    double? tasaAnual,
  }) {
    if (monto <= 0 || meses <= 0) {
      return null;
    }

    final tasa = tasaAnual ?? tasaSugeridaPorPlazo[meses] ?? tasaAnualPorDefecto;
    final i = tasa / 100 / 12;

    double cuota;
    if (i <= 0) {
      // Sin interes: el monto se reparte en partes iguales.
      cuota = monto / meses;
    } else {
      final factor = _pow(1 + i, meses);
      cuota = monto * (i * factor) / (factor - 1);
    }

    final cuotaRedondeada = _redondear(cuota);
    final total = _redondear(cuotaRedondeada * meses);

    return PlanPago(
      meses: meses,
      monto: monto,
      tasaAnual: tasa,
      cuota: cuotaRedondeada,
      totalPagar: total,
      costoFinanciero: _redondear(total - monto),
    );
  }

  /// Calcula todos los plazos disponibles para [monto] de una vez.
  ///
  /// Devuelve solo los planes validos, en el orden de
  /// [plazosDisponibles], listos para pintarse como comparativa.
  static List<PlanPago> comparar({
    required double monto,
    List<int> plazos = plazosDisponibles,
  }) {
    final planes = <PlanPago>[];
    for (final meses in plazos) {
      final plan = calcular(monto: monto, meses: meses);
      if (plan != null) {
        planes.add(plan);
      }
    }
    return planes;
  }

  /// Tasa anual sugerida para un plazo, o la tasa por defecto.
  static double tasaParaPlazo(int meses) =>
      tasaSugeridaPorPlazo[meses] ?? tasaAnualPorDefecto;

  /// Potencia con excepcion entera, sin depender de `dart:math` para
  /// mantener el dominio puro y testeable.
  static double _pow(double base, int exp) {
    var resultado = 1.0;
    for (var i = 0; i < exp; i++) {
      resultado *= base;
    }
    return resultado;
  }

  /// Redondea a dos decimales, que es la unidad que compara el usuario.
  /// Los calculos intermedios conservan precision completa; el redondeo
  /// se aplica una sola vez, al presentar la cifra.
  static double _redondear(double valor) {
    final escalado = (valor * 100).roundToDouble();
    return escalado / 100;
  }
}
