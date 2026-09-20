import 'package:flutter/material.dart';

import 'gp_colors.dart';

/// Radios, espaciados y formas consistentes de la aplicación.
abstract final class GpRadii {
  static const double cuadroBoton = 14;
  static const double campo = 14;
  static const double tarjeta = 18;
  static const double dialogo = 24;
  static const double pastilla = 99;
}

abstract final class GpSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double page = 16;
}

/// Definiciones de estilo centralizadas (light y dark). Las pantallas
/// consumen el tema y evitan estilos ad-hoc.
abstract final class GpTheme {
  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final oscuro = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: GpColors.seed,
      brightness: brightness,
      primary: oscuro ? GpColors.verdeClaro : GpColors.verde,
      onPrimary: oscuro ? GpColors.esmeraldaOscuro : GpColors.sobreVerde,
    ).copyWith(
      surface: oscuro ? GpColors.superficieOscura : GpColors.superficieClara,
      onSurface: oscuro ? GpColors.textoOscuro : GpColors.textoClaro,
      error: oscuro ? GpColors.errorOscuro : GpColors.error,
      outline: oscuro ? GpColors.bordeOscuro : GpColors.bordeClaro,
      surfaceContainerHighest:
          oscuro ? GpColors.bordeOscuro.withValues(alpha: 0.4) : const Color(0xFFEDF1EE),
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: oscuro ? GpColors.fondoOscuro : GpColors.fondoClaro,
    );

    final schemeGe = base.colorScheme;
    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: oscuro ? GpColors.fondoOscuro : GpColors.fondoClaro,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
          color: schemeGe.onSurface,
        ),
        iconTheme: IconThemeData(color: schemeGe.onSurface),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: schemeGe.surface,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GpRadii.tarjeta),
          side: BorderSide(color: schemeGe.outline, width: 1),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          backgroundColor: schemeGe.primary,
          foregroundColor: schemeGe.onPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(GpRadii.cuadroBoton)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          foregroundColor: schemeGe.primary,
          side: BorderSide(color: schemeGe.primary),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(GpRadii.cuadroBoton)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: schemeGe.primary,
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: schemeGe.surfaceContainerHighest,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: TextStyle(color: schemeGe.onSurfaceVariant, fontSize: 14),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        hintStyle: TextStyle(color: schemeGe.outline, fontSize: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(GpRadii.campo),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(GpRadii.campo),
          borderSide: BorderSide(color: schemeGe.outline, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(GpRadii.campo),
          borderSide: BorderSide(color: schemeGe.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(GpRadii.campo),
          borderSide: BorderSide(color: schemeGe.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(GpRadii.campo),
          borderSide: BorderSide(color: schemeGe.error, width: 2),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(GpRadii.pastilla)),
        side: BorderSide(color: schemeGe.outline),
        labelStyle: TextStyle(color: schemeGe.onSurface, fontWeight: FontWeight.w500),
        selectedColor: schemeGe.primary,
        secondarySelectedColor: schemeGe.primary,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        backgroundColor: oscuro ? GpColors.superficieOscura : GpColors.superficieClara,
        indicatorColor: schemeGe.primary.withValues(alpha: 0.16),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? schemeGe.primary
                : schemeGe.onSurfaceVariant,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? schemeGe.primary
                : schemeGe.onSurfaceVariant,
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: schemeGe.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(GpRadii.dialogo)),
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: schemeGe.onSurface,
        ),
        contentTextStyle: TextStyle(fontSize: 15, color: schemeGe.onSurfaceVariant),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: oscuro ? GpColors.textoOscuro : GpColors.textoClaro,
        contentTextStyle: TextStyle(
          color: oscuro ? GpColors.textoClaro : GpColors.textoOscuro,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(GpRadii.campo)),
      ),
      dividerTheme: DividerThemeData(color: schemeGe.outline, thickness: 1, space: 1),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: schemeGe.primary,
        linearTrackColor: schemeGe.surfaceContainerHighest,
      ),
      textTheme: base.textTheme.copyWith(
        displaySmall: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
          color: schemeGe.onSurface,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
          color: schemeGe.onSurface,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: schemeGe.onSurface,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: schemeGe.onSurface,
        ),
        bodyLarge: TextStyle(fontSize: 16, color: schemeGe.onSurface),
        bodyMedium: TextStyle(fontSize: 14, color: schemeGe.onSurface),
        bodySmall: TextStyle(
          fontSize: 13,
          color: schemeGe.onSurfaceVariant,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: schemeGe.onSurface,
        ),
      ),
    );
  }
}