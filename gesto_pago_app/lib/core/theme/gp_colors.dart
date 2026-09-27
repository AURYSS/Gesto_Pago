import 'package:flutter/material.dart';

/// Paleta de marca de Gesto Pago. Un solo lugar para los colores,
/// evitando valores hardcodeados en las pantallas.
///
/// La escala oscura usa grises profundos neutros en lugar de negro puro:
/// el fondo (#141414) queda un escalon por debajo de la superficie
/// (#1E1E1E) para que las tarjetas se lean por profundidad y no solo por
/// borde, y el texto principal se apoya en #F2F2F2.
abstract final class GpColors {
  static const Color seed = Color(0xFF0E9F6E);

  // Verde de marca.
  static const Color verde = Color(0xFF0E9F6E);
  static const Color sobreVerde = Colors.white;

  /// Verde menta vibrante para las acciones en modo oscuro: botones de
  /// pagar, confirmar y cualquier CTA.
  static const Color menta = Color(0xFF3DDC97);

  /// Texto e iconos sobre [menta]. Verde casi negro: el menta es claro, asi
  /// que un verde medio daba 3.7:1 y fallaba WCAG AA. Este da 8.4:1.
  static const Color sobreMenta = Color(0xFF052E21);

  static const Color verdeClaro = Color(0xFF34D399);
  static const Color esmeraldaOscuro = Color(0xFF0A6B4B);

  // Neutros claros.
  static const Color fondoClaro = Color(0xFFF6F8F7);
  static const Color superficieClara = Colors.white;
  static const Color bordeClaro = Color(0xFFE3E8E5);
  static const Color textoClaro = Color(0xFF16211D);
  static const Color textoSuaveClaro = Color(0xFF5D6B65);

  // Neutros oscuros.
  static const Color fondoOscuro = Color(0xFF141414);
  static const Color superficieOscura = Color(0xFF1E1E1E);

  /// Un escalon por encima de [superficieOscura] para campos, chips y
  /// elementos que flotan sobre una tarjeta.
  static const Color superficieElevadaOscura = Color(0xFF262626);

  static const Color bordeOscuro = Color(0xFF2F2F2F);
  static const Color textoOscuro = Color(0xFFF2F2F2);

  /// Gris claro para subtitulos y metadatos. 6.2:1 sobre [superficieOscura].
  static const Color textoSuaveOscuro = Color(0xFF9E9E9E);

  /// Tracks de scroll y rellenos sutiles, para no competir con el texto.
  static const Color veloOscuro = Color(0xFF171717);

  // Estados.
  static const Color exito = Color(0xFF12935A);
  static const Color exitoClaro = Color(0xFFE6F6EE);
  static const Color exitoOscuro = Color(0xFF3EDB87);
  static const Color error = Color(0xFFD64545);
  static const Color errorClaro = Color(0xFFFDECEA);
  static const Color errorOscuro = Color(0xFFFF8A80);
  static const Color proceso = Color(0xFFED8936);
  static const Color procesoClaro = Color(0xFFFFF3E4);
  static const Color procesoOscuro = Color(0xFFFFB75E);
  static const Color neutro = Color(0xFF6B7A74);

  // Acento.
  static const Color acentoAmarillo = Color(0xFFFFC24D);
}
