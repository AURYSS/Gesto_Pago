import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format/message_de_error.dart';
import '../../../core/network/app_exception.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/gp_colors.dart';
import '../../../core/theme/gp_theme.dart';
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
              Text(l.perfilEdit, style: Theme.of(sheetContext).textTheme.titleLarge),
              const SizedBox(height: 20),
              TextField(
                controller: _nombreController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(labelText: l.perfilPersonaName),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _paternoController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(labelText: l.perfilPersonaPaternal),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _maternoController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(labelText: l.perfilPersonaMaternal),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => Navigator.of(sheetContext).pop(true),
                child: Text(l.commonSave),
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
        SnackBar(content: Text(l.perfilSaveSuccess)),
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
    final sesion = ref.watch(sessionControllerProvider);
    final themeMode = ref.watch(themeModeProvider);

    final nombreSesion = sesion.session?.nombre;
    final nombre = (nombreSesion != null && nombreSesion.trim().isNotEmpty)
        ? nombreSesion
        : '';

    return Scaffold(
      appBar: AppBar(title: Text(l.perfilTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(GpSpacing.page, 8, GpSpacing.page, 24),
        children: [
          const SizedBox(height: 8),
          Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: GpColors.verde.withValues(alpha: 0.16),
                child: Text(
                  _iniciales(nombre),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.primary,
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
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      sesion.session?.email ?? '',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _TarjetaSeccion(
            title: l.perfilEdit,
            children: [
              _FilaIcono(
                icon: Icons.badge_outlined,
                texto: l.perfilEdit,
                onTap: _guardando ? null : () => _editarDatosPersonales(l, nombre),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _TarjetaSeccion(
            title: l.perfilTheme,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: SegmentedButton<ThemeMode>(
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
              ),
            ],
          ),
          const SizedBox(height: 16),
          _TarjetaSeccion(
            title: null,
            children: [
              _FilaIcono(
                icon: Icons.logout,
                texto: l.perfilLogout,
                color: GpColors.error,
                onTap: () => _confirmarLogout(l),
              ),
            ],
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
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: GpSpacing.lg),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(GpRadii.tarjeta),
        border: Border.all(color: scheme.outline),
      ),
      child: Material(
        color: Colors.transparent,
        clipBehavior: Clip.hardEdge,
        borderRadius: BorderRadius.circular(GpRadii.tarjeta),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  title!,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const Divider(),
            ],
            ...children,
          ],
        ),
      ),
    );
  }
}

class _FilaIcono extends StatelessWidget {
  const _FilaIcono({
    required this.icon,
    required this.texto,
    this.onTap,
    this.color,
  });

  final IconData icon;
  final String texto;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final target = color ?? Theme.of(context).colorScheme.onSurfaceVariant;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: target),
      title: Text(texto, style: TextStyle(color: target)),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: onTap,
      enabled: onTap != null,
    );
  }
}