import 'package:flutter/material.dart';

import '../../../../core/theme/gp_colors.dart';
import '../../../../core/theme/gp_theme.dart';
import '../../domain/estado_transaccion.dart';

/// Insignia de color para el estado de una transacción.
class EstadoTransaccionBadge extends StatelessWidget {
  const EstadoTransaccionBadge({
    super.key,
    required this.estado,
    required this.label,
  });

  final EstadoTransaccion estado;
  final String label;

  @override
  Widget build(BuildContext context) {
    final oscuro = Theme.of(context).brightness == Brightness.dark;
    final (Color fondo, Color texto) = switch (estado) {
      EstadoTransaccion.aprobada => (
          oscuro ? GpColors.exitoOscuro.withValues(alpha: 0.2) : GpColors.exitoClaro,
          oscuro ? GpColors.exitoOscuro : GpColors.exito,
        ),
      EstadoTransaccion.fallida => (
          oscuro ? GpColors.errorOscuro.withValues(alpha: 0.18) : GpColors.errorClaro,
          oscuro ? GpColors.errorOscuro : GpColors.error,
        ),
      EstadoTransaccion.enProceso => (
          oscuro ? GpColors.procesoOscuro.withValues(alpha: 0.2) : GpColors.procesoClaro,
          oscuro ? GpColors.procesoOscuro : GpColors.proceso,
        ),
      EstadoTransaccion.pendiente => (
          GpColors.neutro.withValues(alpha: 0.15),
          GpColors.neutro,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(GpRadii.pastilla),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            switch (estado) {
              EstadoTransaccion.aprobada => Icons.check_circle,
              EstadoTransaccion.fallida => Icons.cancel,
              EstadoTransaccion.enProceso => Icons.hourglass_top,
              EstadoTransaccion.pendiente => Icons.schedule,
            },
            size: 14,
            color: texto,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: texto,
            ),
          ),
        ],
      ),
    );
  }
}