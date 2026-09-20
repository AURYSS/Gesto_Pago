import 'catalogo_producto.dart';

abstract interface class CatalogoRepository {
  Future<List<CatalogoProducto>> obtenerProductos();
}