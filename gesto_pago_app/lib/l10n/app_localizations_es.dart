// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Gesto Pago';

  @override
  String get commonLoading => 'Cargando...';

  @override
  String get commonRetry => 'Reintentar';

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get commonConfirm => 'Confirmar';

  @override
  String get commonSave => 'Guardar';

  @override
  String get commonClose => 'Cerrar';

  @override
  String get commonBack => 'Volver';

  @override
  String get commonDone => 'Listo';

  @override
  String get errorGeneric => 'Ocurrió un error inesperado. Intenta de nuevo.';

  @override
  String get errorNetwork =>
      'No se pudo conectar con el servidor. Revisa tu conexión.';

  @override
  String get errorTimeout =>
      'El servidor tardó demasiado en responder. Intenta de nuevo.';

  @override
  String get errorUnauthorized => 'Tu sesión expiró. Vuelve a iniciar sesión.';

  @override
  String get errorForbidden => 'No tienes permiso para realizar esta acción.';

  @override
  String get errorNotFound => 'No se encontró la información solicitada.';

  @override
  String get errorRateLimit => 'Demasiados intentos. Intenta en un momento.';

  @override
  String get errorServer => 'Error del servidor. Intenta más tarde.';

  @override
  String get splashTagline => 'Paga tus servicios en un solo lugar';

  @override
  String get splashRestoring => 'Restaurando tu sesión...';

  @override
  String get loginTitle => 'Bienvenido de nuevo';

  @override
  String get loginSubtitle => 'Inicia sesión para pagar tus servicios';

  @override
  String get loginEmailLabel => 'Correo electrónico';

  @override
  String get loginPasswordLabel => 'Contraseña';

  @override
  String get loginEmailRequired => 'Ingresa tu correo';

  @override
  String get loginEmailInvalid => 'Correo inválido';

  @override
  String get loginPasswordRequired => 'Ingresa tu contraseña';

  @override
  String get loginButton => 'Iniciar sesión';

  @override
  String get loginInvalidCredentials => 'Correo o contraseña inválidos.';

  @override
  String get loginGenericError =>
      'No se pudo iniciar sesión. Intenta de nuevo.';

  @override
  String get loginNoAccount => '¿Aún no tienes cuenta?';

  @override
  String get loginCreateAccount => 'Crear cuenta';

  @override
  String get registerTitle => 'Crear cuenta';

  @override
  String get registerSubtitle => 'Regístrate para comenzar';

  @override
  String get registerNameLabel => 'Nombre completo';

  @override
  String get registerEmailLabel => 'Correo electrónico';

  @override
  String get registerPasswordLabel => 'Contraseña';

  @override
  String get registerConfirmPasswordLabel => 'Confirmar contraseña';

  @override
  String get registerNameRequired => 'Ingresa tu nombre';

  @override
  String get registerPasswordTooShort => 'Usa al menos 6 caracteres';

  @override
  String get registerButton => 'Crear cuenta';

  @override
  String get registerPasswordMismatch => 'Las contraseñas no coinciden.';

  @override
  String get registerAlreadyHaveAccount => '¿Ya tienes cuenta?';

  @override
  String get registerSignIn => 'Inicia sesión';

  @override
  String get registerGenericError =>
      'No se pudo crear la cuenta. Intenta de nuevo.';

  @override
  String get homeWelcome => '¿Qué vas a pagar hoy?';

  @override
  String homeGreeting(Object nombre) {
    return '¡Hola, $nombre!';
  }

  @override
  String get navInicio => 'Inicio';

  @override
  String get navHistorial => 'Historial';

  @override
  String get navPerfil => 'Perfil';

  @override
  String get homeCatalog => 'Servicios';

  @override
  String get homeProfile => 'Perfil';

  @override
  String get catalogTitle => 'Servicios';

  @override
  String get catalogAll => 'Todos';

  @override
  String get catalogSearchHint => 'Buscar servicios...';

  @override
  String get catalogEmpty => 'No hay servicios disponibles.';

  @override
  String get catalogPrice => 'Precio';

  @override
  String get catalogCommission => 'Comisión';

  @override
  String get catalogDetails => 'Detalle del servicio';

  @override
  String get catalogReferenceTypeA => 'Número de teléfono';

  @override
  String get catalogReferenceTypeB => 'Número de cliente / contrato';

  @override
  String get catalogReferenceTypeC => 'Código de barras / referencia';

  @override
  String get catalogReferenceDefault => 'Referencia';

  @override
  String get catalogDigitoVerificador => 'Dígito verificador';

  @override
  String get catalogHelp => 'Ayuda';

  @override
  String get catalogError => 'No se pudo cargar el catálogo.';

  @override
  String get pagoReferenceLabel => 'Referencia';

  @override
  String get pagoReferenceHint => 'Ej. 6241234567';

  @override
  String get pagoReferenceRequired => 'Ingresa la referencia';

  @override
  String get pagoServicioNoDisponible => 'El servicio no está disponible.';

  @override
  String get pagoAmountLabel => 'Monto a pagar';

  @override
  String get pagoAmountHint => '0.00';

  @override
  String get pagoServiceLabel => 'Servicio';

  @override
  String get pagoVerifyReference => 'Verificar referencia';

  @override
  String get pagoVerifying => 'Verificando referencia...';

  @override
  String get pagoVerifyValid => 'Referencia válida';

  @override
  String pagoValidReferenceMessage(Object saldo) {
    return 'Referencia válida. Saldo: $saldo.';
  }

  @override
  String get pagoVerifyInvalid =>
      'Referencia inválida. Revísala e intenta de nuevo.';

  @override
  String get pagoVerifyError => 'No se pudo verificar la referencia.';

  @override
  String get pagoInvalidAmount => 'Ingresa un monto válido.';

  @override
  String get pagoConfirmTitle => 'Confirmar pago';

  @override
  String pagoConfirmMessage(Object amount, Object reference, Object service) {
    return 'Vas a pagar $service con referencia $reference por $amount. Confirma que los datos sean correctos.';
  }

  @override
  String get pagoConfirmService => 'Servicio';

  @override
  String get pagoConfirmReference => 'Referencia';

  @override
  String get pagoConfirmAmount => 'Monto';

  @override
  String get pagoConfirmButton => 'Pagar ahora';

  @override
  String get pagoEnviado =>
      'Pago enviado. Esperando confirmación del proveedor...';

  @override
  String get pagoProcessing =>
      'Procesando el pago... Podrás consultar el resultado en cualquier momento desde tu historial.';

  @override
  String get pagoCheckingResult => 'Consultando resultado con el proveedor...';

  @override
  String get pagoSuccess => 'Pago realizado con éxito';

  @override
  String get pagoAuthorization => 'Autorización';

  @override
  String get pagoTransactionId => 'Transacción';

  @override
  String get pagoFailed => 'El pago no se completó';

  @override
  String get pagoPending =>
      'Pago en proceso. Lo confirmaremos con el proveedor.';

  @override
  String get pagoReceipt => 'Comprobante';

  @override
  String get pagoSeeHistory => 'Ver historial';

  @override
  String get pagoDoNotDoubleSubmit => 'Espera, no cierres la aplicación.';

  @override
  String get comprobanteTitle => 'Comprobante de pago';

  @override
  String get comprobanteFecha => 'Fecha';

  @override
  String get comprobanteEstado => 'Estado';

  @override
  String get comprobanteVolverInicio => 'Volver al inicio';

  @override
  String get historialTitle => 'Historial de pagos';

  @override
  String get historialEmpty => 'Aún no hay pagos.';

  @override
  String get historialError => 'No se pudo cargar el historial.';

  @override
  String get historialFecha => 'Fecha';

  @override
  String get historialVerComprobante => 'Ver comprobante';

  @override
  String get historialStateApproved => 'Aprobado';

  @override
  String get historialStateFailed => 'Fallido';

  @override
  String get historialStateProcessing => 'En proceso';

  @override
  String get historialStatePending => 'Pendiente';

  @override
  String get perfilTitle => 'Perfil';

  @override
  String get perfilName => 'Nombre';

  @override
  String get perfilEmail => 'Correo electrónico';

  @override
  String get perfilEdit => 'Editar datos personales';

  @override
  String get perfilPersonaName => 'Nombre';

  @override
  String get perfilPersonaPaternal => 'Apellido paterno';

  @override
  String get perfilPersonaMaternal => 'Apellido materno';

  @override
  String get perfilSaveSuccess => 'Datos guardados correctamente.';

  @override
  String get perfilTheme => 'Apariencia';

  @override
  String get perfilThemeSystem => 'Automático';

  @override
  String get perfilThemeLight => 'Claro';

  @override
  String get perfilThemeDark => 'Oscuro';

  @override
  String get perfilLogout => 'Cerrar sesión';

  @override
  String get perfilLogoutConfirm => '¿Cerrar sesión?';

  @override
  String get perfilLogoutConfirmMessage =>
      'Necesitarás tu contraseña para volver a entrar.';

  @override
  String get cardPayAction => 'Pagar';

  @override
  String get themeDark => 'Oscuro';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeSwitchToLight => 'Cambiar a modo claro';

  @override
  String get themeSwitchToDark => 'Cambiar a modo oscuro';

  @override
  String get plazosTitle => 'Paga en plazos';

  @override
  String get plazosSubtitle => 'Compara el costo de financiar tu pago.';

  @override
  String plazosMonths(int months) {
    return '$months meses';
  }

  @override
  String get plazosPerMonth => '/ mes';

  @override
  String get plazosTotal => 'Total a pagar';

  @override
  String get plazosCost => 'Costo del financiamiento';

  @override
  String get plazosSinCosto => 'Sin costo';

  @override
  String plazosRate(double rate) {
    return '$rate% anual';
  }

  @override
  String plazosSelect(int months) {
    return 'Elegir $months meses';
  }

  @override
  String plazosPlanLabel(int months) {
    return 'Plan de $months meses';
  }

  @override
  String get plazosDisclaimer =>
      'Simulacion de calculo. El monto final y las condiciones los define el proveedor.';

  @override
  String get valReferenciaVacia => 'Escribe la referencia del pago.';

  @override
  String get valReferenciaFormato =>
      'La referencia solo admite letras y numeros.';

  @override
  String get valReferenciaMovil => 'El numero de movil debe tener 10 digitos.';

  @override
  String get valReferenciaCuenta => 'Revisa los datos de la cuenta o recibo.';

  @override
  String get valReferenciaLargo => 'La referencia no tiene el largo esperado.';

  @override
  String get valReferenciaCorto => 'La referencia esta incompleta.';

  @override
  String get valReferenciaDigito =>
      'La referencia debe incluir el digito verificador completo.';

  @override
  String get homePopulares => 'Servicios populares';

  @override
  String get homePopularesSub => 'Los mas usados';

  @override
  String get homeTodosServicios => 'Todos los servicios';

  @override
  String homeTodosServiciosSub(int count) {
    return '$count disponibles';
  }

  @override
  String get gridDesde => 'desde';

  @override
  String get catTiempoAire => 'Tiempo Aire';

  @override
  String get catInternet => 'Internet';

  @override
  String get catTelevision => 'TV';

  @override
  String get catEntretenimiento => 'Entretenimiento';

  @override
  String get catServicios => 'Servicios';

  @override
  String get catTransporte => 'Transporte';

  @override
  String get pendientesTitulo => 'Pagos pendientes';

  @override
  String get pendientesSub => 'En proceso, pendientes o por reintentar';

  @override
  String get pendientesVacio => 'No tienes pagos pendientes.';

  @override
  String get cardTodos => 'Ver todos';

  @override
  String homeResultados(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count resultados',
      one: '1 resultado',
      zero: 'Sin resultados',
    );
    return '$_temp0';
  }

  @override
  String get homeVerTodos => 'Ver todos';
}
