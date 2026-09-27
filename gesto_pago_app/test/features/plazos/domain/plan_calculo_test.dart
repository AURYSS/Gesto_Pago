import 'package:flutter_test/flutter_test.dart';
import 'package:gesto_pago_app/features/plazos/domain/plan_calculo.dart';

void main() {
  group('PlanCalculo', () {
    test('rechaza montos y plazos no positivos', () {
      expect(PlanCalculo.calcular(monto: 0, meses: 6), isNull);
      expect(PlanCalculo.calcular(monto: -100, meses: 6), isNull);
      expect(PlanCalculo.calcular(monto: 100, meses: 0), isNull);
    });

    test('sin interes reparte el monto en partes iguales', () {
      final plan = PlanCalculo.calcular(monto: 1200, meses: 6, tasaAnual: 0)!;
      expect(plan.cuota, 200);
      expect(plan.totalPagar, 1200);
      expect(plan.sinCosto, isTrue);
    });

    test('con interes la cuota supera la division simple', () {
      final plan = PlanCalculo.calcular(monto: 1200, meses: 6, tasaAnual: 12)!;
      expect(plan.cuota, greaterThan(200));
      expect(plan.totalPagar, greaterThan(1200));
      expect(plan.costoFinanciero, greaterThan(0));
    });

    test('a mayor plazo la cuota es menor', () {
      final corto = PlanCalculo.calcular(monto: 3000, meses: 3)!;
      final medio = PlanCalculo.calcular(monto: 3000, meses: 6)!;
      final largo = PlanCalculo.calcular(monto: 3000, meses: 12)!;
      expect(corto.cuota, greaterThan(medio.cuota));
      expect(medio.cuota, greaterThan(largo.cuota));
    });

    test('conserva precision en un caso conocido', () {
      // 1000 a 6 meses al 12% anual: i = 0.01, cuota ≈ 172.55
      final plan = PlanCalculo.calcular(monto: 1000, meses: 6, tasaAnual: 12)!;
      expect(plan.cuota, closeTo(172.55, 0.01));
      expect(plan.totalPagar, closeTo(1035.30, 0.02));
    });

    test('la cuota se redondea a dos decimales', () {
      final plan = PlanCalculo.calcular(monto: 999.99, meses: 7, tasaAnual: 11.5)!;
      final decimalesCuota = plan.cuota.toString().split('.');
      final decimalesTotal = plan.totalPagar.toString().split('.');
      expect(decimalesCuota.length == 1 || decimalesCuota[1].length <= 2, isTrue);
      expect(decimalesTotal.length == 1 || decimalesTotal[1].length <= 2, isTrue);
    });

    test('usar la tasa sugerida segun el plazo', () {
      expect(PlanCalculo.tasaParaPlazo(3), 6.0);
      expect(PlanCalculo.tasaParaPlazo(6), 9.0);
      expect(PlanCalculo.tasaParaPlazo(12), 12.0);
      expect(PlanCalculo.tasaParaPlazo(24), PlanCalculo.tasaAnualPorDefecto);
    });

    test('comparar devuelve los tres plazos por defecto', () {
      final planes = PlanCalculo.comparar(monto: 5000);
      expect(planes.map((p) => p.meses).toList(), [3, 6, 12]);
    });

    test('comparar omite plazos invalidos', () {
      final planes = PlanCalculo.comparar(monto: 5000, plazos: [0, 6, -3, 12]);
      expect(planes.map((p) => p.meses).toList(), [6, 12]);
    });

    test('comparar devuelve vacio si el monto no es valido', () {
      expect(PlanCalculo.comparar(monto: 0), isEmpty);
    });
  });
}
