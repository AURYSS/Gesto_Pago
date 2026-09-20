class Persona {
  const Persona({required this.nombre, required this.apellidoP, required this.apellidoMaterno});

  factory Persona.fromJson(Map<String, dynamic> json) {
    return Persona(
      nombre: json['nombre'] as String? ?? '',
      apellidoP: json['apellidoP'] as String? ?? '',
      apellidoMaterno: json['apellidoMaterno'] as String? ?? '',
    );
  }

  final String nombre;
  final String apellidoP;
  final String apellidoMaterno;

  Map<String, dynamic> toJson() => {
        'nombre': nombre,
        'apellidoP': apellidoP,
        'apellidoMaterno': apellidoMaterno,
      };
}

abstract interface class PersonaRepository {
  /// Registra los datos personales del usuario en el backend.
  Future<Persona> crearPersona(Persona persona);

  /// Actualiza los datos personales.
  Future<Persona> actualizarPersona(Persona persona);
}