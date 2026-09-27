import 'package:flutter/material.dart';

/// Tokens de movimiento de la aplicación.
///
/// Centraliza duraciones y curvas para que las microinteracciones se
/// sientan coherentes en toda la app. Valores cortos y discretos: la app
/// debe responder al instante, nunca hacer esperar al usuario.
abstract final class GpMotion {
  /// Presión de un elemento (cards, botones, list tiles).
  static const Duration rapida = Duration(milliseconds: 120);

  /// Cambio de estado visible (chips, toggles, iconos).
  static const Duration media = Duration(milliseconds: 220);

  /// Entrada de una pantalla o tarjeta grande.
  static const Duration lenta = Duration(milliseconds: 380);

  /// Retardo entre elementos de una lista escalonada.
  static const Duration escalonado = Duration(milliseconds: 45);

  /// Curva estándar de entrada: arranca rápido y asienta con suavidad.
  static const Curve entrada = Curves.easeOutCubic;

  /// Curva estándar de salida: se retira sin rebote.
  static const Curve salida = Curves.easeInCubic;

  /// Curva elástica para checks y confirmaciones.
  static const Curve elastic = Curves.easeOutBack;

  /// Transición estándar entre pantallas de la app.
  static const Curve navegacion = Curves.easeOutQuart;
}
