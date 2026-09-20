import '../domain/catalogo_producto.dart';
import '../domain/catalogo_repository.dart';
import 'catalogo_remote.dart';

class CatalogoRepositoryImpl implements CatalogoRepository {
  CatalogoRepositoryImpl(this._remote);

  final CatalogoRemote _remote;

  @override
  Future<List<CatalogoProducto>> obtenerProductos() => _remote.obtenerProductos();
}