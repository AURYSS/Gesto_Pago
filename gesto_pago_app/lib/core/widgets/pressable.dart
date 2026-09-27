import 'package:flutter/material.dart';

import '../theme/gp_motion.dart';

/// Envuelve un widget con una realimentación tactile al presionarlo.
///
/// Aplica una escala ligeramente menor mientras el dedo esta abajo y un
/// leve brillo, de modo que el usuario confirma el toque sin esperar a la
/// navegacion. Pensado para cards, tiles y logos.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.escalaPulsado = 0.97,
    this.habilitado = true,
    this.semanticsLabel,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double escalaPulsado;
  final bool habilitado;
  final String? semanticsLabel;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _pulsado = false;

  void _setPulsado(bool valor) {
    if (_pulsado == valor || !mounted) {
      return;
    }
    setState(() => _pulsado = valor);
  }

  @override
  Widget build(BuildContext context) {
    final activo = widget.habilitado && (widget.onTap != null || widget.onLongPress != null);
    final contenido = AnimatedScale(
      scale: _pulsado ? widget.escalaPulsado : 1.0,
      duration: GpMotion.rapida,
      curve: GpMotion.entrada,
      child: AnimatedOpacity(
        opacity: widget.habilitado ? 1.0 : 0.55,
        duration: GpMotion.rapida,
        child: widget.child,
      ),
    );

    return Semantics(
      button: true,
      enabled: activo,
      label: widget.semanticsLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: activo ? (_) => _setPulsado(true) : null,
        onTapUp: activo ? (_) => _setPulsado(false) : null,
        onTapCancel: activo ? () => _setPulsado(false) : null,
        onTap: activo ? widget.onTap : null,
        onLongPress: activo ? widget.onLongPress : null,
        child: contenido,
      ),
    );
  }
}
