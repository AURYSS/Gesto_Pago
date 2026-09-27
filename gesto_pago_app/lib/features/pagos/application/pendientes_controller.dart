import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/app_exception.dart';
import '../../../core/providers/app_providers.dart';
import '../domain/pago_pendiente.dart';

class PendientesController extends AsyncNotifier<List<PagoPendiente>> {
  @override
  Future<List<PagoPendiente>> build() {
    return ref.watch(pagosRepositoryProvider).pendientes();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(pagosRepositoryProvider).pendientes());
  }

  String userMessage(AppException error) => 'No se pudieron cargar los pagos pendientes.';
}

final pendientesControllerProvider =
    AsyncNotifierProvider<PendientesController, List<PagoPendiente>>(PendientesController.new);
