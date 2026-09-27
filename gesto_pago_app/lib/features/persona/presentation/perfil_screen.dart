import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format/message_de_error.dart';
import '../../../core/network/app_exception.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/gp_colors.dart';
import '../../../core/theme/gp_theme.dart';
import '../../../core/widgets/pressable.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/application/session_controller.dart';
import '../domain/persona.dart';

class PerfilScreen extends ConsumerStatefulWidget {
  const PerfilScreen({super.key});

  @override
  ConsumerState<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends ConsumerState<PerfilScreen> {
  final _nombreController = TextEditingController();
  final _paternoController = TextEditingController();
  final _maternoController = TextEditingController();
  bool _guardando = false;

  @override
  void dispose() {
    _nombreController.dispose();
    _paternoController.dispose();
    _maternoController.dispose();
    super.dispose();
  }

  String _iniciales(String nombre) {
    final partes =
        nombre.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (partes.isEmpty) {
      return 'GP';
    }
    if (partes.length == 1) {
      return partes.first.characters.first.toUpperCase();
    }
    return '${partes.first.characters.first}${partes.last.characters.first}'.toUpperCase();
  }

  Future<void> _editarDatosPersonales(AppLocalizations l, String nombreActual) async {
    _nombreController.text = nombreActual;
    _paternoController.clear();
    _maternoController.clear();

    final guardar = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(GpSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(sheetContext).colorScheme.outline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Icon(
                    Icons.edit_note_rounded,
                    color: Theme.of(sheetContext).colorScheme.primary,
                    size: 28,
                  ),
                  const SizedBox(width: 10),
                  Text(l.perfilEdit, style: Theme.of(sheetContext).textTheme.titleLarge),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _nombreController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: l.perfilPersonaName,
                  prefixIcon: const Icon(Icons.person_outline_rounded),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _paternoController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: l.perfilPersonaPaternal,
                  prefixIcon: const Icon(Icons.badge_outlined),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _maternoController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: l.perfilPersonaMaternal,
                  prefixIcon: const Icon(Icons.badge_outlined),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                icon: const Icon(Icons.check_rounded),
                onPressed: () => Navigator.of(sheetContext).pop(true),
                label: Text(l.commonSave),
              ),
            ],
          ),
        ),
      ),
    );

    if (guardar != true || !mounted) {
      return;
    }
    setState(() => _guardando = true);
    try {
      await ref.read(personaRepositoryProvider).crearPersona(
            Persona(
              nombre: _nombreController.text.trim(),
              apellidoP: _paternoController.text.trim(),
              apellidoMaterno: _maternoController.text.trim(),
            ),
          );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.perfilSaveSuccess),
          backgroundColor: GpColors.verde,
        ),
      );
    } on AppException catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(messageDeError(context, e))),
      );
    } finally {
      if (mounted) {
        setState(() => _guardando = false);
      }
    }
  }

  Future<void> _confirmarLogout(AppLocalizations l) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l.perfilLogoutConfirm),
        content: Text(l.perfilLogoutConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l.commonCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l.perfilLogout),
          ),
        ],
      ),
    );
    if (confirmado == true && mounted) {
      await ref.read(sessionControllerProvider.notifier).logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final sesion = ref.watch(sessionControllerProvider);
    final themeMode = ref.watch(themeModeProvider);

    final nombreSesion = sesion.session?.nombre;
    final nombre = (nombreSesion != null && nombreSesion.trim().isNotEmpty)
        ? nombreSesion
        : '';
    final email = sesion.session?.email ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(l.perfilTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(GpSpacing.page, 8, GpSpacing.page, 32),
        children: [
          // Tarjeta de perfil Hero
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  scheme.primary.withValues(alpha: 0.15),
                  scheme.surface,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(GpRadii.tarjeta),
              border: Border.all(color: scheme.outline),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor: scheme.primary.withValues(alpha: 0.2),
                  child: Text(
                    _iniciales(nombre),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: scheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nombre.isEmpty ? l.perfilName : nombre,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        email.isNotEmpty ? email : 'usuario@gestopago.com',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: GpColors.verde.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.verified_rounded, size: 14, color: GpColors.verde),
                            const SizedBox(width: 4),
                            Text(
                              'Cuenta Verificada',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: GpColors.verde,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Seccion: Informacion de cuenta
          _TarjetaSeccion(
            title: 'Información de Cuenta',
            children: [
              _FilaIcono(
                icon: Icons.person_outline_rounded,
                texto: l.perfilEdit,
                subtitulo: 'Modificar nombre y datos personales',
                onTap: _guardando ? null : () => _editarDatosPersonales(l, nombre),
              ),
              const Divider(height: 1),
              _FilaIcono(
                icon: Icons.email_outlined,
                texto: 'Correo Electrónico',
                subtitulo: email.isNotEmpty ? email : 'No registrado',
                mostrarChevron: false,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Seccion: Preferencias de tema
          _TarjetaSeccion(
            title: l.perfilTheme,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Elige la apariencia visual de la app',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<ThemeMode>(
                      segments: [
                        ButtonSegment(
                          value: ThemeMode.system,
                          icon: const Icon(Icons.brightness_auto_outlined),
                          label: Text(l.perfilThemeSystem),
                        ),
                        ButtonSegment(
                          value: ThemeMode.light,
                          icon: const Icon(Icons.light_mode_outlined),
                          label: Text(l.perfilThemeLight),
                        ),
                        ButtonSegment(
                          value: ThemeMode.dark,
                          icon: const Icon(Icons.dark_mode_outlined),
                          label: Text(l.perfilThemeDark),
                        ),
                      ],
                      selected: {themeMode},
                      showSelectedIcon: false,
                      onSelectionChanged: (value) =>
                          ref.read(themeModeProvider.notifier).state = value.first,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Seccion: Ayuda y Legal
          _TarjetaSeccion(
            title: 'Soporte y Seguridad',
            children: [
              _FilaIcono(
                icon: Icons.help_outline_rounded,
                texto: 'Centro de Ayuda',
                subtitulo: 'Preguntas frecuentes y soporte técnico',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Soporte: soporte@gestopago.com')),
                  );
                },
              ),
              const Divider(height: 1),
              _FilaIcono(
                icon: Icons.security_rounded,
                texto: 'Seguridad y Privacidad',
                subtitulo: 'Tus pagos están protegidos con cifrado JWT',
                mostrarChevron: false,
              ),
              const Divider(height: 1),
              _FilaIcono(
                icon: Icons.info_outline_rounded,
                texto: 'Versión de la App',
                subtitulo: 'GestoPago v1.0.0 (Build 2026)',
                mostrarChevron: false,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Boton de cerrar sesion
          Pressable(
            onTap: () => _confirmarLogout(l),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: scheme.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(GpRadii.tarjeta),
                border: Border.all(color: scheme.error.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.logout_rounded, color: scheme.error, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    l.perfilLogout,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: scheme.error,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TarjetaSeccion extends StatelessWidget {
  const _TarjetaSeccion({required this.title, required this.children});

  final String? title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(GpRadii.tarjeta),
        border: Border.all(color: scheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 12),
          ],
          ...children,
        ],
      ),
    );
  }
}

class _FilaIcono extends StatelessWidget {
  const _FilaIcono({
    required this.icon,
    required this.texto,
    this.subtitulo,
    this.onTap,
    this.mostrarChevron = true,
  });

  final IconData icon;
  final String texto;
  final String? subtitulo;
  final VoidCallback? onTap;
  final bool mostrarChevron;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final target = scheme.onSurface;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: scheme.primary, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    texto,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: target,
                    ),
                  ),
                  if (subtitulo != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitulo!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (mostrarChevron && onTap != null)
              Icon(
                Icons.chevron_right_rounded,
                color: scheme.onSurfaceVariant,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}