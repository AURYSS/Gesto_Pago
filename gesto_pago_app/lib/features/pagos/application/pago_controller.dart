import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/app_exception.dart';
import '../../../core/providers/app_providers.dart';
import '../../catalogo/domain/catalogo_producto.dart';
import '../domain/pagos_repository.dart';
import '../domain/transaccion.dart';

/// Flujo de un pago en pantalla.
class PagoFlowState {
  const PagoFlowState({
    this.verificando = false,
    this.procesando = false,
    this.confirmando = false,
    this.verificacion,
    this.transaccion,
    this.error,
  });

  final bool verificando;
  final bool procesando;
  final bool confirmando;
  final VerificacionReferencia? verificacion;
  final Transaccion? transaccion;
  final AppException? error;

  bool get estaOcupado => verificando || procesando || confirmando;

  PagoFlowState copyWith({
    bool? verificando,
    bool? procesando,
    bool? confirmando,
    VerificacionReferencia? verificacion,
    Transaccion? transaccion,
    AppException? error,
    bool clearVerificacion = false,
    bool clearTransaccion = false,
    bool clearError = false,
  }) {
    return PagoFlowState(
      verificando: verificando ?? this.verificando,
      procesando: procesando ?? this.procesando,
      confirmando: confirmando ?? this.confirmando,
      verificacion: clearVerificacion ? null : verificacion ?? this.verificacion,
      transaccion: clearTransaccion ? null : transaccion ?? this.transaccion,
      error: clearError ? null : error ?? this.error,
    );
  }
}

/// Orquesta el pago de un servicio.
class PagoController extends Notifier<PagoFlowState> {
  @override
  PagoFlowState build() => const PagoFlowState();

  PagosRepository get _repository => ref.read(pagosRepositoryProvider);

  /// Verifica la referencia contra el proveedor (monto autoritativo).
  Future<void> verificarReferencia({
    required CatalogoProducto producto,
    required String referencia,
  }) async {
    if (state.verificando) {
      return;
    }
    state = state.copyWith(
      verificando: true,
      error: null,
      clearVerificacion: true,
      clearTransaccion: true,
    );
    try {
      final verificacion = await _repository.verificarReferencia(
        idServicio: producto.idServicio,
        idProducto: producto.idProducto,
        referencia: referencia,
      );
      state = state.copyWith(verificando: false, verificacion: verificacion);
    } on AppException catch (e) {
      state = state.copyWith(verificando: false, error: e);
    }
  }

  /// Inicia el pago. Rechaza reenvíos mientras se procesa (anti doble clic).
  Future<void> pagar({
    required CatalogoProducto producto,
    required String referencia,
    required String monto,
  }) async {
    if (!state.estaOcupado) {
      state = state.copyWith(procesando: true, error: null, clearTransaccion: true);
    }
    final idempotencyKey = _claveIdempotencia(
      producto.idServicio,
      producto.idProducto,
      referencia,
      monto,
    );
    try {
      final transaccion = await _repository.crearTransaccion(
        PagoRequest(
          idServicio: producto.idServicio,
          idProducto: producto.idProducto,
          referencia: referencia,
          monto: monto,
          idempotencyKey: idempotencyKey,
        ),
      );
      state = state.copyWith(procesando: false, transaccion: transaccion);
    } on AppException catch (e) {
      if (state.procesando) {
        state = state.copyWith(procesando: false);
      }
      state = state.copyWith(error: e);
    }
  }

  /// Consulta el resultado final con el proveedor (confirmTx).
  Future<void> confirmarTransaccion(int id) async {
    if (state.confirmando) {
      return;
    }
    state = state.copyWith(confirmando: true, error: null);
    try {
      final transaccion = await _repository.confirmarTransaccion(id);
      state = state.copyWith(confirmando: false, transaccion: transaccion);
    } on AppException catch (e) {
      state = state.copyWith(confirmando: false, error: e);
    }
  }

  void reset() => state = const PagoFlowState();

  /// Clave de idempotencia estable para la misma intención de pago:
  /// same servicio, producto, referencia y monto ⇒ misma clave.
  /// Si algo cambia, se genera una nueva.
  String? _ultimaClave;
  PagoRequest? _ultimoRequest;

  String _claveIdempotencia(int idServicio, int idProducto, String referencia, String monto) {
    final candidate = PagoRequest(
      idServicio: idServicio,
      idProducto: idProducto,
      referencia: referencia,
      monto: monto,
      idempotencyKey: '',
    );
    final mismoIntento = _ultimoRequest != null &&
        _ultimoRequest!.idServicio == idServicio &&
        _ultimoRequest!.idProducto == idProducto &&
        _ultimoRequest!.referencia == referencia &&
        _ultimoRequest!.monto == monto;
    if (!mismoIntento || _ultimaClave == null) {
      _ultimaClave = _generarClave();
    }
    _ultimoRequest = candidate;
    return _ultimaClave!;
  }

  String _generarClave() {
    final random = Random.secure();
    final buffer = StringBuffer();
    for (var i = 0; i < 15; i++) {
      buffer.write(random.nextInt(16).toRadixString(16));
    }
    return buffer.toString();
  }
}

final pagoControllerProvider =
    NotifierProvider<PagoController, PagoFlowState>(PagoController.new);

class HistorialController extends AsyncNotifier<List<Transaccion>> {
  @override
  Future<List<Transaccion>> build() {
    return ref.watch(pagosRepositoryProvider).historial();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(pagosRepositoryProvider).historial());
  }
}

final historialControllerProvider =
    AsyncNotifierProvider<HistorialController, List<Transaccion>>(HistorialController.new);