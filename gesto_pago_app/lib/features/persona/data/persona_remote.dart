import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/app_exception.dart';
import '../domain/persona.dart';

class PersonaRemote {
  PersonaRemote(this._dio);

  final Dio _dio;

  Future<Persona> crearPersona(Persona persona) async {
    try {
      final response = await _dio.post('/personas', data: persona.toJson());
      return _parse(response.data);
    } catch (e) {
      throw ApiClient.unwrap(e);
    }
  }

  Future<Persona> actualizarPersona(Persona persona) async {
    try {
      final response =
          await _dio.put('/personasActualiza', data: persona.toJson());
      return _parse(response.data);
    } catch (e) {
      throw ApiClient.unwrap(e);
    }
  }

  Persona _parse(Object? data) {
    if (data is! Map<String, dynamic>) {
      throw const SerializationException('Respuesta de persona inválida.');
    }
    return Persona.fromJson(data);
  }
}