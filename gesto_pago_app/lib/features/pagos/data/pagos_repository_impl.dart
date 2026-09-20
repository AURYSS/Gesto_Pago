import '../domain/pagos_repository.dart';
import '../domain/transaccion.dart';
import 'pagos_remote.dart';

class PagosRepositoryImpl implements PagosRepository {
  PagosRepositoryImpl(this._remote);

  final PagosRemote _remote;

  @override
  Future<Transaccion> confirmarTransaccion(int id) => _remote.confirmarTransaccion(id);

  @override
  Future<Transaccion> crearTransaccion(PagoRequest request) =>
      _remote.crearTransaccion(request.toJson());

  @override
  Future<List<Transaccion>> historial() => _remote.historial();

  @override
  Future<VerificacionReferencia> verificarReferencia({
    required int idServicio,
    required int idProducto,
    required String referencia,
  }) =>
      _remote.verificarReferencia(
        idServicio: idServicio,
        idProducto: idProducto,
        referencia: referencia,
      );
}