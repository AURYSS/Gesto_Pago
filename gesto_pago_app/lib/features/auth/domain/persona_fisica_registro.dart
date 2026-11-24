class PersonaFisicaRegistro {
  const PersonaFisicaRegistro({
    required this.nombre,
    this.segundoNombre,
    required this.apellidoPaterno,
    required this.apellidoMaterno,
    required this.fechaNacimiento,
    required this.curp,
    required this.rfc,
    required this.sexo,
    this.nacionalidad = 'Mexicana',
    required this.estadoCivil,
    required this.correo,
    required this.telefonoMovil,
    this.telefonoAlternativo,
    required this.calle,
    required this.numeroExterior,
    this.numeroInterior,
    required this.colonia,
    required this.municipio,
    required this.estado,
    required this.codigoPostal,
    this.pais = 'México',
    required this.ocupacion,
    required this.empresa,
    required this.ingresoMensual,
    required this.password,
  });

  final String nombre;
  final String? segundoNombre;
  final String apellidoPaterno;
  final String apellidoMaterno;
  final String fechaNacimiento;
  final String curp;
  final String rfc;
  final String sexo;
  final String nacionalidad;
  final String estadoCivil;
  final String correo;
  final String telefonoMovil;
  final String? telefonoAlternativo;
  final String calle;
  final String numeroExterior;
  final String? numeroInterior;
  final String colonia;
  final String municipio;
  final String estado;
  final String codigoPostal;
  final String pais;
  final String ocupacion;
  final String empresa;
  final double ingresoMensual;
  final String password;

  String get nombreCompleto {
    final partes = <String>[nombre.trim()];
    if (segundoNombre != null && segundoNombre!.trim().isNotEmpty) {
      partes.add(segundoNombre!.trim());
    }
    partes.add(apellidoPaterno.trim());
    if (apellidoMaterno.trim().isNotEmpty) {
      partes.add(apellidoMaterno.trim());
    }
    return partes.join(' ');
  }

  Map<String, dynamic> toMicroUsuariosPayload() {
    return {
      'cliente': {
        'nombre': nombre.trim(),
        'segundoNombre': (segundoNombre != null && segundoNombre!.trim().isNotEmpty)
            ? segundoNombre!.trim()
            : null,
        'apellidoPaterno': apellidoPaterno.trim(),
        'apellidoMaterno': apellidoMaterno.trim(),
        'fechaNacimiento': fechaNacimiento,
        'curp': curp.trim().toUpperCase(),
        'rfc': rfc.trim().toUpperCase(),
        'sexo': sexo,
        'nacionalidad': nacionalidad.trim(),
        'estadoCivil': estadoCivil,
        'correo': correo.trim().toLowerCase(),
        'telefonoMovil': telefonoMovil.trim(),
        'telefonoAlternativo': (telefonoAlternativo != null && telefonoAlternativo!.trim().isNotEmpty)
            ? telefonoAlternativo!.trim()
            : null,
        'ocupacion': ocupacion.trim(),
        'empresa': empresa.trim(),
        'ingresoMensual': ingresoMensual,
        'domicilio': {
          'calle': calle.trim(),
          'numeroExterior': numeroExterior.trim(),
          'numeroInterior': (numeroInterior != null && numeroInterior!.trim().isNotEmpty)
              ? numeroInterior!.trim()
              : null,
          'colonia': colonia.trim(),
          'codigoPostal': codigoPostal.trim(),
          'municipio': municipio.trim(),
          'estado': estado.trim(),
          'pais': pais.trim(),
        },
      },
      'password': password,
    };
  }

  Map<String, dynamic> toAuthRegisterPayload() {
    return {
      'nombre': nombreCompleto,
      'email': correo.trim().toLowerCase(),
      'password': password,
    };
  }
}
