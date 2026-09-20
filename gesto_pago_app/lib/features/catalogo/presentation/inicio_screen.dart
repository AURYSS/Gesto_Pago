import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/gp_colors.dart';
import '../../../core/theme/gp_theme.dart';
import '../../../core/widgets/app_empty_view.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/app_loading_view.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/application/session_controller.dart';
import '../application/catalogo_controller.dart';
import '../domain/catalogo_producto.dart';
import '../presentation/widgets/servicio_card.dart';

/// Inicio: saludo, búsqueda y catálogo de servicios.
class InicioScreen extends ConsumerStatefulWidget {
  const InicioScreen({super.key});

  @override
  ConsumerState<InicioScreen> createState() => _InicioScreenState();
}

class _InicioScreenState extends ConsumerState<InicioScreen> {
  final _searchController = TextEditingController();
  String _filtroServicio = '';

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

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final sesion = ref.watch(sessionControllerProvider);
    final catalogo = ref.watch(catalogoControllerProvider);

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
                  style: Theme.of(context).textTheme.bodyMedium,
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
                  if (nombre != null)
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: GpColors.verde.withValues(alpha: 0.16),
                      child: Text(
                        _iniciales(nombre),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(GpSpacing.page, 4, GpSpacing.page, 12),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: l.catalogSearchHint,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        ),
                ),
              ),
            ),
            catalogo.when(
              data: (productos) => _ContenidoCatalogo(
                productos: productos,
                busqueda: _searchController.text.trim().toLowerCase(),
                filtroServicio: _filtroServicio,
                onFiltroServicio: (servicio) => setState(() => _filtroServicio = servicio),
              ),
              loading: () => const Expanded(child: AppLoadingView()),
              error: (error, stack) => Expanded(
                child: AppErrorView(
                  message: l.catalogError,
                  onRetry: () => ref.read(catalogoControllerProvider.notifier).refresh(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContenidoCatalogo extends ConsumerWidget {
  const _ContenidoCatalogo({
    required this.productos,
    required this.busqueda,
    required this.filtroServicio,
    required this.onFiltroServicio,
  });

  final List<CatalogoProducto> productos;
  final String busqueda;
  final String filtroServicio;
  final ValueChanged<String> onFiltroServicio;

  List<CatalogoProducto> get _filtrados {
    final servicios = productos
        .where((p) => filtroServicio.isEmpty || p.servicio == filtroServicio)
        .where((p) =>
            busqueda.isEmpty ||
            p.producto.toLowerCase().contains(busqueda) ||
            p.servicio.toLowerCase().contains(busqueda))
        .toList();
    return servicios;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final serviciosDisponibles = productos.map((p) => p.servicio).toSet().toList();

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: GpSpacing.page),
              children: [
                _ChipFiltro(
                  etiqueta: l.catalogAll,
                  seleccionado: filtroServicio.isEmpty,
                  onTap: () => onFiltroServicio(''),
                ),
                for (final servicio in serviciosDisponibles)
                  _ChipFiltro(
                    etiqueta: servicio,
                    seleccionado: filtroServicio == servicio,
                    onTap: () => onFiltroServicio(servicio),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (_filtrados.isEmpty)
            Expanded(child: AppEmptyView(message: l.catalogEmpty))
          else
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => ref.read(catalogoControllerProvider.notifier).refresh(),
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    GpSpacing.page,
                    4,
                    GpSpacing.page,
                    24,
                  ),
                  itemCount: _filtrados.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final producto = _filtrados[index];
                    return ServicioCard(
                      producto: producto,
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
  }
}

class _ChipFiltro extends StatelessWidget {
  const _ChipFiltro({
    required this.etiqueta,
    required this.seleccionado,
    required this.onTap,
  });

  final String etiqueta;
  final bool seleccionado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(etiqueta),
        selected: seleccionado,
        onSelected: (_) => onTap(),
        showCheckmark: false,
        labelStyle: TextStyle(
          color: seleccionado ? scheme.onPrimary : scheme.onSurface,
          fontWeight: seleccionado ? FontWeight.w700 : FontWeight.w500,
        ),
        selectedColor: scheme.primary,
        backgroundColor: scheme.surface,
      ),
    );
  }
}