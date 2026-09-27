import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/theme/gp_theme.dart';
import '../../../core/widgets/app_empty_view.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/app_loading_view.dart';
import '../../../core/widgets/brand_mark.dart';
import '../../../core/widgets/pressable.dart';
import '../../../core/widgets/theme_toggle.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/application/session_controller.dart';
import '../../pagos/application/pago_controller.dart';
import '../../pagos/application/pendientes_controller.dart';
import '../../pagos/domain/pago_pendiente.dart';
import '../../pagos/presentation/widgets/pending_payment_item.dart';
import '../application/catalogo_controller.dart';
import '../application/marcas_controller.dart';
import '../domain/catalogo_agrupacion.dart';
import '../domain/catalogo_marca.dart';
import '../domain/catalogo_producto.dart';
import '../presentation/widgets/category_chip.dart';
import '../presentation/widgets/gp_search_bar.dart';
import '../presentation/widgets/service_card.dart';
import '../presentation/widgets/servicio_card.dart';

/// Inicio: saludo, busqueda, acciones rapidas, categorias, accesos rapidos
/// (usados recientes), transacciones pendientes y servicios populares en scroll horizontal.
class InicioScreen extends ConsumerStatefulWidget {
  const InicioScreen({super.key});

  @override
  ConsumerState<InicioScreen> createState() => _InicioScreenState();
}

class _InicioScreenState extends ConsumerState<InicioScreen> {
  final _searchController = TextEditingController();
  String _busqueda = '';
  String? _categoria;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _iniciales(String nombre) {
    final partes =
        nombre.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (partes.isEmpty) {
      return 'GP';
    }
    if (partes.length == 1) {
      return partes.first.characters.first.toUpperCase();
    }
    return '${partes.first.characters.first}${partes.last.characters.first}'.toUpperCase();
  }

  void _limpiarBusqueda() {
    _searchController.clear();
    setState(() => _busqueda = '');
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final sesion = ref.watch(sessionControllerProvider);
    final catalogo = ref.watch(catalogoControllerProvider);
    final marcasAsync = ref.watch(marcasControllerProvider);

    final nombreSesion = sesion.session?.nombre;
    final nombre = (nombreSesion != null && nombreSesion.trim().isNotEmpty)
        ? nombreSesion
        : null;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(GpSpacing.page, 16, GpSpacing.page, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (nombre != null) ...[
                          Text(
                            l.homeGreeting(nombre),
                            style: Theme.of(context).textTheme.headlineMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            l.homeWelcome,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ] else
                          Text(
                            l.homeWelcome,
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const ThemeToggle(),
                  if (nombre != null) ...[
                    const SizedBox(width: 8),
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.16),
                      child: Text(
                        _iniciales(nombre),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(GpSpacing.page, 4, GpSpacing.page, 12),
              child: GpSearchBar(
                controller: _searchController,
                hintText: l.catalogSearchHint,
                onChanged: (valor) => setState(() => _busqueda = valor.trim().toLowerCase()),
              ),
            ),
            catalogo.when(
              data: (productos) => marcasAsync.when(
                data: (marcas) => _ContenidoInicio(
                  productos: productos,
                  marcas: marcas,
                  busqueda: _busqueda,
                  categoria: _categoria,
                  onCategoria: (c) => setState(() => _categoria = c),
                  onLimpiarBusqueda: _limpiarBusqueda,
                ),
                loading: () => const Expanded(child: AppLoadingView()),
                error: (error, stack) => Expanded(
                  child: AppErrorView(
                    message: l.catalogError,
                    onRetry: () {
                      ref.read(catalogoControllerProvider.notifier).refresh();
                      ref.read(marcasControllerProvider.notifier).refresh();
                    },
                  ),
                ),
              ),
              loading: () => const Expanded(child: AppLoadingView()),
              error: (error, stack) => Expanded(
                child: AppErrorView(
                  message: l.catalogError,
                  onRetry: () {
                    ref.read(catalogoControllerProvider.notifier).refresh();
                    ref.read(marcasControllerProvider.notifier).refresh();
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContenidoInicio extends ConsumerWidget {
  const _ContenidoInicio({
    required this.productos,
    required this.marcas,
    required this.busqueda,
    required this.categoria,
    required this.onCategoria,
    required this.onLimpiarBusqueda,
  });

  final List<CatalogoProducto> productos;
  final CatalogoMarcas marcas;
  final String busqueda;
  final String? categoria;
  final ValueChanged<String?> onCategoria;
  final VoidCallback onLimpiarBusqueda;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final resultados = filtrarCatalogo(
      productos,
      marcas,
      busqueda: busqueda,
      categoriaSlug: categoria,
    );
    final buscando = busqueda.isNotEmpty;

    return Expanded(
      child: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            ref.read(catalogoControllerProvider.notifier).refresh(),
            ref.read(marcasControllerProvider.notifier).refresh(),
            ref.read(pendientesControllerProvider.notifier).refresh(),
            ref.read(historialControllerProvider.notifier).refresh(),
          ]);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            if (buscando)
              _ResultadosSliver(
                resultados: resultados,
                onLimpiar: onLimpiarBusqueda,
              )
            else ...[
              // Acciones rapidas principales (Recargas, Pagar Servicios, Historial, Ver Todos)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    GpSpacing.page,
                    0,
                    GpSpacing.page,
                    GpSpacing.lg,
                  ),
                  child: _SeccionAccionesRapidas(
                    onSeleccionarCategoria: onCategoria,
                  ),
                ),
              ),

              // Chips de categoria
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: GpSpacing.lg),
                  child: CategoryChipRow(
                    children: [
                      CategoryChip(
                        categoriaSlug: null,
                        seleccionada: categoria == null,
                        onTap: () => onCategoria(null),
                        etiqueta: l.catalogAll,
                      ),
                      for (final entry in conteoPorCategoria(productos, marcas).entries)
                        CategoryChip(
                          categoriaSlug: entry.key,
                          categoriaNombre: marcas.categorias
                              .where((c) => c.slug == entry.key)
                              .firstOrNull
                              ?.nombre,
                          cantidad: entry.value,
                          seleccionada: categoria == entry.key,
                          onTap: () => onCategoria(categoria == entry.key ? null : entry.key),
                        ),
                    ],
                  ),
                ),
              ),

              // Servicios usados recientes (accesos rapidos)
              SliverToBoxAdapter(child: _SeccionRecientes(marcas: marcas)),

              // Pagos pendientes
              SliverToBoxAdapter(child: _SeccionPendientes(marcas: marcas)),

              // Servicios populares en scroll horizontal izquierda/derecha
              SliverToBoxAdapter(
                child: _SeccionPopulares(
                  categoria: categoria,
                  marcas: marcas,
                ),
              ),
            ],
            if (resultados.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: AppEmptyView(message: l.catalogEmpty),
              )
            else if (buscando)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  GpSpacing.page,
                  0,
                  GpSpacing.page,
                  GpSpacing.xxl,
                ),
                sliver: SliverList.separated(
                  itemCount: resultados.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final producto = resultados[index];
                    return ServicioCard(
                      producto: producto,
                      logoAsset: marcas.logoDe(producto.servicio),
                      onTap: () => context.push(
                        '/pago/${producto.idServicio}/${producto.idProducto}',
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Acciones rapidas en la parte superior (Recargas, Pagar Servicios, Historial, Ver Todos)
class _SeccionAccionesRapidas extends StatelessWidget {
  const _SeccionAccionesRapidas({
    required this.onSeleccionarCategoria,
  });

  final ValueChanged<String?> onSeleccionarCategoria;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final acciones = [
      (
        icono: Icons.phone_android_rounded,
        color: const Color(0xFF00A8E0),
        titulo: 'Recargas',
        onTap: () => onSeleccionarCategoria('tiempo_aire'),
      ),
      (
        icono: Icons.receipt_long_rounded,
        color: const Color(0xFFE87722),
        titulo: 'Servicios',
        onTap: () => onSeleccionarCategoria('servicios'),
      ),
      (
        icono: Icons.history_rounded,
        color: scheme.primary,
        titulo: 'Historial',
        onTap: () => context.push('/historial'),
      ),
      (
        icono: Icons.grid_view_rounded,
        color: const Color(0xFF9C27B0),
        titulo: 'Ver Todos',
        onTap: () => context.push('/servicios'),
      ),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(GpRadii.tarjeta),
        border: Border.all(color: scheme.outline),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          for (final a in acciones)
            Expanded(
              child: Pressable(
                onTap: a.onTap,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: a.color.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(a.icono, color: a.color, size: 24),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      a.titulo,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Resultados de la busqueda: solo la lista, con el conteo arriba.
class _ResultadosSliver extends StatelessWidget {
  const _ResultadosSliver({required this.resultados, required this.onLimpiar});

  final List<CatalogoProducto> resultados;
  final VoidCallback onLimpiar;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(GpSpacing.page, 0, GpSpacing.page, GpSpacing.md),
        child: Row(
          children: [
            Expanded(
              child: Text(
                l.homeResultados(resultados.length),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            TextButton(onPressed: onLimpiar, child: Text(l.commonClose)),
          ],
        ),
      ),
    );
  }
}

/// Seccion de accesos rapidos con los servicios usados recientemente por el usuario.
class _SeccionRecientes extends ConsumerWidget {
  const _SeccionRecientes({required this.marcas});

  final CatalogoMarcas marcas;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historialAsync = ref.watch(historialControllerProvider);

    return historialAsync.when(
      data: (transacciones) {
        if (transacciones.isEmpty) {
          return const SizedBox.shrink();
        }

        // Obtener servicios unicos usados recientemente (hasta 8)
        final vistos = <String>{};
        final listaRecientes = <({String slug, String nombre, String? logo, int idServicio, int idProducto})>[];

        for (final tx in transacciones) {
          final slug = marcas.slugDe(tx.servicio) ?? tx.servicio.toLowerCase().replaceAll(' ', '_');
          if (!vistos.contains(slug)) {
            vistos.add(slug);
            final marca = marcas.porSlug(slug);
            listaRecientes.add((
              slug: slug,
              nombre: marca?.nombre ?? tx.servicio,
              logo: marca?.logoAsset ?? marcas.logoDe(tx.servicio),
              idServicio: tx.idServicio,
              idProducto: tx.idProducto,
            ));
          }
          if (listaRecientes.length >= 8) break;
        }

        if (listaRecientes.isEmpty) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, GpSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: GpSpacing.page),
                child: GpSeccionHeader(
                  titulo: 'Usados recientes',
                  subtitulo: 'Accesos rápidos a tus servicios frecuentes',
                ),
              ),
              const SizedBox(height: GpSpacing.md),
              SizedBox(
                height: 94,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: GpSpacing.page),
                  itemCount: listaRecientes.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 14),
                  itemBuilder: (context, index) {
                    final item = listaRecientes[index];
                    final marcaObj = marcas.porSlug(item.slug);

                    return Pressable(
                      onTap: () {
                        if (marcaObj != null) {
                          context.push('/marca/${marcaObj.slug}');
                        } else {
                          context.push('/pago/${item.idServicio}/${item.idProducto}');
                        }
                      },
                      child: SizedBox(
                        width: 72,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            BrandMark(
                              asset: item.logo,
                              tamano: 54,
                              radio: 18,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              item.nombre,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

/// Seccion de transacciones pendientes del usuario.
class _SeccionPendientes extends ConsumerWidget {
  const _SeccionPendientes({required this.marcas});

  final CatalogoMarcas marcas;

  Future<void> _manejarAccion(BuildContext context, WidgetRef ref, PagoPendiente pendiente) async {
    if (pendiente.puedeConfirmar) {
      try {
        final res = await ref.read(pagosRepositoryProvider).confirmarTransaccion(pendiente.id);
        ref.read(pendientesControllerProvider.notifier).refresh();
        if (context.mounted) {
          context.push('/comprobante/${res.id}');
        }
      } catch (_) {
        if (context.mounted) {
          context.push('/pago/${pendiente.idServicio}/${pendiente.idProducto}');
        }
      }
    } else {
      context.push('/pago/${pendiente.idServicio}/${pendiente.idProducto}');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final pendientesAsync = ref.watch(pendientesControllerProvider);

    return pendientesAsync.when(
      data: (pendientes) {
        if (pendientes.isEmpty) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: const EdgeInsets.fromLTRB(GpSpacing.page, 0, GpSpacing.page, GpSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GpSeccionHeader(
                titulo: l.pendientesTitulo,
                subtitulo: l.pendientesSub,
              ),
              const SizedBox(height: GpSpacing.md),
              for (final pendiente in pendientes) ...[
                PendingPaymentItem(
                  pendiente: pendiente,
                  logoAsset: marcas.logoDe(pendiente.servicio),
                  onAccion: () => _manejarAccion(context, ref, pendiente),
                ),
                const SizedBox(height: GpSpacing.sm),
              ],
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

/// Scroll horizontal deslizable de companias/servicios mas usados y populares.
class _SeccionPopulares extends StatelessWidget {
  const _SeccionPopulares({
    required this.categoria,
    required this.marcas,
  });

  final String? categoria;
  final CatalogoMarcas marcas;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Consumer(
      builder: (context, ref, _) {
        final productos = ref.watch(catalogoControllerProvider).valueOrNull;
        if (productos == null) {
          return const SizedBox.shrink();
        }
        final listaMarcas = resumenMarcas(
          productos,
          marcas,
          categoriaSlug: categoria,
          limite: 15,
        );
        if (listaMarcas.isEmpty) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, GpSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: GpSpacing.page),
                child: GpSeccionHeader(
                  titulo: l.homePopulares,
                  subtitulo: 'Desliza para ver más opciones populares',
                  accion: TextButton(
                    onPressed: () => context.push(
                      Uri(
                        path: '/servicios',
                        queryParameters: categoria == null
                            ? null
                            : {'categoria': categoria},
                      ).toString(),
                    ),
                    child: Text(l.homeVerTodos),
                  ),
                ),
              ),
              const SizedBox(height: GpSpacing.md),
              SizedBox(
                height: 154,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: GpSpacing.page),
                  itemCount: listaMarcas.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final item = listaMarcas[index];
                    final marcaObj = item.marca ??
                        marcas.porSlug(item.slug) ??
                        CatalogoMarca(
                          slug: item.slug,
                          nombre: item.nombre,
                          categoria: '',
                        );
                    return SizedBox(
                      width: 132,
                      child: ServiceCard(
                        marca: marcaObj,
                        onTap: () => context.push('/marca/${marcaObj.slug}'),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
