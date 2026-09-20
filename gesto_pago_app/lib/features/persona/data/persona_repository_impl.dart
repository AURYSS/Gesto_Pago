import '../domain/persona.dart';
import 'persona_remote.dart';

class PersonaRepositoryImpl implements PersonaRepository {
  PersonaRepositoryImpl(this._remote);

  final PersonaRemote _remote;

  @override
  Future<Persona> actualizarPersona(Persona persona) => _remote.actualizarPersona(persona);

  @override
  Future<Persona> crearPersona(Persona persona) => _remote.crearPersona(persona);
}