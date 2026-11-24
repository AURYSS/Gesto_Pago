import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format/message_de_error.dart';
import '../../../core/network/app_exception.dart';
import '../../../core/widgets/password_field.dart';
import '../../../l10n/app_localizations.dart';
import '../application/session_controller.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmacionController = TextEditingController();
  bool _cargando = false;
  String? _error;

  static final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmacionController.dispose();
    super.dispose();
  }

  Future<void> _crearCuenta() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final l = AppLocalizations.of(context);
    final pass = _passwordController.text;
    final conf = _confirmacionController.text;

    if (pass != conf) {
      setState(() => _error = l.registerPasswordMismatch);
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
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      await ref.read(sessionControllerProvider.notifier).register(
            nombre: _nombreController.text.trim(),
            email: _emailController.text,
            password: _passwordController.text,
          );
      // El router redirige a /home al autenticarse.
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
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.registerTitle)),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(l.registerSubtitle, style: Theme.of(context).textTheme.bodyLarge),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _nombreController,
                      enabled: !_cargando,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      autocorrect: false,
                      decoration: InputDecoration(
                        labelText: l.registerNameLabel,
                        prefixIcon: const Icon(Icons.badge_outlined),
                      ),
                      validator: (value) {
                        final v = value?.trim() ?? '';
                        if (v.isEmpty) {
                          return l.registerNameRequired;
                        }
                        if (v.length < 2 || v.length > 50) {
                          return 'El nombre debe tener entre 2 y 50 caracteres';
                        }
                        if (!RegExp(r"^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$").hasMatch(v)) {
                          return 'Solo se permiten letras y espacios';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      enabled: !_cargando,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      autocorrect: false,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: l.registerEmailLabel,
                        prefixIcon: const Icon(Icons.alternate_email),
                      ),
                      validator: (value) {
                        final v = value?.trim() ?? '';
                        if (v.isEmpty) {
                          return l.loginEmailRequired;
                        }
                        if (!_emailRegex.hasMatch(v)) {
                          return l.loginEmailInvalid;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    PasswordField(
                      controller: _passwordController,
                      label: l.registerPasswordLabel,
                      enabled: !_cargando,
                    ),
                    const SizedBox(height: 16),
                    PasswordField(
                      controller: _confirmacionController,
                      label: l.registerConfirmPasswordLabel,
                      enabled: !_cargando,
                      onSubmitted: (_) => _cargando ? null : _crearCuenta(),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      _ErrorBanner(mensaje: _error!),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _cargando ? null : _crearCuenta,
                      child: _cargando
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2.4),
                            )
                          : Text(l.registerButton),
                    ),
                    const SizedBox(height: 24),
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          l.registerAlreadyHaveAccount,
                          style: Theme.of(context).textTheme.bodyMedium,
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