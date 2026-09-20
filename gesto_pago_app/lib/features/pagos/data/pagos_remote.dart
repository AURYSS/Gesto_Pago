import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/app_exception.dart';
import '../domain/transaccion.dart';

class PagosRemote {
  PagosRemote(this._dio);

  final Dio _dio;

  Future<VerificacionReferencia> verificarReferencia({
    required int idServicio,
    required int idProducto,
    required String referencia,
  }) async {
    try {
      final response = await _dio.post(
        '/pagos/verificar-referencia',
        data: {
          'idServicio': idServicio,
          'idProducto': idProducto,
          'referencia': referencia,
        },
      );
      return VerificacionReferencia.fromJson(_map(response.data, 'Verificación'));
    } catch (e) {
      throw ApiClient.unwrap(e);
    }
  }

  Future<Transaccion> crearTransaccion(Map<String, dynamic> request) async {
    try {
      final response = await _dio.post('/pagos/transacciones', data: request);
      return _parseTransaccion(_map(response.data, 'Transacción'));
    } catch (e) {
      throw ApiClient.unwrap(e);
    }
  }

  Future<Transaccion> confirmarTransaccion(int id) async {
    try {
      final response =
          await _dio.post('/pagos/transacciones/$id/confirmar');
      return _parseTransaccion(_map(response.data, 'Transacción'));
    } catch (e) {
      throw ApiClient.unwrap(e);
    }
  }

  Future<List<Transaccion>> historial() async {
    try {
      final response = await _dio.get('/pagos/transacciones');
      final data = response.data;
      if (data is! List) {
        return const [];
      }
      return data.map((e) => Transaccion.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      throw ApiClient.unwrap(e);
    }
  }

  Map<String, dynamic> _map(Object? data, String origen) {
    if (data is Map<String, dynamic>) {
      return data;
    }
    throw SerializationException('Respuesta de $origen inválida.');
  }

  Transaccion _parseTransaccion(Map<String, dynamic> data) {
    return Transaccion.fromJson(data);
  }
}