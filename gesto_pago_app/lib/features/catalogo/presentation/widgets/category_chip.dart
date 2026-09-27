import 'package:flutter/material.dart';

import '../../../../core/theme/gp_motion.dart';
import '../../../../core/theme/gp_theme.dart';
import '../../../../core/widgets/pressable.dart';
import '../../../../l10n/app_localizations.dart';

/// Chip de categoria del catalogo, para el scroll horizontal.
///
/// Es un chip propio y no un `ChoiceChip` de Material porque aqui se necesita
/// un icono a la izquierda, un estado seleccionado con fondo menta y texto
/// sobre menta, y una pastilla con el conteo de productos. Los colores salen
/// de los tokens de [GpTheme], no de los defaults del tema.
class CategoryChip extends StatelessWidget {
  const CategoryChip({
    super.key,
    required this.categoriaSlug,
    this.categoriaNombre,
    required this.seleccionada,
    required this.onTap,
    this.etiqueta,
    this.cantidad,
  });

  /// `null` representa "Todos".
  final String? categoriaSlug;

  /// Nombre desde BD para fallback cuando el slug no tiene clave l10n.
  final String? categoriaNombre;

  final bool seleccionada;
  final VoidCallback onTap;
  final String? etiqueta;

  /// Numero de productos de la categoria. Se muestra en el chip para que el
  /// usuario sepa cuanto hay detras antes de entrar.
  final int? cantidad;

  IconData get _icono => switch (categoriaSlug) {
        'tiempo_aire' => Icons.sim_card_outlined,
        'internet' => Icons.wifi_rounded,
        'television' => Icons.tv_outlined,
        'entretenimiento' => Icons.play_circle_outline_rounded,
        'servicios' => Icons.receipt_long_outlined,
        'transporte' => Icons.directions_bus_outlined,
        null => Icons.grid_view_rounded,
        _ => Icons.category_outlined,
      };

  String _texto(AppLocalizations l) {
    if (etiqueta != null) {
      return etiqueta!;
    }
    return switch (categoriaSlug) {
      'tiempo_aire' => l.catTiempoAire,
      'internet' => l.catInternet,
      'television' => l.catTelevision,
      'entretenimiento' => l.catEntretenimiento,
      'servicios' => l.catServicios,
      'transporte' => l.catTransporte,
      null => l.catalogAll,
      _ => categoriaNombre ?? categoriaSlug ?? l.catalogAll,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final texto = _texto(AppLocalizations.of(context));

    final fondo = seleccionada ? scheme.primary : scheme.surface;
    final colorTexto = seleccionada ? scheme.onPrimary : scheme.onSurface;
    final colorIcono =
        seleccionada ? scheme.onPrimary : scheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.only(right: GpSpacing.sm),
      child: Pressable(
        onTap: onTap,
        semanticsLabel: texto,
        escalaPulsado: 0.94,
        child: AnimatedContainer(
          duration: GpMotion.rapida,
          curve: GpMotion.entrada,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: fondo,
            borderRadius: BorderRadius.circular(GpRadii.pastilla),
            border: Border.all(
              color: seleccionada ? Colors.transparent : scheme.outline,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_icono, size: 16, color: colorIcono),
              const SizedBox(width: 6),
              Text(
                texto,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colorTexto,
                  fontWeight: seleccionada ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              if (cantidad != null && cantidad! > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: seleccionada
                        ? scheme.onPrimary.withValues(alpha: 0.18)
                        : scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(GpRadii.pastilla),
                  ),
                  child: Text(
                    '$cantidad',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: seleccionada ? scheme.onPrimary : scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
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

/// Fila de categorias con desplazamiento horizontal.
class CategoryChipRow extends StatelessWidget {
  const CategoryChipRow({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: GpSpacing.page),
        physics: const BouncingScrollPhysics(),
        children: children,
      ),
    );
  }
}
