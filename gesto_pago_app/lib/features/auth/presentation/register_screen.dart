import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format/message_de_error.dart';
import '../../../core/network/app_exception.dart';
import '../../../core/widgets/password_field.dart';
import '../../../l10n/app_localizations.dart';
import '../application/session_controller.dart';
import '../domain/persona_fisica_registro.dart';

/// Pantalla de Onboarding y Registro de Persona Física en 3 pasos:
/// Paso 1: Datos Personales
/// Paso 2: Domicilio y Contacto
/// Paso 3: Información Laboral y Acceso
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  int _step = 1; // 1, 2, 3

  final _formKeyStep1 = GlobalKey<FormState>();
  final _formKeyStep2 = GlobalKey<FormState>();
  final _formKeyStep3 = GlobalKey<FormState>();

  // Paso 1: Datos Personales
  final _nombreController = TextEditingController();
  final _segundoNombreController = TextEditingController();
  final _apellidoPaternoController = TextEditingController();
  final _apellidoMaternoController = TextEditingController();
  final _fechaNacimientoController = TextEditingController();
  final _curpController = TextEditingController();
  final _rfcController = TextEditingController();
  String _sexo = 'MASCULINO';
  final _nacionalidadController = TextEditingController(text: 'Mexicana');
  String _estadoCivil = 'SOLTERO';

  // Paso 2: Contacto y Domicilio
  final _correoController = TextEditingController();
  final _telefonoMovilController = TextEditingController();
  final _telefonoAlternativoController = TextEditingController();
  final _calleController = TextEditingController();
  final _numeroExteriorController = TextEditingController();
  final _numeroInteriorController = TextEditingController();
  final _coloniaController = TextEditingController();
  final _municipioController = TextEditingController();
  final _estadoController = TextEditingController(text: 'Guanajuato');
  final _codigoPostalController = TextEditingController();
  final _paisController = TextEditingController(text: 'México');

  // Paso 3: Laboral y Acceso
  final _ocupacionController = TextEditingController();
  final _empresaController = TextEditingController();
  final _ingresoMensualController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmacionController = TextEditingController();

  bool _cargando = false;
  String? _error;

  // Regex oficiales y de negocio
  static final _soloLetrasRegex = RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$');
  static final _curpRegex = RegExp(r'^[A-Z]{4}\d{6}[HM][A-Z]{5}[A-Z0-9]\d$');
  static final _rfcRegex = RegExp(r'^[A-ZÑ&]{3,4}\d{6}[A-Z0-9]{3}$');
  static final _emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
  static final _diezDigitosRegex = RegExp(r'^\d{10}$');
  static final _cincoDigitosRegex = RegExp(r'^\d{5}$');

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_onPasswordChanged);
  }

  void _onPasswordChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _passwordController.removeListener(_onPasswordChanged);
    _nombreController.dispose();
    _segundoNombreController.dispose();
    _apellidoPaternoController.dispose();
    _apellidoMaternoController.dispose();
    _fechaNacimientoController.dispose();
    _curpController.dispose();
    _rfcController.dispose();
    _nacionalidadController.dispose();

    _correoController.dispose();
    _telefonoMovilController.dispose();
    _telefonoAlternativoController.dispose();
    _calleController.dispose();
    _numeroExteriorController.dispose();
    _numeroInteriorController.dispose();
    _coloniaController.dispose();
    _municipioController.dispose();
    _estadoController.dispose();
    _codigoPostalController.dispose();
    _paisController.dispose();

    _ocupacionController.dispose();
    _empresaController.dispose();
    _ingresoMensualController.dispose();
    _passwordController.dispose();
    _confirmacionController.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFechaNacimiento() async {
    FocusScope.of(context).unfocus();
    final ahora = DateTime.now();
    final fechaInicial = DateTime(ahora.year - 25, ahora.month, ahora.day);
    final fechaMin = DateTime(1920, 1, 1);

    final seleccion = await showDatePicker(
      context: context,
      initialDate: fechaInicial,
      firstDate: fechaMin,
      lastDate: ahora,
      helpText: 'Fecha de nacimiento (mayor de 18 años)',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
    );

    if (seleccion != null) {
      final y = seleccion.year.toString().padLeft(4, '0');
      final m = seleccion.month.toString().padLeft(2, '0');
      final d = seleccion.day.toString().padLeft(2, '0');
      setState(() {
        _fechaNacimientoController.text = '$y-$m-$d';
      });
      _formKeyStep1.currentState?.validate();
    }
  }

  String? _validarFechaNacimiento(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) {
      return 'La fecha de nacimiento es obligatoria';
    }
    final partes = v.split('-');
    if (partes.length != 3) {
      return 'Formato de fecha inválido (AAAA-MM-DD)';
    }
    final year = int.tryParse(partes[0]);
    final month = int.tryParse(partes[1]);
    final day = int.tryParse(partes[2]);
    if (year == null || month == null || day == null) {
      return 'Formato de fecha inválido (AAAA-MM-DD)';
    }
    final nac = DateTime(year, month, day);
    final hoy = DateTime.now();
    if (nac.isAfter(hoy)) {
      return 'La fecha de nacimiento no puede ser futura';
    }
    int edad = hoy.year - nac.year;
    final mDiff = hoy.month - nac.month;
    if (mDiff < 0 || (mDiff == 0 && hoy.day < nac.day)) {
      edad--;
    }
    if (edad < 18) {
      return 'El cliente debe ser mayor de edad (18 años o más)';
    }
    return null;
  }

  void _irASiguientePaso() {
    FocusScope.of(context).unfocus();
    setState(() => _error = null);

    if (_step == 1) {
      if (!_formKeyStep1.currentState!.validate()) {
        setState(() => _error = 'Por favor completa y corrige los campos de Datos Personales');
        return;
      }
      setState(() => _step = 2);
    } else if (_step == 2) {
      if (!_formKeyStep2.currentState!.validate()) {
        setState(() => _error = 'Por favor completa y corrige los campos de Domicilio y Contacto');
        return;
      }
      setState(() => _step = 3);
    }
  }

  void _irAPasoAnterior() {
    FocusScope.of(context).unfocus();
    setState(() {
      _error = null;
      if (_step > 1) {
        _step--;
      }
    });
  }

  Future<void> _crearCuenta() async {
    FocusScope.of(context).unfocus();
    setState(() => _error = null);

    if (!_formKeyStep3.currentState!.validate()) {
      setState(() => _error = 'Por favor verifica la información laboral y de acceso');
      return;
    }

    final pass = _passwordController.text;
    final conf = _confirmacionController.text;

    if (pass != conf) {
      setState(() => _error = 'Las contraseñas no coinciden.');
      return;
    }
    if (pass.length < 8) {
      setState(() => _error = 'La contraseña debe contener al menos 8 caracteres.');
      return;
    }
    if (!RegExp(r'[A-Z]').hasMatch(pass)) {
      setState(() => _error = 'La contraseña debe incluir al menos una letra mayúscula.');
      return;
    }
    if (!RegExp(r'[a-z]').hasMatch(pass)) {
      setState(() => _error = 'La contraseña debe incluir al menos una letra minúscula.');
      return;
    }
    if (!RegExp(r'[0-9]').hasMatch(pass)) {
      setState(() => _error = 'La contraseña debe incluir al menos un número.');
      return;
    }
    if (!RegExp(r'''[!@#$%^&*()_+\-=\[\]{};':"\\|,.<>/?]''').hasMatch(pass)) {
      setState(() => _error = 'La contraseña debe incluir al menos un carácter especial.');
      return;
    }

    final ingreso = double.tryParse(_ingresoMensualController.text.replaceAll(',', '')) ?? 0.0;
    if (ingreso <= 0) {
      setState(() => _error = 'El ingreso mensual debe ser mayor a cero.');
      return;
    }

    final registro = PersonaFisicaRegistro(
      nombre: _nombreController.text.trim(),
      segundoNombre: _segundoNombreController.text.trim().isNotEmpty
          ? _segundoNombreController.text.trim()
          : null,
      apellidoPaterno: _apellidoPaternoController.text.trim(),
      apellidoMaterno: _apellidoMaternoController.text.trim(),
      fechaNacimiento: _fechaNacimientoController.text.trim(),
      curp: _curpController.text.trim().toUpperCase(),
      rfc: _rfcController.text.trim().toUpperCase(),
      sexo: _sexo,
      nacionalidad: _nacionalidadController.text.trim(),
      estadoCivil: _estadoCivil,
      correo: _correoController.text.trim().toLowerCase(),
      telefonoMovil: _telefonoMovilController.text.trim(),
      telefonoAlternativo: _telefonoAlternativoController.text.trim().isNotEmpty
          ? _telefonoAlternativoController.text.trim()
          : null,
      calle: _calleController.text.trim(),
      numeroExterior: _numeroExteriorController.text.trim(),
      numeroInterior: _numeroInteriorController.text.trim().isNotEmpty
          ? _numeroInteriorController.text.trim()
          : null,
      colonia: _coloniaController.text.trim(),
      municipio: _municipioController.text.trim(),
      estado: _estadoController.text.trim(),
      codigoPostal: _codigoPostalController.text.trim(),
      pais: _paisController.text.trim(),
      ocupacion: _ocupacionController.text.trim(),
      empresa: _empresaController.text.trim(),
      ingresoMensual: ingreso,
      password: pass,
    );

    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      await ref.read(sessionControllerProvider.notifier).registerPersonaFisica(registro);
      // El router redirige automáticamente a /home al autenticarse.
    } on AppException catch (e) {
      if (mounted) {
        setState(() => _error = messageDeError(context, e));
      }
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('Registro falló con error inesperado: $e\n$st');
      }
      if (mounted) {
        setState(() => _error = AppLocalizations.of(context).errorGeneric);
      }
    } finally {
      if (mounted) {
        setState(() => _cargando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.registerTitle),
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Encabezado de Onboarding
                  _WizardHeader(pasoActual: _step),
                  const SizedBox(height: 20),

                  // Barra de progreso y pasos
                  _StepIndicator(pasoActual: _step),
                  const SizedBox(height: 24),

                  // Formulario según paso
                  if (_step == 1) _buildPaso1(context),
                  if (_step == 2) _buildPaso2(context),
                  if (_step == 3) _buildPaso3(context),

                  // Banner de error
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    _ErrorBanner(mensaje: _error!),
                  ],

                  const SizedBox(height: 24),

                  // Botones de Navegación del Wizard
                  _buildBotonesNavegacion(context),

                  const SizedBox(height: 24),
                  // Enlace a inicio de sesión
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        l.registerAlreadyHaveAccount,
                        style: theme.textTheme.bodyMedium,
                      ),
                      TextButton(
                        onPressed: _cargando ? null : () => context.go('/login'),
                        child: Text(l.registerSignIn),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- PASO 1: DATOS PERSONALES ---
  Widget _buildPaso1(BuildContext context) {
    return Form(
      key: _formKeyStep1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Paso 1: Datos Personales',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Ingresa tus datos de identidad oficial como Persona Física',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 16),

          // Nombre
          TextFormField(
            controller: _nombreController,
            enabled: !_cargando,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Nombre *',
              prefixIcon: Icon(Icons.person_outline),
            ),
            validator: (v) {
              final val = v?.trim() ?? '';
              if (val.isEmpty) return 'El nombre es obligatorio';
              if (val.length < 2 || val.length > 50) return 'Debe tener entre 2 y 50 caracteres';
              if (!_soloLetrasRegex.hasMatch(val)) return 'Solo se permiten letras y espacios';
              return null;
            },
          ),
          const SizedBox(height: 12),

          // Segundo nombre (opcional)
          TextFormField(
            controller: _segundoNombreController,
            enabled: !_cargando,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Segundo nombre (opcional)',
              prefixIcon: Icon(Icons.person_outline),
            ),
            validator: (v) {
              final val = v?.trim() ?? '';
              if (val.isNotEmpty && !_soloLetrasRegex.hasMatch(val)) {
                return 'Solo se permiten letras y espacios';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),

          // Apellidos Paterno y Materno
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: _apellidoPaternoController,
                  enabled: !_cargando,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Apellido paterno *',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  validator: (v) {
                    final val = v?.trim() ?? '';
                    if (val.isEmpty) return 'El apellido paterno es obligatorio';
                    if (val.length < 2 || val.length > 50) return 'Debe tener entre 2 y 50 caracteres';
                    if (!_soloLetrasRegex.hasMatch(val)) return 'Solo se permiten letras y espacios';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: _apellidoMaternoController,
                  enabled: !_cargando,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Apellido materno *',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  validator: (v) {
                    final val = v?.trim() ?? '';
                    if (val.isEmpty) return 'El apellido materno es obligatorio';
                    if (val.length < 2 || val.length > 50) return 'Debe tener entre 2 y 50 caracteres';
                    if (!_soloLetrasRegex.hasMatch(val)) return 'Solo se permiten letras y espacios';
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Fecha de nacimiento con DatePicker
          TextFormField(
            controller: _fechaNacimientoController,
            enabled: !_cargando,
            keyboardType: TextInputType.datetime,
            decoration: InputDecoration(
              labelText: 'Fecha de nacimiento (AAAA-MM-DD) *',
              hintText: 'AAAA-MM-DD',
              prefixIcon: const Icon(Icons.calendar_today_outlined),
              suffixIcon: IconButton(
                icon: const Icon(Icons.date_range),
                onPressed: _cargando ? null : _seleccionarFechaNacimiento,
              ),
            ),
            validator: _validarFechaNacimiento,
          ),
          const SizedBox(height: 12),

          // CURP
          TextFormField(
            controller: _curpController,
            enabled: !_cargando,
            textCapitalization: TextCapitalization.characters,
            maxLength: 18,
            textInputAction: TextInputAction.next,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
            ],
            decoration: const InputDecoration(
              labelText: 'CURP (18 caracteres) *',
              hintText: 'ABCD010203HDFRRN09',
              prefixIcon: Icon(Icons.fingerprint),
              counterText: '',
            ),
            validator: (v) {
              final val = v?.trim().toUpperCase() ?? '';
              if (val.isEmpty) return 'La CURP es obligatoria';
              if (val.length != 18) return 'La CURP debe contener exactamente 18 caracteres';
              if (!_curpRegex.hasMatch(val)) {
                return 'Formato de CURP inválido (ej. ABCD010203HDFRRN09)';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),

          // RFC
          TextFormField(
            controller: _rfcController,
            enabled: !_cargando,
            textCapitalization: TextCapitalization.characters,
            maxLength: 13,
            textInputAction: TextInputAction.next,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9&Ññ]')),
            ],
            decoration: const InputDecoration(
              labelText: 'RFC (12 o 13 caracteres) *',
              hintText: 'ABCD010203XX1',
              prefixIcon: Icon(Icons.credit_card),
              counterText: '',
            ),
            validator: (v) {
              final val = v?.trim().toUpperCase() ?? '';
              if (val.isEmpty) return 'El RFC es obligatorio';
              if (val.length < 12 || val.length > 13) return 'El RFC debe contener 12 o 13 caracteres';
              if (!_rfcRegex.hasMatch(val)) {
                return 'Formato de RFC inválido (ej. ABCD010203XX1)';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),

          // Sexo
          DropdownButtonFormField<String>(
            initialValue: _sexo,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Sexo *',
              prefixIcon: Icon(Icons.wc_outlined),
            ),
            items: const [
              DropdownMenuItem(value: 'MASCULINO', child: Text('Masculino (H)')),
              DropdownMenuItem(value: 'FEMENINO', child: Text('Femenino (M)')),
            ],
            onChanged: _cargando ? null : (v) => setState(() => _sexo = v ?? 'MASCULINO'),
            validator: (v) => (v == null || v.isEmpty) ? 'Selecciona el sexo' : null,
          ),
          const SizedBox(height: 12),

          // Estado Civil
          DropdownButtonFormField<String>(
            initialValue: _estadoCivil,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Estado civil *',
              prefixIcon: Icon(Icons.favorite_border),
            ),
            items: const [
              DropdownMenuItem(value: 'SOLTERO', child: Text('Soltero(a)')),
              DropdownMenuItem(value: 'CASADO', child: Text('Casado(a)')),
              DropdownMenuItem(value: 'DIVORCIADO', child: Text('Divorciado(a)')),
              DropdownMenuItem(value: 'VIUDO', child: Text('Viudo(a)')),
              DropdownMenuItem(value: 'UNION_LIBRE', child: Text('Unión Libre')),
            ],
            onChanged: _cargando ? null : (v) => setState(() => _estadoCivil = v ?? 'SOLTERO'),
            validator: (v) => (v == null || v.isEmpty) ? 'Selecciona el estado civil' : null,
          ),
          const SizedBox(height: 12),

          // Nacionalidad
          TextFormField(
            controller: _nacionalidadController,
            enabled: !_cargando,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'Nacionalidad *',
              prefixIcon: Icon(Icons.flag_outlined),
            ),
            validator: (v) {
              final val = v?.trim() ?? '';
              if (val.isEmpty) return 'La nacionalidad es obligatoria';
              return null;
            },
          ),
        ],
      ),
    );
  }

  // --- PASO 2: DOMICILIO Y CONTACTO ---
  Widget _buildPaso2(BuildContext context) {
    return Form(
      key: _formKeyStep2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Paso 2: Domicilio y Contacto',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Datos para autenticación, notificaciones 2FA y comprobante domiciliario',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 16),

          // Correo Electrónico
          TextFormField(
            controller: _correoController,
            enabled: !_cargando,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Correo electrónico (Usuario y 2FA) *',
              prefixIcon: Icon(Icons.alternate_email),
            ),
            validator: (v) {
              final val = v?.trim() ?? '';
              if (val.isEmpty) return 'El correo electrónico es obligatorio';
              if (val.length > 100) return 'El correo no puede exceder 100 caracteres';
              if (!_emailRegex.hasMatch(val)) {
                return 'Formato de correo inválido (ej. usuario@dominio.com)';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),

          // Teléfonos
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: _telefonoMovilController,
                  enabled: !_cargando,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  textInputAction: TextInputAction.next,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Teléfono móvil (10 dígitos) *',
                    prefixIcon: Icon(Icons.phone_android),
                    counterText: '',
                  ),
                  validator: (v) {
                    final val = v?.trim() ?? '';
                    if (val.isEmpty) return 'El teléfono móvil es obligatorio';
                    if (!_diezDigitosRegex.hasMatch(val)) {
                      return 'El teléfono debe contener exactamente 10 dígitos';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: _telefonoAlternativoController,
                  enabled: !_cargando,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  textInputAction: TextInputAction.next,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Teléfono alt. (opcional)',
                    prefixIcon: Icon(Icons.phone),
                    counterText: '',
                  ),
                  validator: (v) {
                    final val = v?.trim() ?? '';
                    if (val.isNotEmpty && !_diezDigitosRegex.hasMatch(val)) {
                      return 'Debe contener exactamente 10 dígitos';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Calle
          TextFormField(
            controller: _calleController,
            enabled: !_cargando,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Calle *',
              prefixIcon: Icon(Icons.home_outlined),
            ),
            validator: (v) => (v?.trim().isEmpty ?? true) ? 'La calle es obligatoria' : null,
          ),
          const SizedBox(height: 12),

          // Número exterior e interior
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: _numeroExteriorController,
                  enabled: !_cargando,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Núm. exterior *',
                    prefixIcon: Icon(Icons.pin_outlined),
                  ),
                  validator: (v) => (v?.trim().isEmpty ?? true) ? 'El número exterior es obligatorio' : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: _numeroInteriorController,
                  enabled: !_cargando,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Núm. interior (opcional)',
                    prefixIcon: Icon(Icons.tag),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Colonia y Código Postal
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _coloniaController,
                  enabled: !_cargando,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Colonia *',
                    prefixIcon: Icon(Icons.location_city_outlined),
                  ),
                  validator: (v) => (v?.trim().isEmpty ?? true) ? 'La colonia es obligatoria' : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 1,
                child: TextFormField(
                  controller: _codigoPostalController,
                  enabled: !_cargando,
                  keyboardType: TextInputType.number,
                  maxLength: 5,
                  textInputAction: TextInputAction.next,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'C.P. (5 dígitos) *',
                    prefixIcon: Icon(Icons.markunread_mailbox_outlined),
                    counterText: '',
                  ),
                  validator: (v) {
                    final val = v?.trim() ?? '';
                    if (val.isEmpty) return 'El C.P. es obligatorio';
                    if (!_cincoDigitosRegex.hasMatch(val)) {
                      return 'Debe ser de 5 dígitos';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Municipio, Estado y País
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: _municipioController,
                  enabled: !_cargando,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Municipio *',
                    prefixIcon: Icon(Icons.map_outlined),
                  ),
                  validator: (v) => (v?.trim().isEmpty ?? true) ? 'El municipio es obligatorio' : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: _estadoController,
                  enabled: !_cargando,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Estado *',
                    prefixIcon: Icon(Icons.public),
                  ),
                  validator: (v) => (v?.trim().isEmpty ?? true) ? 'El estado es obligatorio' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          TextFormField(
            controller: _paisController,
            enabled: !_cargando,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'País *',
              prefixIcon: Icon(Icons.travel_explore),
            ),
            validator: (v) => (v?.trim().isEmpty ?? true) ? 'El país es obligatorio' : null,
          ),
        ],
      ),
    );
  }

  // --- PASO 3: INFORMACIÓN LABORAL Y ACCESO ---
  Widget _buildPaso3(BuildContext context) {
    final pass = _passwordController.text;
    final tieneLongitud = pass.length >= 8;
    final tieneMayuscula = RegExp(r'[A-Z]').hasMatch(pass);
    final tieneMinuscula = RegExp(r'[a-z]').hasMatch(pass);
    final tieneNumero = RegExp(r'[0-9]').hasMatch(pass);
    final tieneEspecial = RegExp(r'''[!@#$%^&*()_+\-=\[\]{};':"\\|,.<>/?]''').hasMatch(pass);

    final puntaje = [tieneLongitud, tieneMayuscula, tieneMinuscula, tieneNumero, tieneEspecial]
        .where((cumple) => cumple)
        .length;

    Color colorFuerza;
    String textoFuerza;
    double porcentaje;
    if (pass.isEmpty) {
      colorFuerza = Colors.grey;
      textoFuerza = 'Sin ingresar';
      porcentaje = 0.0;
    } else if (puntaje <= 2) {
      colorFuerza = Colors.redAccent;
      textoFuerza = 'Débil';
      porcentaje = 0.33;
    } else if (puntaje <= 4) {
      colorFuerza = Colors.amber;
      textoFuerza = 'Media';
      porcentaje = 0.66;
    } else {
      colorFuerza = Colors.green;
      textoFuerza = 'Fuerte';
      porcentaje = 1.0;
    }

    return Form(
      key: _formKeyStep3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Paso 3: Información Laboral y Acceso',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Información financiera y credenciales seguras para apertura de cuenta',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 16),

          // Ocupación y Empresa
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: _ocupacionController,
                  enabled: !_cargando,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Ocupación *',
                    prefixIcon: Icon(Icons.work_outline),
                  ),
                  validator: (v) => (v?.trim().isEmpty ?? true) ? 'La ocupación es obligatoria' : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: _empresaController,
                  enabled: !_cargando,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Empresa / Empleador *',
                    prefixIcon: Icon(Icons.business_outlined),
                  ),
                  validator: (v) => (v?.trim().isEmpty ?? true) ? 'La empresa es obligatoria' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Ingreso mensual
          TextFormField(
            controller: _ingresoMensualController,
            enabled: !_cargando,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Ingreso mensual (MXN) *',
              hintText: '18000.00',
              prefixIcon: Icon(Icons.attach_money),
            ),
            validator: (v) {
              final val = v?.trim() ?? '';
              if (val.isEmpty) return 'El ingreso mensual es obligatorio';
              final n = double.tryParse(val.replaceAll(',', ''));
              if (n == null || n <= 0) return 'El ingreso mensual debe ser mayor a cero';
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Contraseña
          PasswordField(
            controller: _passwordController,
            label: 'Contraseña *',
            enabled: !_cargando,
            validator: (v) {
              final val = v ?? '';
              if (val.isEmpty) return 'La contraseña es obligatoria';
              if (val.length < 8) return 'Mínimo 8 caracteres';
              if (!RegExp(r'[A-Z]').hasMatch(val)) return 'Debe incluir al menos una mayúscula (A-Z)';
              if (!RegExp(r'[a-z]').hasMatch(val)) return 'Debe incluir al menos una minúscula (a-z)';
              if (!RegExp(r'[0-9]').hasMatch(val)) return 'Debe incluir al menos un número (0-9)';
              if (!RegExp(r'''[!@#$%^&*()_+\-=\[\]{};':"\\|,.<>/?]''').hasMatch(val)) {
                return 'Debe incluir al menos un carácter especial';
              }
              return null;
            },
          ),
          const SizedBox(height: 8),

          // Barra medidora de fuerza
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: porcentaje,
                    minHeight: 6,
                    backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(colorFuerza),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Seguridad: $textoFuerza',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: colorFuerza,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Checklist interactivo en vivo
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Requisitos de contraseña:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                _ChecklistRow(cumplido: tieneLongitud, texto: 'Mínimo 8 caracteres'),
                _ChecklistRow(cumplido: tieneMayuscula, texto: 'Al menos una letra mayúscula (A-Z)'),
                _ChecklistRow(cumplido: tieneMinuscula, texto: 'Al menos una letra minúscula (a-z)'),
                _ChecklistRow(cumplido: tieneNumero, texto: 'Al menos un número (0-9)'),
                _ChecklistRow(cumplido: tieneEspecial, texto: 'Al menos un carácter especial (!@#\$%^&*...)'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Confirmar Contraseña
          PasswordField(
            controller: _confirmacionController,
            label: 'Confirmar contraseña *',
            enabled: !_cargando,
            onSubmitted: (_) => _cargando ? null : _crearCuenta(),
            validator: (v) {
              final val = v ?? '';
              if (val.isEmpty) return 'Confirma tu contraseña';
              if (val != _passwordController.text) return 'Las contraseñas no coinciden';
              return null;
            },
          ),
        ],
      ),
    );
  }

  // --- BOTONES DE NAVEGACIÓN ---
  Widget _buildBotonesNavegacion(BuildContext context) {
    if (_step == 1) {
      return FilledButton.icon(
        onPressed: _cargando ? null : _irASiguientePaso,
        icon: const Icon(Icons.arrow_forward, size: 18),
        label: const Text('Siguiente'),
      );
    }

    if (_step == 2) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _cargando ? null : _irAPasoAnterior,
              icon: const Icon(Icons.arrow_back, size: 18),
              label: const Text('Anterior'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton.icon(
              onPressed: _cargando ? null : _irASiguientePaso,
              icon: const Icon(Icons.arrow_forward, size: 18),
              label: const Text('Siguiente'),
            ),
          ),
        ],
      );
    }

    // Paso 3
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: OutlinedButton.icon(
            onPressed: _cargando ? null : _irAPasoAnterior,
            icon: const Icon(Icons.arrow_back, size: 18),
            label: const Text('Anterior'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: FilledButton.icon(
            onPressed: _cargando ? null : _crearCuenta,
            icon: _cargando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.person_add_alt_1, size: 18),
            label: Text(_cargando ? 'Registrando...' : 'Registrar y Abrir Cuenta'),
          ),
        ),
      ],
    );
  }
}

// --- SUBCOMPONENTES DE PRESENTACIÓN ---

class _WizardHeader extends StatelessWidget {
  const _WizardHeader({required this.pasoActual});

  final int pasoActual;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            Icons.account_balance_wallet_outlined,
            size: 28,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Gesto Pago Mobile',
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          'Onboarding de Clientes: Persona Física y Apertura de Cuenta',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.pasoActual});

  final int pasoActual;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final surfaceVariant = theme.colorScheme.surfaceContainerHighest;

    return Column(
      children: [
        Row(
          children: [
            _buildStepCircle(context, 1, 'Personales', Icons.person_outline),
            Expanded(
              child: Container(
                height: 3,
                color: pasoActual > 1 ? primary : surfaceVariant,
              ),
            ),
            _buildStepCircle(context, 2, 'Contacto', Icons.home_outlined),
            Expanded(
              child: Container(
                height: 3,
                color: pasoActual > 2 ? primary : surfaceVariant,
              ),
            ),
            _buildStepCircle(context, 3, 'Acceso', Icons.lock_outline),
          ],
        ),
      ],
    );
  }

  Widget _buildStepCircle(BuildContext context, int stepNumber, String label, IconData icon) {
    final theme = Theme.of(context);
    final isActive = pasoActual == stepNumber;
    final isDone = pasoActual > stepNumber;

    Color bg;
    Color fg;
    if (isDone) {
      bg = theme.colorScheme.primary;
      fg = theme.colorScheme.onPrimary;
    } else if (isActive) {
      bg = theme.colorScheme.primary;
      fg = theme.colorScheme.onPrimary;
    } else {
      bg = theme.colorScheme.surfaceContainerHighest;
      fg = theme.colorScheme.onSurfaceVariant;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: bg,
            shape: BoxShape.circle,
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    )
                  ]
                : null,
          ),
          child: Center(
            child: isDone
                ? const Icon(Icons.check, size: 20, color: Colors.white)
                : Icon(icon, size: 18, color: fg),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isActive || isDone ? FontWeight.bold : FontWeight.normal,
            color: isActive ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _ChecklistRow extends StatelessWidget {
  const _ChecklistRow({required this.cumplido, required this.texto});

  final bool cumplido;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        children: [
          Icon(
            cumplido ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 15,
            color: cumplido ? Colors.green : Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              texto,
              style: TextStyle(
                fontSize: 12,
                color: cumplido
                    ? Theme.of(context).colorScheme.onSurface
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.mensaje});

  final String mensaje;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).colorScheme.error.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              mensaje,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }
}
