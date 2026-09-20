import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format/gp_fecha.dart';
import '../../../core/theme/gp_theme.dart';
import '../../../core/widgets/app_empty_view.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/money_text.dart';
import '../../../l10n/app_localizations.dart';
import '../application/pago_controller.dart';
import '../domain/estado_transaccion.dart';
import '../domain/transaccion.dart';
import 'widgets/estado_transaccion_badge.dart';

class HistorialScreen extends ConsumerWidget {
  const HistorialScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final historial = ref.watch(historialControllerProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l.historialTitle)),
      body: historial.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => AppErrorView(
          message: l.historialError,
          onRetry: () => ref.read(historialControllerProvider.notifier).refresh(),
        ),
        data: (transacciones) {
          if (transacciones.isEmpty) {
            return AppEmptyView(
              message: l.historialEmpty,
              icon: Icons.receipt_long_outlined,
            );
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(historialControllerProvider.notifier).refresh(),
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(GpSpacing.page, 8, GpSpacing.page, 24),
              itemCount: transacciones.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final tx = transacciones[index];
                return _ItemHistorial(
                  transaccion: tx,
                  onTap: () => context.push('/comprobante/${tx.id}'),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _ItemHistorial extends ConsumerWidget {
  const _ItemHistorial({required this.transaccion, required this.onTap});

  final Transaccion transaccion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final etiquetaEstado = switch (transaccion.estado) {
      EstadoTransaccion.aprobada => l.historialStateApproved,
      EstadoTransaccion.fallida => l.historialStateFailed,
      EstadoTransaccion.enProceso => l.historialStateProcessing,
      EstadoTransaccion.pendiente => l.historialStatePending,
    };

    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(GpRadii.tarjeta),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(GpRadii.tarjeta),
        child: Ink(
          padding: const EdgeInsets.all(GpSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(GpRadii.tarjeta),
            border: Border.all(color: scheme.outline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      transaccion.producto,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  EstadoTransaccionBadge(
                    estado: transaccion.estado,
                    label: etiquetaEstado,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                transaccion.servicio,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ref ${transaccion.referencia}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        formatFecha(transaccion.fecha),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  MoneyText(
                    monto: transaccion.monto,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}