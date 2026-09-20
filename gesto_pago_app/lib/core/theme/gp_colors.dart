import 'package:flutter/material.dart';

/// Paleta de marca de Gesto Pago. Un solo lugar para los colores,
/// evitando valores hardcodeados en las pantallas.
abstract final class GpColors {
  static const Color seed = Color(0xFF0E9F6E);

  // Verde de marca.
  static const Color verde = Color(0xFF0E9F6E);
  static const Color sobreVerde = Colors.white;
  static const Color verdeClaro = Color(0xFF34D399);
  static const Color esmeraldaOscuro = Color(0xFF0A6B4B);

  // Neutros claros.
  static const Color fondoClaro = Color(0xFFF6F8F7);
  static const Color superficieClara = Colors.white;
  static const Color bordeClaro = Color(0xFFE3E8E5);
  static const Color textoClaro = Color(0xFF16211D);
  static const Color textoSuaveClaro = Color(0xFF5D6B65);

  // Neutros oscuros.
  static const Color fondoOscuro = Color(0xFF0E1311);
  static const Color superficieOscura = Color(0xFF161D1A);
  static const Color bordeOscuro = Color(0xFF26302C);
  static const Color textoOscuro = Color(0xFFE5EDE9);
  static const Color textoSuaveOscuro = Color(0xFF8FA098);

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