import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import 'app_exception.dart';
import 'token_refresher.dart';
import 'token_store.dart';

/// Cliente HTTP único de la aplicación.
///
/// Se encarga de: base URL y timeouts, renovación automática de sesión y
/// traducción de errores a [AppException] tipadas.
class ApiClient {
  ApiClient({
    required TokenStore tokenStore,
    required TokenRefresher Function() tokenRefresher,
    void Function()? onSessionExpired,
  }) {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: AppConfig.connectTimeout,
        receiveTimeout: AppConfig.receiveTimeout,
        sendTimeout: AppConfig.connectTimeout,
        headers: const {'Accept': 'application/json'},
        contentType: Headers.jsonContentType,
      ),
    );
    _dio.interceptors.addAll([
      if (kDebugMode)
        LogInterceptor(
          request: true,
          requestHeader: false,
          requestBody: true,
          responseBody: true,
          responseHeader: false,
          error: true,
          logPrint: (object) => debugPrint('DIO: $object'),
        ),
      _AuthInterceptor(
        dio: _dio,
        tokenStore: tokenStore,
        tokenRefresher: tokenRefresher,
        onRefreshFailed: () => onSessionExpired?.call(),
      ),
      _ErrorInterceptor(),
    ]);
  }

  late final Dio _dio;

  Dio get dio => _dio;

  /// Convierte cualquier error que salga de la capa HTTP a una [AppException].
  ///
  /// Dio 5.11 envuelve en un [DioException] (con el original en `error`) todo
  /// lo que lanzan los interceptores, así que una [AppException] lanzada en el
  /// interceptor nunca llega sola al caller: aquí se desempaqueta.
  static AppException unwrap(Object error) {
    if (error is AppException) {
      return error;
    }
    if (error is DioException) {
      final inner = error.error;
      if (inner is AppException) {
        return inner;
      }
      return _ErrorInterceptor.map(error);
    }
    return const ApiException('Error inesperado.');
  }
}

/// Renueva el access token con un único refresh concurrente.
class _AuthInterceptor extends QueuedInterceptor {
  _AuthInterceptor({
    required this.dio,
    required this.tokenStore,
    required this.tokenRefresher,
    required this.onRefreshFailed,
  });

  final Dio dio;
  final TokenStore tokenStore;
  final TokenRefresher Function() tokenRefresher;
  final void Function() onRefreshFailed;

  Future<String?>? _refreshInFlight;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    if (_isAuthEndpoint(options.path)) {
      return handler.next(options);
    }
    final access = await tokenStore.readAccessToken();
    if (access != null) {
      options.headers['Authorization'] = 'Bearer $access';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final options = err.requestOptions;
    final is401 = err.response?.statusCode == 401;
    final isAuthCall = _isAuthEndpoint(options.path);
    final alreadyRetried = options.extra['_authRetried'] == true;

    if (!is401 || isAuthCall || alreadyRetried) {
      return handler.next(err);
    }

    final access = await _refreshOnce();
    if (access == null) {
      await tokenStore.clear();
      onRefreshFailed();
      return handler.next(err);
    }

    final retryOptions = options.copyWith(
      headers: {
        ...options.headers,
        'Authorization': 'Bearer $access',
      },
      extra: {
        ...options.extra,
        '_authRetried': true,
      },
    );
    try {
      final response = await dio.fetch(retryOptions);
      return handler.resolve(response);
    } on DioException catch (retryError) {
      return handler.next(retryError);
    }
  }

  Future<String?> _refreshOnce() {
    final inflight = _refreshInFlight;
    if (inflight != null) {
      return inflight;
    }
    final future = _doRefresh();
    _refreshInFlight = future;
    return future.whenComplete(() => _refreshInFlight = null);
  }

  Future<String?> _doRefresh() async {
    final refreshToken = await tokenStore.readRefreshToken();
    if (refreshToken == null) {
      return null;
    }
    final result = await tokenRefresher().refreshSession(refreshToken);
    if (result == null) {
      return null;
    }
    final email = await tokenStore.readEmail();
    await tokenStore.save(
      accessToken: result.accessToken,
      refreshToken: result.refreshToken,
      nombre: result.nombre,
      email: email ?? '',
    );
    return result.accessToken;
  }

  bool _isAuthEndpoint(String path) {
    return path.startsWith('/auth/');
  }
}

/// Traduce errores de [DioException] a excepciones tipadas de la aplicación.
class _ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    throw map(err);
  }

  static AppException map(DioException err) {
    final status = err.response?.statusCode;
    final data = err.response?.data;

    Object? code;
    Object? message;
    if (data is Map) {
      code = data['code'];
      message = data['message'];
    }

    final detail = (message is String && message.isNotEmpty) ? message : '';

    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return const TimeoutException('Espera de respuesta agotada.');
      case DioExceptionType.connectionError:
      case DioExceptionType.unknown:
      case DioExceptionType.badCertificate:
      case DioExceptionType.cancel:
        return const NetworkException('Sin conexión con el servidor.');
      case DioExceptionType.badResponse:
        return _mapResponse(status, detail, code is String ? code : null);
    }
  }

  static AppException _mapResponse(int? status, String message, String? code) {
    switch (status) {
      case 400:
      case 422:
        return ApiException(
          message.isEmpty ? 'Solicitud inválida.' : message,
          code: code,
          statusCode: status,
        );
      case 401:
        return UnauthorizedException(
          message.isEmpty ? 'No autorizado.' : message,
          code: code,
          statusCode: status,
        );
      case 403:
        return ForbiddenException(
          message.isEmpty ? 'Sin permisos.' : message,
          code: code,
          statusCode: status,
        );
      case 404:
        return NotFoundException(message, code: code, statusCode: status);
      case 429:
        return RateLimitException(
          message.isEmpty ? 'Demasiadas peticiones.' : message,
          code: code,
          statusCode: status,
        );
      default:
        return ServerException(
          message.isEmpty ? 'Error del servidor.' : message,
          statusCode: status,
        );
    }
  }
}