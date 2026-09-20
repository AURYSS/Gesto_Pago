import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gesto_pago_app/core/network/api_client.dart';
import 'package:gesto_pago_app/core/network/app_exception.dart';

void main() {
  test('unwrap recupera la AppException que Dio envuelve desde un interceptor', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:9'))
      ..interceptors.add(
        InterceptorsWrapper(
          onError: (err, handler) => throw ForbiddenException('sin permiso', statusCode: 403),
        ),
      );

    Object? capturado;
    try {
      await dio.get('/x');
    } catch (e) {
      capturado = e;
    }

    expect(capturado, isA<DioException>(),
        reason: 'Dio 5 envuelve lo que lancen los interceptores en DioException');
    final error = capturado as DioException;
    expect(error.error, isA<AppException>());

    final result = ApiClient.unwrap(error);
    expect(result, isA<ForbiddenException>());
    expect(result.message, 'sin permiso');
  });

  test('unwrap mapea errores de red (connectionError) a NetworkException', () {
    final options = RequestOptions(path: '/x', baseUrl: 'http://localhost:9');
    final err = DioException.connectionError(
      requestOptions: options,
      reason: 'sin conexión',
    );

    expect(ApiClient.unwrap(err), isA<NetworkException>());
  });

  test('unwrap deja pasar AppException directas (p. ej. SerializationException)', () {
    const orig = SerializationException('respuesta rara');

    expect(ApiClient.unwrap(orig), same(orig));
  });

  test('unwrap de errores crudos produce ApiException genérica', () {
    expect(ApiClient.unwrap(StateError('boom')), isA<ApiException>());
  });
}