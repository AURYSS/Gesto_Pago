import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/app_exception.dart';
import '../../../core/providers/app_providers.dart';
import '../domain/catalogo_producto.dart';

class CatalogoController extends AsyncNotifier<List<CatalogoProducto>> {
  @override
  Future<List<CatalogoProducto>> build() {
    return ref.watch(catalogoRepositoryProvider).obtenerProductos();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(catalogoRepositoryProvider).obtenerProductos());
  }

  String userMessage(AppException error) => 'No se pudo cargar el catálogo.';
}

final catalogoControllerProvider =
    AsyncNotifierProvider<CatalogoController, List<CatalogoProducto>>(CatalogoController.new);

final catalogoFiltradoProvider = Provider<List<CatalogoProducto>>((ref) {
  final catalogo = ref.watch(catalogoControllerProvider).value ?? const <CatalogoProducto>[];
  return catalogo
      .where((p) =>
          p.idCatTipoServicio == CatalogoCategorias.pagoServicios ||
          p.idCatTipoServicio == CatalogoCategorias.pagoImpuestos ||
          p.idCatTipoServicio == CatalogoCategorias.pagoDerechosAgua)
      .toList();
});