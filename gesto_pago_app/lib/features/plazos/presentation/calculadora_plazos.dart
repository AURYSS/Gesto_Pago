import 'package:flutter/material.dart';

import '../../../core/format/gp_money.dart';
import '../../../core/theme/gp_motion.dart';
import '../../../core/theme/gp_theme.dart';
import '../../../core/widgets/pressable.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/plan_calculo.dart';

/// Comparativa de pago a plazos para un monto.
///
/// Muestra los planes disponibles (3, 6 y 12 meses) como tarjetas
/// seleccionables con la cuota mensual en grande y el desglose debajo.
/// Es una simulacion: el monto final lo determina el proveedor.
class CalculadoraPlazos extends StatefulWidget {
  const CalculadoraPlazos({
    super.key,
    required this.monto,
    this.plazos = PlanCalculo.plazosDisponibles,
    this.onSeleccion,
  });

  /// Monto a financiar.
  final double monto;

  /// Plazos a comparar. Por defecto 3, 6 y 12 meses.
  final List<int> plazos;

  /// Se invoca cuando el usuario elige un plazo.
  final void Function(PlanPago plan)? onSeleccion;

  @override
  State<CalculadoraPlazos> createState() => _CalculadoraPlazosState();
}

class _CalculadoraPlazosState extends State<CalculadoraPlazos> {
  int? _seleccionado;

  @override
  void didUpdateWidget(CalculadoraPlazos oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si el monto cambia, la seleccion previa deja de ser coherente.
    if (oldWidget.monto != widget.monto) {
      _seleccionado = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final planes = PlanCalculo.comparar(monto: widget.monto, plazos: widget.plazos);

    if (planes.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.schedule_rounded, size: 18, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(l.plazosTitle, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
        const SizedBox(height: GpSpacing.xs),
        Text(
          l.plazosSubtitle,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: GpSpacing.md),
        ...planes.asMap().entries.map(
              (entry) => _PlanTarjeta(
                plan: entry.value,
                seleccionado: entry.value.meses == _seleccionado,
                onTap: () => setState(() => _seleccionado = entry.value.meses),
                onConfirmar: widget.onSeleccion == null
                    ? null
                    : () => widget.onSeleccion!(entry.value),
              ),
            ),
        const SizedBox(height: GpSpacing.sm),
        // La simulacion no es un compromiso: hay que decirlo.
        Text(
          l.plazosDisclaimer,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _PlanTarjeta extends StatelessWidget {
  const _PlanTarjeta({
    required this.plan,
    required this.seleccionado,
    required this.onTap,
    this.onConfirmar,
  });

  final PlanPago plan;
  final bool seleccionado;
  final VoidCallback onTap;
  final VoidCallback? onConfirmar;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: GpSpacing.md),
      child: Pressable(
        onTap: onTap,
        semanticsLabel: l.plazosPlanLabel(plan.meses),
        child: AnimatedContainer(
          duration: GpMotion.media,
          curve: GpMotion.entrada,
          padding: const EdgeInsets.all(GpSpacing.lg),
          decoration: BoxDecoration(
            color: seleccionado ? scheme.primary.withValues(alpha: 0.10) : scheme.surface,
            borderRadius: BorderRadius.circular(GpRadii.tarjeta),
            border: Border.all(
              color: seleccionado ? scheme.primary : scheme.outline,
              width: seleccionado ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    l.plazosMonths(plan.meses),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(width: GpSpacing.sm),
                  if (plan.sinCosto)
                    _Etiqueta(
                      texto: l.plazosSinCosto,
                      color: scheme.primary,
                    )
                  else
                    _Etiqueta(
                      texto: l.plazosRate(plan.tasaAnual),
                      color: scheme.onSurfaceVariant,
                    ),
                  const Spacer(),
                  if (seleccionado)
                    Icon(Icons.check_circle_rounded, color: scheme.primary, size: 22),
                ],
              ),
              const SizedBox(height: GpSpacing.md),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    GpMoney.formatMonto(plan.cuota),
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    l.plazosPerMonth,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: GpSpacing.sm),
              _Fila(
                label: l.plazosTotal,
                valor: GpMoney.formatMonto(plan.totalPagar),
              ),
              if (!plan.sinCosto)
                _Fila(
                  label: l.plazosCost,
                  valor: GpMoney.formatMonto(plan.costoFinanciero),
                ),
              if (seleccionado && onConfirmar != null) ...[
                const SizedBox(height: GpSpacing.md),
                FilledButton(
                  onPressed: onConfirmar,
                  child: Text(l.plazosSelect(plan.meses)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Etiqueta extends StatelessWidget {
  const _Etiqueta({required this.texto, required this.color});

  final String texto;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(GpRadii.pastilla),
      ),
      child: Text(
        texto,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}

class _Fila extends StatelessWidget {
  const _Fila({required this.label, required this.valor});

  final String label;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          Text(
            valor,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
