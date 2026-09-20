import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/app_exception.dart';
import '../domain/catalogo_producto.dart';

class CatalogoRemote {
  CatalogoRemote(this._dio);

  final Dio _dio;

  Future<List<CatalogoProducto>> obtenerProductos() async {
    try {
      final response = await _dio.get('/catalogo/productos');
      final data = response.data;
      if (data is! List) {
        throw const SerializationException('Catálogo vacío.');
      }
      return data
          .map((e) => CatalogoProducto.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ApiClient.unwrap(e);
    }
  }
}