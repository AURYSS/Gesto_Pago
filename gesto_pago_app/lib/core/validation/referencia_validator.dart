/// Resultado de validar la referencia capturada por el usuario.
///
/// Se separa del widget para poder probarlo sin levantar la app y para
/// que `pago_screen` no tenga que conocer las reglas de formato.
class ResultadoValidacion {
  const ResultadoValidacion._({
    required this.valido,
    this.digitos = 0,
    this.mensaje,
  });

  /// La referencia cumple el formato esperado y esta lista para enviarse.
  const ResultadoValidacion.ok(int digitos)
      : this._(valido: true, digitos: digitos);

  /// La referencia no cumple el formato. `mensaje` es una clave estable
  /// que la capa de presentacion traduce al idioma del usuario.
  const ResultadoValidacion.error(String mensaje)
      : this._(valido: false, mensaje: mensaje);

  final bool valido;

  /// Cantidad de digitos utiles tras normalizar, util para decidir si
  /// falta informacion. Es 0 cuando la referencia es invalida.
  final int digitos;

  /// Clave de traducion del motivo del rechazo, o null si es valida.
  final String? mensaje;
}

/// Valida la referencia de pago segun la clase declarada por el proveedor.
///
/// El catalogo expone `tipoReferencia` con los siguientes valores y
/// `hasDigitoVerificador` para referencias con digito de control:
///
/// - `a`  10 digitos (movil de 10 posiciones).
/// - `b`  Reference de 12 a 20 digitos con al menos 2 letras.
/// - `c`  Solo letras, 4 a 24 caracteres (correos, cuentas nominales).
/// - `ab` prepayment: se espera movil y la cuenta del recibo.
/// - `bc`  pago de servicio: se espera el numero del recibo.
/// - `d`  Reference libre de 4 a 24 caracteres.
///
/// Cuando `hasDigitoVerificador` es true se valida ademas la longitud
/// exacta que declara el proveedor mediante [digitosEsperados].
abstract final class ReferenciaValidator {
  /// Longitud por defecto de una referencia con digito verificador.
  static const int digitosPorDefecto = 18;

  /// Claves de traducion expuestas para las pantallas.
  static const String errorVacio = 'valReferenciaVacia';
  static const String errorFormato = 'valReferenciaFormato';
  static const String errorMovil = 'valReferenciaMovil';
  static const String errorCuenta = 'valReferenciaCuenta';
  static const String errorLargo = 'valReferenciaLargo';
  static const String errorCorto = 'valReferenciaCorto';
  static const String errorDigito = 'valReferenciaDigito';

  /// Valida [referencia] usando la regla de [tipoReferencia].
  ///
  /// [digitosEsperados] solo se considera cuando [conDigitoVerificador] es
  /// true; si es null se usa [digitosPorDefecto].
  static ResultadoValidacion validar(
    String referencia, {
    String tipoReferencia = 'd',
    bool conDigitoVerificador = false,
    int? digitosEsperados,
  }) {
    final limpio = referencia.trim();
    if (limpio.isEmpty) {
      return const ResultadoValidacion.error(errorVacio);
    }

    // Solo se admiten digitos y letras; se descartan espacios y signos.
    final soloAlfanumerico = limpio.replaceAll(RegExp(r'[^0-9A-Za-z]'), '');
    if (soloAlfanumerico.isEmpty) {
      return const ResultadoValidacion.error(errorFormato);
    }

    final digitos = _contarDigitos(soloAlfanumerico);

    if (conDigitoVerificador) {
      final esperados = digitosEsperados ?? digitosPorDefecto;
      if (digitos != esperados) {
        return const ResultadoValidacion.error(errorDigito);
      }
      return ResultadoValidacion.ok(digitos);
    }

    switch (tipoReferencia.trim().toLowerCase()) {
      case 'a':
        if (digitos != 10) {
          return const ResultadoValidacion.error(errorMovil);
        }
      case 'b':
        if (digitos < 12 || digitos > 20) {
          return const ResultadoValidacion.error(errorLargo);
        }
        if (!_tieneAlMenosDosLetras(soloAlfanumerico)) {
          return const ResultadoValidacion.error(errorCuenta);
        }
      case 'c':
        if (!_esSoloLetras(soloAlfanumerico)) {
          return const ResultadoValidacion.error(errorCuenta);
        }
        if (soloAlfanumerico.length < 4 || soloAlfanumerico.length > 24) {
          return const ResultadoValidacion.error(errorLargo);
        }
      case 'ab':
        return _validarAbono(soloAlfanumerico);
      case 'bc':
        if (digitos < 6) {
          return const ResultadoValidacion.error(errorCorto);
        }
      case 'd':
      default:
        if (soloAlfanumerico.length < 4 || soloAlfanumerico.length > 24) {
          return const ResultadoValidacion.error(errorLargo);
        }
    }

    return ResultadoValidacion.ok(digitos);
  }

  /// `ab` prepayment: numero de movil (10 digitos) o cuenta de referencia
  /// con 12 a 20 digitos. Se acepta cualquiera de las dos formas.
  static ResultadoValidacion _validarAbono(String valor) {
    final digitos = _contarDigitos(valor);
    if (digitos == 10) {
      return ResultadoValidacion.ok(digitos);
    }
    if (digitos >= 12 && digitos <= 20) {
      return ResultadoValidacion.ok(digitos);
    }
    return const ResultadoValidacion.error(errorCuenta);
  }

  static bool _esSoloLetras(String valor) => RegExp(r'^[A-Za-z]+$').hasMatch(valor);

  static bool _tieneAlMenosDosLetras(String valor) {
    var letras = 0;
    for (final ch in valor.split('')) {
      if (RegExp(r'[A-Za-z]').hasMatch(ch)) {
        letras++;
        if (letras >= 2) {
          return true;
        }
      }
    }
    return false;
  }

  static int _contarDigitos(String valor) {
    var total = 0;
    for (final ch in valor.split('')) {
      if (ch.codeUnitAt(0) >= 48 && ch.codeUnitAt(0) <= 57) {
        total++;
      }
    }
    return total;
  }
}
