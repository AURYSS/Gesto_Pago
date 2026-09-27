import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../providers/app_providers.dart';
import '../theme/gp_motion.dart';
import 'pressable.dart';

/// Interruptor claro/oscuro con animacion.
///
/// Un solo control binario: alterna entre tema oscuro y claro segun el
/// tema activo, sin exponer las tres opciones de [ThemeMode] al usuario.
class ThemeToggle extends ConsumerWidget {
  const ThemeToggle({super.key, this.mostrarEtiqueta = false});

  /// Cuando es true, muestra el texto del modo actual junto al icono.
  final bool mostrarEtiqueta;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final modo = ref.watch(themeModeProvider);
    final oscuro = modo == ThemeMode.dark || modo == ThemeMode.system;
    final esquema = Theme.of(context).colorScheme;

    return Tooltip(
      message: oscuro ? l.themeSwitchToLight : l.themeSwitchToDark,
      child: Pressable(
        onTap: () => ref.read(themeModeProvider.notifier).state =
            oscuro ? ThemeMode.light : ThemeMode.dark,
        escalaPulsado: 0.93,
        semanticsLabel: oscuro ? l.themeSwitchToLight : l.themeSwitchToDark,
        child: AnimatedContainer(
          duration: GpMotion.media,
          curve: GpMotion.entrada,
          padding: EdgeInsets.symmetric(
            horizontal: mostrarEtiqueta ? 14 : 10,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: esquema.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: esquema.outline),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: GpMotion.media,
                transitionBuilder: (child, animation) => RotationTransition(
                  turns: Tween(begin: 0.75, end: 1.0).animate(animation),
                  child: FadeTransition(opacity: animation, child: child),
                ),
                child: Icon(
                  oscuro ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                  key: ValueKey(oscuro),
                  size: 18,
                  color: esquema.onSurface,
                ),
              ),
              if (mostrarEtiqueta) ...[
                const SizedBox(width: 8),
                Text(
                  oscuro ? l.themeDark : l.themeLight,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: esquema.onSurface,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
