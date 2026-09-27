import 'package:flutter/material.dart';

import '../../../../../core/theme/gp_theme.dart';
import '../../../../../core/widgets/brand_mark.dart';
import '../../../../../core/widgets/money_text.dart';
import '../../../../../core/widgets/pressable.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/catalogo_producto.dart';

/// Tarjeta de un producto/servicio del catálogo.
///
/// Muestra el logo real de la marca, la jerarquia de texto (producto
/// destacado, servicio y tipo de precio atenuados) y una accion explicita
/// de pago.
class ServicioCard extends StatelessWidget {
  const ServicioCard({
    super.key,
    required this.producto,
    this.logoAsset,
    required this.onTap,
  });

  final CatalogoProducto producto;
  final String? logoAsset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(GpRadii.tarjeta),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(GpRadii.tarjeta),
        child: Ink(
          padding: const EdgeInsets.all(GpSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(GpRadii.tarjeta),
            border: Border.all(color: scheme.outline),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BrandMark(
                asset: logoAsset,
                categoria: producto.idCatTipoServicio,
                tamano: 48,
              ),
              const SizedBox(width: GpSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Jerarquia 1: que es lo que el usuario busca.
                    Text(
                      producto.producto,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    // Jerarquia 2: la empresa, atenuada.
                    Text(
                      producto.servicio,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: GpSpacing.sm),
                    // Jerarquia 3: el importe manda sobre la etiqueta.
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        MoneyText(
                          monto: producto.precio,
                          style: Theme.of(context).textTheme.titleMedium,
                          negritas: true,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            producto.esPrecioFinal ? l.catalogPrice : l.catalogCommission,
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: GpSpacing.md),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _AccionPagar(onTap: onTap),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Accion explicita de pago.
class _AccionPagar extends StatelessWidget {
  const _AccionPagar({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Pressable(
      onTap: onTap,
      semanticsLabel: l.cardPayAction,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
        decoration: BoxDecoration(
          color: scheme.primary,
          borderRadius: BorderRadius.circular(99),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bolt_rounded, size: 16, color: scheme.onPrimary),
            const SizedBox(width: 6),
            Text(
              l.cardPayAction,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: scheme.onPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
