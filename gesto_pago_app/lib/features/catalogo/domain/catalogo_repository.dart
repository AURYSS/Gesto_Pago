import 'catalogo_marca.dart';
import 'catalogo_producto.dart';

abstract interface class CatalogoRepository {
  Future<List<CatalogoProducto>> obtenerProductos();
  Future<CatalogoMarcas> obtenerMarcas();
}