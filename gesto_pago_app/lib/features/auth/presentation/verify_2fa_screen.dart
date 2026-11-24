import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format/message_de_error.dart';
import '../../../core/network/app_exception.dart';
import '../../../core/theme/gp_colors.dart';
import '../application/session_controller.dart';

class Verify2FaScreen extends ConsumerStatefulWidget {
  const Verify2FaScreen({
    super.key,
    required this.tempToken,
    required this.email,
    this.codigo2FaDev,
    this.correoEnmascarado,
  });

  final String tempToken;
  final String email;
  final String? codigo2FaDev;
  final String? correoEnmascarado;

  @override
  ConsumerState<Verify2FaScreen> createState() => _Verify2FaScreenState();
}

class _Verify2FaScreenState extends ConsumerState<Verify2FaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codigoController = TextEditingController();
  bool _cargando = false;
  String? _error;

  @override
  void dispose() {
    _codigoController.dispose();
    super.dispose();
  }

  Future<void> _verificar({bool forzarCierre = false}) async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      await ref.read(sessionControllerProvider.notifier).complete2Fa(
            tempToken: widget.tempToken,
            codigo: _codigoController.text.trim(),
            email: widget.email,
            forzarCierre: forzarCierre,
          );
      // El router redirigirá a /home al autenticarse.
    } on ConcurrentSessionException catch (e) {
      if (!mounted) return;
      await _mostrarDialogoConflictoSesion(e);
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = messageDeError(context, e);
      });
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('Error en 2FA: $e\n$st');
      }
      if (mounted) {
        setState(() {
          _error = 'Ocurrió un error inesperado al verificar el código.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _cargando = false);
      }
    }
  }

  Future<void> _mostrarDialogoConflictoSesion(ConcurrentSessionException e) async {
    final dispositivo = e.dispositivoActivo ?? 'la plataforma Web';
    final aceptar = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.devices_other_rounded, size: 48, color: Colors.amber),
        title: const Text('Sesión activa detectada'),
        content: Text(
          'Existe una sesión activa en $dispositivo. '
          'Para cumplir con la política de sesión única, debes cerrar la sesión anterior para ingresar en este dispositivo.\n\n'
          '¿Deseas cerrar la otra sesión y continuar aquí?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: GpColors.verde),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Cerrar sesión anterior y entrar'),
          ),
        ],
      ),
    );

    if (aceptar == true) {
      await _verificar(forzarCierre: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final correoDestino = widget.correoEnmascarado ?? widget.email;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Autenticación 2FA'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/login'),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: GpColors.verde.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: GpColors.verde, width: 2),
                      ),
                      child: const Icon(
                        Icons.verified_user_rounded,
                        size: 44,
                        color: GpColors.verde,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Código de Verificación',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Revisa tu bandeja de entrada o spam.\nIngresa el código OTP de 6 dígitos enviado a:\n$correoDestino',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey.shade400,
                          ),
                    ),
                    const SizedBox(height: 28),
                    TextFormField(
                      controller: _codigoController,
                      enabled: !_cargando,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 6,
                      style: const TextStyle(
                        fontSize: 28,
                        letterSpacing: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        hintText: '000000',
                        counterText: '',
                        prefixIcon: const Icon(Icons.lock_clock_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      validator: (value) {
                        final v = value?.trim() ?? '';
                        if (v.isEmpty) {
                          return 'Ingresa el código de 6 dígitos';
                        }
                        if (v.length != 6 || !RegExp(r'^\d{6}$').hasMatch(v)) {
                          return 'El código debe tener exactamente 6 números';
                        }
                        return null;
                      },
                      onFieldSubmitted: (_) => _cargando ? null : _verificar(),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade900.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.red.shade700),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.redAccent),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _error!,
                                style: const TextStyle(color: Colors.redAccent),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: _cargando ? null : () => _verificar(),
                      child: _cargando
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2.4),
                            )
                          : const Text(
                              'Verificar e Ingresar',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: _cargando ? null : () => context.go('/login'),
                      child: const Text('Cancelar y volver al inicio de sesión'),
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
