import 'package:flutter/material.dart';

import '../../../../../core/theme/gp_colors.dart';
import '../../../../../core/theme/gp_theme.dart';
import '../../../../../core/widgets/money_text.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/catalogo_producto.dart';

/// Tarjeta de un producto/servicio del catálogo.
class ServicioCard extends StatelessWidget {
  const ServicioCard({super.key, required this.producto, required this.onTap});

  final CatalogoProducto producto;
  final VoidCallback onTap;

  IconData get _icono {
    return switch (producto.idCatTipoServicio) {
      CatalogoCategorias.pagoImpuestos => Icons.account_balance_outlined,
      CatalogoCategorias.pagoDerechosAgua => Icons.water_drop_outlined,
      _ => Icons.receipt_outlined,
    };
  }

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
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: GpColors.verde.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(_icono, color: scheme.primary, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      producto.producto,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      producto.servicio,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      producto.esPrecioFinal ? l.catalogPrice : l.catalogCommission,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  MoneyText(
                    monto: producto.precio,
                    style: Theme.of(context).textTheme.titleMedium,
                    negritas: true,
                  ),
                  const SizedBox(height: 4),
                  Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}