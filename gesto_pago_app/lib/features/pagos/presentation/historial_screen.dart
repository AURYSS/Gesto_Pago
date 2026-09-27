import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format/gp_fecha.dart';
import '../../../core/format/gp_money.dart';
import '../../../core/text/texto_normalizado.dart';
import '../../../core/theme/gp_theme.dart';
import '../../../core/widgets/app_empty_view.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/brand_mark.dart';
import '../../../core/widgets/money_text.dart';
import '../../../core/widgets/pressable.dart';
import '../../../l10n/app_localizations.dart';
import '../../catalogo/application/marcas_controller.dart';
import '../../catalogo/domain/catalogo_marca.dart';
import '../../catalogo/presentation/widgets/gp_search_bar.dart';
import '../application/pago_controller.dart';
import '../domain/estado_transaccion.dart';
import '../domain/transaccion.dart';
import 'widgets/estado_transaccion_badge.dart';

class HistorialScreen extends ConsumerStatefulWidget {
  const HistorialScreen({super.key});

  @override
  ConsumerState<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends ConsumerState<HistorialScreen> {
  final _searchController = TextEditingController();
  String _busqueda = '';
  EstadoTransaccion? _filtroEstado;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final historial = ref.watch(historialControllerProvider);
    final marcasAsync = ref.watch(marcasControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.historialTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Actualizar',
            onPressed: () => ref.read(historialControllerProvider.notifier).refresh(),
          ),
        ],
      ),
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

          final marcas = marcasAsync.valueOrNull ??
              CatalogoMarcas(categorias: const [], marcas: const []);

          // Filtrar por busqueda y estado
          final query = normalizarTexto(_busqueda);
          final filtradas = transacciones.where((tx) {
            if (_filtroEstado != null && tx.estado != _filtroEstado) {
              return false;
            }
            if (query.isEmpty) return true;
            return normalizarTexto(tx.servicio).contains(query) ||
                normalizarTexto(tx.producto).contains(query) ||
                normalizarTexto(tx.referencia).contains(query) ||
                normalizarTexto(tx.numeroAutorizacion).contains(query);
          }).toList();

          // Metricas resumen
          final aprobadas = transacciones.where((t) => t.estado == EstadoTransaccion.aprobada).toList();
          final totalMontoAprobado = aprobadas.fold<double>(
            0.0,
            (acc, t) => acc + (double.tryParse(t.monto) ?? 0.0),
          );

          return RefreshIndicator(
            onRefresh: () => ref.read(historialControllerProvider.notifier).refresh(),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // Tarjeta de resumen
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(GpSpacing.page, 8, GpSpacing.page, 12),
                    child: _ResumenHistorialCard(
                      totalTransacciones: transacciones.length,
                      totalAprobadas: aprobadas.length,
                      montoTotal: totalMontoAprobado,
                    ),
                  ),
                ),

                // Buscador
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(GpSpacing.page, 0, GpSpacing.page, 10),
                    child: GpSearchBar(
                      controller: _searchController,
                      hintText: 'Buscar por servicio, ref o monto...',
                      onChanged: (v) => setState(() => _busqueda = v.trim()),
                    ),
                  ),
                ),

                // Chips de filtro por estado
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: GpSpacing.page),
                      child: Row(
                        children: [
                          _FiltroChip(
                            label: 'Todos (${transacciones.length})',
                            activo: _filtroEstado == null,
                            onTap: () => setState(() => _filtroEstado = null),
                          ),
                          const SizedBox(width: 8),
                          _FiltroChip(
                            label: 'Exitosos (${aprobadas.length})',
                            color: Theme.of(context).colorScheme.primary,
                            activo: _filtroEstado == EstadoTransaccion.aprobada,
                            onTap: () => setState(
                              () => _filtroEstado =
                                  _filtroEstado == EstadoTransaccion.aprobada
                                      ? null
                                      : EstadoTransaccion.aprobada,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _FiltroChip(
                            label: 'En proceso',
                            color: Colors.amber,
                            activo: _filtroEstado == EstadoTransaccion.enProceso,
                            onTap: () => setState(
                              () => _filtroEstado =
                                  _filtroEstado == EstadoTransaccion.enProceso
                                      ? null
                                      : EstadoTransaccion.enProceso,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _FiltroChip(
                            label: 'Fallidos',
                            color: Theme.of(context).colorScheme.error,
                            activo: _filtroEstado == EstadoTransaccion.fallida,
                            onTap: () => setState(
                              () => _filtroEstado =
                                  _filtroEstado == EstadoTransaccion.fallida
                                      ? null
                                      : EstadoTransaccion.fallida,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Lista de transacciones
                if (filtradas.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: AppEmptyView(
                      message: 'No se encontraron movimientos con ese filtro.',
                      icon: Icons.search_off_rounded,
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      GpSpacing.page,
                      0,
                      GpSpacing.page,
                      GpSpacing.xxl,
                    ),
                    sliver: SliverList.separated(
                      itemCount: filtradas.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final tx = filtradas[index];
                        final logo = marcas.logoDe(tx.servicio);

                        return _ItemHistorial(
                          transaccion: tx,
                          logoAsset: logo,
                          onTap: () => context.push('/comprobante/${tx.id}'),
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Tarjeta de métricas de gasto en el historial
class _ResumenHistorialCard extends StatelessWidget {
  const _ResumenHistorialCard({
    required this.totalTransacciones,
    required this.totalAprobadas,
    required this.montoTotal,
  });

  final int totalTransacciones;
  final int totalAprobadas;
  final double montoTotal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(GpRadii.tarjeta),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.24)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.account_balance_wallet_rounded, color: scheme.primary, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Pagado Exitoso',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  GpMoney.format(montoTotal.toStringAsFixed(2)),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: scheme.primary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: scheme.outline),
            ),
            child: Text(
              '$totalAprobadas / $totalTransacciones pagos',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Chip de filtrado de estados
class _FiltroChip extends StatelessWidget {
  const _FiltroChip({
    required this.label,
    required this.activo,
    required this.onTap,
    this.color,
  });

  final String label;
  final bool activo;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tinta = color ?? scheme.primary;

    return Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: activo ? tinta : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color: activo ? tinta : scheme.outline,
          ),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: activo ? (tinta.computeLuminance() > 0.4 ? Colors.black : Colors.white) : scheme.onSurface,
            fontWeight: activo ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

/// Ficha de cada transacción en el historial con logo, fecha y estado
class _ItemHistorial extends StatelessWidget {
  const _ItemHistorial({
    required this.transaccion,
    this.logoAsset,
    required this.onTap,
  });

  final Transaccion transaccion;
  final String? logoAsset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
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
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(GpRadii.tarjeta),
            border: Border.all(color: scheme.outline),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              BrandMark(
                asset: logoAsset,
                tamano: 46,
                radio: 14,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaccion.producto.isNotEmpty
                          ? transaccion.producto
                          : transaccion.servicio,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Text(
                          transaccion.servicio,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (transaccion.referencia.isNotEmpty) ...[
                          Text(
                            ' • Ref ${transaccion.referencia}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatFecha(transaccion.fecha),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  MoneyText(
                    monto: transaccion.monto,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: transaccion.estado == EstadoTransaccion.aprobada
                          ? scheme.primary
                          : scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  EstadoTransaccionBadge(
                    estado: transaccion.estado,
                    label: etiquetaEstado,
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