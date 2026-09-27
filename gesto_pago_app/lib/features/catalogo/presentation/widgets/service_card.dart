import 'package:flutter/material.dart';

import '../../../../core/theme/gp_theme.dart';
import '../../../../core/widgets/pressable.dart';
import '../../domain/catalogo_marca.dart';

/// Ficha de una compania/marca en la cuadricula de servicios populares.
///
/// Muestra el logo oficial de la marca sobre una franja con el color de marca
/// y el nombre de la empresa abajo, sin mostrar precio, sirviendo como punto
/// de entrada a todos los productos de esa compania.
class ServiceCard extends StatelessWidget {
  const ServiceCard({
    super.key,
    required this.marca,
    this.precioDesde,
    required this.onTap,
  });

  /// Marca completa con sus datos desde la BD.
  final CatalogoMarca marca;

  /// Precio opcional (si se llega a requerir en otros contextos).
  final String? precioDesde;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final colorMarca = marca.color;
    final nombre = marca.nombre;
    final logo = marca.logoAsset;
    final banda = colorMarca?.withValues(alpha: 0.18) ??
        scheme.surfaceContainerHighest;
    final tintaMonograma = colorMarca == null
        ? scheme.onSurface
        : _contraste(theme, colorMarca);

    return Pressable(
      onTap: onTap,
      semanticsLabel: nombre,
      escalaPulsado: 0.97,
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(GpRadii.tarjeta),
          border: Border.all(color: scheme.outline),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Franja con el logo de la marca.
            Expanded(
              child: Container(
                width: double.infinity,
                color: banda,
                padding: const EdgeInsets.all(GpSpacing.md),
                child: Center(
                  child: (logo == null || logo.isEmpty)
                      ? _Monograma(texto: _iniciales(nombre), color: tintaMonograma)
                      : Image.asset(
                          logo,
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => _Monograma(
                            texto: _iniciales(nombre),
                            color: tintaMonograma,
                          ),
                        ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: GpSpacing.md,
                vertical: 12,
              ),
              child: Text(
                nombre,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Iniciales de una marca, para cuando el catalogo no trae logo.
class _Monograma extends StatelessWidget {
  const _Monograma({required this.texto, required this.color});

  final String texto;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(GpRadii.pastilla),
      ),
      child: Text(
        texto,
        style: theme.textTheme.titleMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

/// Primeras letras legibles de un nombre de marca.
String _iniciales(String nombre) {
  final palabras = nombre
      .split(RegExp(r'[\s\-_/]+'))
      .where((p) => p.trim().isNotEmpty)
      .toList();
  final letras = palabras
      .map((p) => p.replaceAll(RegExp(r'[^A-Za-zÁÉÍÓÚÑáéíóúñ]'), ''))
      .where((p) => p.isNotEmpty)
      .toList();
  if (letras.isEmpty) return '?';
  if (letras.length == 1) {
    final una = letras.first;
    return una.substring(0, una.length >= 2 ? 2 : 1).toUpperCase();
  }
  return '${letras[0][0]}${letras[1][0]}'.toUpperCase();
}

Color _contraste(ThemeData theme, Color colorMarca) {
  return colorMarca.computeLuminance() > 0.45
      ? colorMarca
      : theme.colorScheme.onSurface;
}
