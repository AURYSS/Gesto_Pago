import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/gp_theme.dart';
import '../../../core/widgets/app_empty_view.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/app_loading_view.dart';
import '../../../l10n/app_localizations.dart';
import '../application/catalogo_controller.dart';
import '../application/marcas_controller.dart';
import '../domain/catalogo_agrupacion.dart';
import 'widgets/category_chip.dart';
import 'widgets/gp_search_bar.dart';
import 'widgets/servicio_card.dart';

/// Listado completo del catalogo, fuera de la portada.
class TodosServiciosScreen extends ConsumerStatefulWidget {
  const TodosServiciosScreen({super.key, this.categoriaInicial});

  final String? categoriaInicial;

  @override
  ConsumerState<TodosServiciosScreen> createState() => _TodosServiciosScreenState();
}

class _TodosServiciosScreenState extends ConsumerState<TodosServiciosScreen> {
  final _searchController = TextEditingController();
  String _busqueda = '';
  late String? _categoria = widget.categoriaInicial;

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
      appBar: AppBar(title: Text(l.homeTodosServicios)),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(GpSpacing.page, 4, GpSpacing.page, 12),
              child: GpSearchBar(
                controller: _searchController,
                hintText: l.catalogSearchHint,
                onChanged: (valor) => setState(() => _busqueda = valor),
              ),
            ),
            catalogoAsync.when(
              data: (productos) => marcasAsync.when(
                data: (marcas) {
                  final resultados = filtrarCatalogo(
                    productos,
                    marcas,
                    busqueda: _busqueda,
                    categoriaSlug: _categoria,
                  );
                  return Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: GpSpacing.lg),
                          child: CategoryChipRow(
                            children: [
                              CategoryChip(
                                categoriaSlug: null,
                                seleccionada: _categoria == null,
                                onTap: () => setState(() => _categoria = null),
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
                                  seleccionada: _categoria == entry.key,
                                  onTap: () => setState(
                                    () => _categoria = _categoria == entry.key ? null : entry.key,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: resultados.isEmpty
                              ? AppEmptyView(message: l.catalogEmpty)
                              : RefreshIndicator(
                                  onRefresh: () async {
                                    await Future.wait([
                                      ref.read(catalogoControllerProvider.notifier).refresh(),
                                      ref.read(marcasControllerProvider.notifier).refresh(),
                                    ]);
                                  },
                                  child: ListView.separated(
                                    padding: const EdgeInsets.fromLTRB(
                                      GpSpacing.page,
                                      0,
                                      GpSpacing.page,
                                      GpSpacing.xxl,
                                    ),
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
                        ),
                      ],
                    ),
                  );
                },
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
