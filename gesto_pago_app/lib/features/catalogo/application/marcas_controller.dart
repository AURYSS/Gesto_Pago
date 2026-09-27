import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/app_exception.dart';
import '../../../core/providers/app_providers.dart';
import '../domain/catalogo_marca.dart';

class MarcasController extends AsyncNotifier<CatalogoMarcas> {
  @override
  Future<CatalogoMarcas> build() {
    return ref.watch(catalogoRepositoryProvider).obtenerMarcas();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(catalogoRepositoryProvider).obtenerMarcas());
  }

  String userMessage(AppException error) => 'No se pudo cargar el catálogo de marcas.';
}

final marcasControllerProvider =
    AsyncNotifierProvider<MarcasController, CatalogoMarcas>(MarcasController.new);
