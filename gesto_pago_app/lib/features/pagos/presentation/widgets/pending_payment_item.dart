import 'package:flutter/material.dart';

import '../../../../core/theme/gp_theme.dart';
import '../../../../core/widgets/brand_mark.dart';
import '../../../../core/widgets/money_text.dart';
import '../../../../core/widgets/pressable.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/estado_transaccion.dart';
import '../../domain/pago_pendiente.dart';
import 'estado_transaccion_badge.dart';

/// Fila de una transaccion o pago pendiente de resolucion.
///
/// Muestra los datos de la transaccion real del usuario, el badge con su estado
/// actual y la accion que corresponde (Confirmar, Reintentar o Pagar).
class PendingPaymentItem extends StatelessWidget {
  const PendingPaymentItem({
    super.key,
    required this.pendiente,
    this.logoAsset,
    required this.onAccion,
  });

  final PagoPendiente pendiente;
  final String? logoAsset;
  final VoidCallback onAccion;

  String _etiquetaEstado(AppLocalizations l) => switch (pendiente.estado) {
        EstadoTransaccion.aprobada => l.historialStateApproved,
        EstadoTransaccion.fallida => l.historialStateFailed,
        EstadoTransaccion.enProceso => l.historialStateProcessing,
        EstadoTransaccion.pendiente => l.historialStatePending,
      };

  String _etiquetaAccion(AppLocalizations l) {
    if (pendiente.puedeConfirmar) {
      return l.commonConfirm;
    }
    if (pendiente.puedeReintentar) {
      return l.commonRetry;
    }
    return l.cardPayAction;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l = AppLocalizations.of(context);

    final accionTexto = _etiquetaAccion(l);
    final estadoTexto = _etiquetaEstado(l);

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(GpRadii.tarjeta),
        border: Border.all(color: scheme.outline),
      ),
      padding: const EdgeInsets.all(GpSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BrandMark(asset: logoAsset, tamano: 44),
          const SizedBox(width: GpSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Jerarquia 1: la empresa.
                          Text(
                            pendiente.servicio,
                            style: theme.textTheme.titleMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          // Jerarquia 2: el concepto / producto.
                          Text(
                            pendiente.producto,
                            style: theme.textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: GpSpacing.sm),
                    _BotonAccion(etiqueta: accionTexto, onTap: onAccion),
                  ],
                ),
                const SizedBox(height: GpSpacing.sm),
                // Jerarquia 3: monto + insignia de estado real.
                Wrap(
                  spacing: GpSpacing.sm,
                  runSpacing: GpSpacing.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    MoneyText(
                      monto: pendiente.monto,
                      style: theme.textTheme.titleMedium,
                      negritas: true,
                    ),
                    EstadoTransaccionBadge(
                      estado: pendiente.estado,
                      label: estadoTexto,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Boton de accion de la fila.
class _BotonAccion extends StatelessWidget {
  const _BotonAccion({required this.etiqueta, required this.onTap});

  final String etiqueta;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Pressable(
      onTap: onTap,
      semanticsLabel: etiqueta,
      escalaPulsado: 0.94,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: scheme.primary,
          borderRadius: BorderRadius.circular(GpRadii.pastilla),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bolt_rounded, size: 16, color: scheme.onPrimary),
            const SizedBox(width: 6),
            Text(
              etiqueta,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: scheme.onPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
