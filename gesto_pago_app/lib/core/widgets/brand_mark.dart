import 'package:flutter/material.dart';

/// Insignia cuadrada con el logo real de la marca sobre una ficha
/// redondeada. Si el asset es null o no esta disponible, muestra el icono
/// de la categoria con fondo neutro.
class BrandMark extends StatelessWidget {
  const BrandMark({
    super.key,
    this.asset,
    this.categoria,
    this.tamano = 48,
    this.radio = 14,
  });

  final String? asset;
  final int? categoria;
  final double tamano;
  final double radio;

  IconData get _icono => switch (categoria) {
        7 => Icons.account_balance_outlined,
        15 => Icons.water_drop_outlined,
        _ => Icons.receipt_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final oscuro = Theme.of(context).brightness == Brightness.dark;

    final contenido = (asset != null && asset!.isNotEmpty)
        ? Image.asset(
            asset!,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => Icon(_icono, color: scheme.onSurfaceVariant, size: tamano * 0.45),
          )
        : Icon(_icono, color: scheme.onSurfaceVariant, size: tamano * 0.45);

    return Container(
      width: tamano,
      height: tamano,
      padding: EdgeInsets.all(tamano * 0.12),
      decoration: BoxDecoration(
        // Las marcas se muestran sobre ficha blanca en ambos temas para
        // no alterar los colores originales de los logotipos.
        color: oscuro ? Colors.white.withValues(alpha: 0.92) : Colors.white,
        borderRadius: BorderRadius.circular(radio),
        border: Border.all(
          color: scheme.outline.withValues(alpha: 0.6),
          width: 1,
        ),
      ),
      child: Center(child: contenido),
    );
  }
}
