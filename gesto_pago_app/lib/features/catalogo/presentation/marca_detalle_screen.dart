import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/text/texto_normalizado.dart';
import '../../../core/theme/gp_theme.dart';
import '../../../core/widgets/app_empty_view.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/app_loading_view.dart';
import '../../../core/widgets/brand_mark.dart';
import '../../../core/widgets/money_text.dart';
import '../../../core/widgets/pressable.dart';
import '../../../l10n/app_localizations.dart';
import '../application/catalogo_controller.dart';
import '../application/marcas_controller.dart';
import '../domain/catalogo_marca.dart';
import '../domain/catalogo_producto.dart';
import 'widgets/gp_search_bar.dart';

/// Pantalla que muestra todos los productos de una compania/marca especifica,
/// organizados y seccionados por tipo de producto/servicio.
class MarcaDetalleScreen extends ConsumerStatefulWidget {
  const MarcaDetalleScreen({
    super.key,
    required this.slug,
  });

  final String slug;

  @override
  ConsumerState<MarcaDetalleScreen> createState() => _MarcaDetalleScreenState();
}

class _MarcaDetalleScreenState extends ConsumerState<MarcaDetalleScreen> {
  final _searchController = TextEditingController();
  String _busqueda = '';
  String? _seccionSeleccionada;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final catalogoAsync = ref.watch(catalogoControllerProvider);
    final marcasAsync = ref.watch(marcasControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: marcasAsync.when(
          data: (marcas) {
            final marca = marcas.porSlug(widget.slug);
            return Text(marca?.nombre ?? widget.slug.toUpperCase());
          },
          loading: () => const Text('...'),
          error: (_, _) => Text(widget.slug.toUpperCase()),
        ),
      ),
      body: catalogoAsync.when(
        data: (productos) => marcasAsync.when(
          data: (marcas) {
            final marca = marcas.porSlug(widget.slug) ??
                CatalogoMarca(
                  slug: widget.slug,
                  nombre: widget.slug.toUpperCase(),
                  categoria: '',
                );

            // Filtrar todos los productos correspondientes a esta marca.
            final productosMarca = productos.where((p) {
              final s = marcas.slugDe(p.servicio);
              if (s != null && s == widget.slug) return true;
              final slugNorm = normalizarTexto(widget.slug).replaceAll('_', '');
              final servNorm = normalizarTexto(p.servicio).replaceAll(' ', '');
              return servNorm.contains(slugNorm);
            }).toList();

            if (productosMarca.isEmpty) {
              return AppEmptyView(
                message: l.catalogEmpty,
                icon: Icons.storefront_outlined,
              );
            }

            // Agrupar productos por sub-servicio / tipo de producto.
            final mapaSecciones = <String, List<CatalogoProducto>>{};
            for (final p in productosMarca) {
              final nombreSeccion = p.servicio.isNotEmpty ? p.servicio : marca.nombre;
              mapaSecciones.putIfAbsent(nombreSeccion, () => []).add(p);
            }

            // Filtrar segun busqueda y seccion activa.
            final textoBusqueda = normalizarTexto(_busqueda);
            final seccionesFiltradas = <String, List<CatalogoProducto>>{};

            for (final entry in mapaSecciones.entries) {
              if (_seccionSeleccionada != null && entry.key != _seccionSeleccionada) {
                continue;
              }
              final lista = entry.value.where((p) {
                if (textoBusqueda.isEmpty) return true;
                return normalizarTexto(p.producto).contains(textoBusqueda) ||
                    normalizarTexto(p.servicio).contains(textoBusqueda);
              }).toList();

              if (lista.isNotEmpty) {
                seccionesFiltradas[entry.key] = lista;
              }
            }

            final totalVisibles = seccionesFiltradas.values.fold<int>(
              0,
              (acc, l) => acc + l.length,
            );

            return SafeArea(
              child: CustomScrollView(
                slivers: [
                  // Cabecera visual de la compania
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        GpSpacing.page,
                        12,
                        GpSpacing.page,
                        16,
                      ),
                      child: _CabeceraMarca(
                        marca: marca,
                        totalProductos: productosMarca.length,
                      ),
                    ),
                  ),

                  // Buscador interno
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        GpSpacing.page,
                        0,
                        GpSpacing.page,
                        12,
                      ),
                      child: GpSearchBar(
                        controller: _searchController,
                        hintText: 'Buscar en ${marca.nombre}...',
                        onChanged: (v) => setState(() => _busqueda = v.trim()),
                      ),
                    ),
                  ),

                  // Chips de tipos / secciones de productos
                  if (mapaSecciones.length > 1)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: GpSpacing.page),
                          child: Row(
                            children: [
                              _TipoChip(
                                etiqueta: '${l.catalogAll} (${productosMarca.length})',
                                seleccionado: _seccionSeleccionada == null,
                                onTap: () => setState(() => _seccionSeleccionada = null),
                              ),
                              const SizedBox(width: 8),
                              for (final entry in mapaSecciones.entries) ...[
                                _TipoChip(
                                  etiqueta: '${entry.key} (${entry.value.length})',
                                  seleccionado: _seccionSeleccionada == entry.key,
                                  onTap: () => setState(
                                    () => _seccionSeleccionada =
                                        _seccionSeleccionada == entry.key ? null : entry.key,
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),

                  if (totalVisibles == 0)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: AppEmptyView(message: l.catalogEmpty),
                    )
                  else
                    // Listado seccionado por tipo de producto
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        GpSpacing.page,
                        0,
                        GpSpacing.page,
                        GpSpacing.xxl,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final keys = seccionesFiltradas.keys.toList();
                            final seccionNombre = keys[index];
                            final prods = seccionesFiltradas[seccionNombre]!;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 4,
                                        height: 16,
                                        decoration: BoxDecoration(
                                          color: marca.color ?? Theme.of(context).colorScheme.primary,
                                          borderRadius: BorderRadius.circular(2),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          seccionNombre,
                                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: 0.2,
                                              ),
                                        ),
                                      ),
                                      Text(
                                        '${prods.length}',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                                            ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  for (final prod in prods) ...[
                                    _ItemProducto(
                                      producto: prod,
                                      marca: marca,
                                      onTap: () => context.push(
                                        '/pago/${prod.idServicio}/${prod.idProducto}',
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                  ],
                                ],
                              ),
                            );
                          },
                          childCount: seccionesFiltradas.length,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
          loading: () => const AppLoadingView(),
          error: (_, _) => AppErrorView(
            message: l.catalogError,
            onRetry: () => ref.read(marcasControllerProvider.notifier).refresh(),
          ),
        ),
        loading: () => const AppLoadingView(),
        error: (_, _) => AppErrorView(
          message: l.catalogError,
          onRetry: () => ref.read(catalogoControllerProvider.notifier).refresh(),
        ),
      ),
    );
  }
}

/// Encabezado destacado con el logo y nombre de la compania
class _CabeceraMarca extends StatelessWidget {
  const _CabeceraMarca({
    required this.marca,
    required this.totalProductos,
  });

  final CatalogoMarca marca;
  final int totalProductos;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: marca.color?.withValues(alpha: 0.12) ?? scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(GpRadii.tarjeta),
        border: Border.all(
          color: marca.color?.withValues(alpha: 0.3) ?? scheme.outline,
        ),
      ),
      child: Row(
        children: [
          BrandMark(
            asset: marca.logoAsset,
            tamano: 56,
            radio: 16,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  marca.nombre,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$totalProductos opciones disponibles',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Chip de filtrado rapido por subcategoria o tipo
class _TipoChip extends StatelessWidget {
  const _TipoChip({
    required this.etiqueta,
    required this.seleccionado,
    required this.onTap,
  });

  final String etiqueta;
  final bool seleccionado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: seleccionado ? scheme.primary : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color: seleccionado ? scheme.primary : scheme.outline,
          ),
        ),
        child: Text(
          etiqueta,
          style: theme.textTheme.labelMedium?.copyWith(
            color: seleccionado ? scheme.onPrimary : scheme.onSurface,
            fontWeight: seleccionado ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

/// Tarjeta de seleccion de producto individual
class _ItemProducto extends StatelessWidget {
  const _ItemProducto({
    required this.producto,
    required this.marca,
    required this.onTap,
  });

  final CatalogoProducto producto;
  final CatalogoMarca marca;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l = AppLocalizations.of(context);

    final tienePrecio = double.tryParse(producto.precio) != null &&
        (double.tryParse(producto.precio)! > 0);

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
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      producto.producto,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            producto.esPagoServicio ? 'Pago de Servicio' : 'Recarga / Paquete',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        if (producto.tipoReferencia.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Text(
                            '• ${producto.tipoReferencia}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (tienePrecio) ...[
                    MoneyText(
                      monto: producto.precio,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      producto.esPrecioFinal ? l.catalogPrice : l.catalogCommission,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ] else ...[
                    Text(
                      'Pagar',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: scheme.onSurfaceVariant,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
