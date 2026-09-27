import 'package:flutter/material.dart';

import '../../../core/text/texto_normalizado.dart';

/// Marca del catalogo con su categoria, color oficial y logo.
class CatalogoMarca {
  const CatalogoMarca({
    required this.slug,
    required this.nombre,
    required this.categoria,
    this.colorHex,
    this.logoAsset,
    this.destacada = false,
    this.orden = 0,
  });

  final String slug;
  final String nombre;
  final String categoria;
  final String? colorHex;
  final String? logoAsset;
  final bool destacada;
  final int orden;

  /// Color oficial de la marca a partir del hex `#RRGGBB` de la BD.
  /// Devuelve `null` si no tiene color asignado.
  Color? get color {
    if (colorHex == null || colorHex!.isEmpty) {
      return null;
    }
    try {
      final hex = colorHex!.replaceAll('#', '');
      if (hex.length == 6) {
        return Color(int.parse('0xFF$hex'));
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  factory CatalogoMarca.fromJson(Map<String, dynamic> json) {
    return CatalogoMarca(
      slug: json['slug'] as String? ?? '',
      nombre: json['nombre'] as String? ?? '',
      categoria: json['categoria'] as String? ?? '',
      colorHex: json['colorHex'] as String?,
      logoAsset: json['logoAsset'] as String?,
      destacada: json['destacada'] as bool? ?? false,
      orden: (json['orden'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'slug': slug,
        'nombre': nombre,
        'categoria': categoria,
        'colorHex': colorHex,
        'logoAsset': logoAsset,
        'destacada': destacada,
        'orden': orden,
      };

  @override
  String toString() => 'CatalogoMarca(slug: $slug, nombre: $nombre, categoria: $categoria)';
}

/// Categoria funcional de una marca (tiempo aire, internet, etc.).
class CatalogoCategoria {
  const CatalogoCategoria({
    required this.slug,
    required this.nombre,
    required this.orden,
  });

  final String slug;
  final String nombre;
  final int orden;

  factory CatalogoCategoria.fromJson(Map<String, dynamic> json) {
    return CatalogoCategoria(
      slug: json['slug'] as String? ?? '',
      nombre: json['nombre'] as String? ?? '',
      orden: (json['orden'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'slug': slug,
        'nombre': nombre,
        'orden': orden,
      };

  @override
  String toString() => 'CatalogoCategoria(slug: $slug, nombre: $nombre, orden: $orden)';
}

/// Agregado de dominio que concentra categorias y marcas del backend.
class CatalogoMarcas {
  CatalogoMarcas({
    required this.categorias,
    required this.marcas,
  }) : _porSlug = {
          for (final marca in marcas) marca.slug: marca,
        };

  final List<CatalogoCategoria> categorias;
  final List<CatalogoMarca> marcas;
  final Map<String, CatalogoMarca> _porSlug;

  factory CatalogoMarcas.fromJson(Map<String, dynamic> json) {
    final catsRaw = json['categorias'] as List<dynamic>? ?? const [];
    final marcasRaw = json['marcas'] as List<dynamic>? ?? const [];
    return CatalogoMarcas(
      categorias: catsRaw
          .whereType<Map<String, dynamic>>()
          .map(CatalogoCategoria.fromJson)
          .toList(),
      marcas: marcasRaw
          .whereType<Map<String, dynamic>>()
          .map(CatalogoMarca.fromJson)
          .toList(),
    );
  }

  /// Busca una marca por su slug exacto.
  CatalogoMarca? porSlug(String? slug) {
    if (slug == null) return null;
    return _porSlug[slug];
  }

  /// Resuelve el slug de una marca a partir de su nombre completo en el catalogo.
  ///
  /// El catalogo real trae el nombre de la marca con sufijos y afijos
  /// ("Telcel Datos", "Telcel Paquetes Amigo", "AT-T Pospago"), asi que la
  /// busqueda prueba de mayor a menor certeza y se queda con la
  /// coincidencia mas larga:
  ///
  /// 1. coincidencia exacta del slug;
  /// 2. los tokens del nombre se unen de forma contigua y el resultado
  ///    coincide con un logo, completo o como prefijo. Asi "telcel datos"
  ///    resuelve `telcel` y "AT-T Pospago" resuelve `att` (tokens "at"+"t");
  /// 3. el texto sin separadores coincide exactamente con el logo.
  ///
  /// Containment sin limites queda descartado a proposito: hacia que "sky"
  /// dejaba de resolver "Kaspersky" y le ponia el logo de television a un
  /// antivirus. Solo se aceptan uniones de tokens contiguos, y por eso
  /// "Kaspersky" no puede formar "sky".
  ///
  /// Devuelve `null` cuando no hay coincidencia con una marca registrada.
  String? slugDe(String nombreServicio) {
    final slug = normalizarSlug(nombreServicio);
    if (slug.isEmpty) {
      return null;
    }
    if (_porSlug.containsKey(slug)) {
      return slug;
    }

    final palabras = slug.split('_').where((p) => p.isNotEmpty).toList();
    final base = slug.replaceAll('_', '');

    // Uniones contiguas de 1..3 tokens: "at"+"t" -> "att", "google"+"play".
    final uniones = <String>{};
    for (var i = 0; i < palabras.length; i++) {
      var buffer = '';
      for (var largo = 1; largo <= 3 && i + largo <= palabras.length; largo++) {
        buffer = '$buffer${palabras[i + largo - 1]}';
        uniones.add(buffer);
      }
    }

    String? mejor;
    var mejorLongitud = 0;
    for (final marca in marcas) {
      final clave = marca.slug.replaceAll('_', '');
      if (clave.length < 3 || marca.slug.length <= mejorLongitud) {
        continue;
      }
      // Igualdad siempre; prefijo solo con claves de 4 letras o mas. Sin ese
      // piso, una clave corta como `sat` se colgaria de cualquier servicio
      // que empezara por "sat..." cuando el proveedor agregue productos.
      final porPrefijo = clave.length >= 4 && uniones.any((u) => u.startsWith(clave));
      final porIgualdad = uniones.contains(clave);
      if (porPrefijo || porIgualdad || base == clave) {
        mejor = marca.slug;
        mejorLongitud = marca.slug.length;
      }
    }
    return mejor;
  }

  /// Categoria funcional de un servicio por su nombre.
  String? categoriaDe(String nombreServicio) {
    final slug = slugDe(nombreServicio);
    return porSlug(slug)?.categoria;
  }

  /// Color oficial de la marca a partir del nombre del servicio.
  Color? colorDe(String nombreServicio) {
    final slug = slugDe(nombreServicio);
    return porSlug(slug)?.color;
  }

  /// Nombre legible de la marca a partir del nombre del servicio.
  String? nombreDe(String nombreServicio) {
    final slug = slugDe(nombreServicio);
    return porSlug(slug)?.nombre ?? nombreServicio;
  }

  /// Ruta del logo asset de la marca a partir del nombre del servicio.
  String? logoDe(String nombreServicio) {
    final slug = slugDe(nombreServicio);
    return porSlug(slug)?.logoAsset;
  }

  /// Marcas pertenecientes a una categoria.
  List<CatalogoMarca> marcasDe(String categoriaSlug) {
    return marcas
        .where((m) => m.categoria == categoriaSlug)
        .toList()
      ..sort((a, b) {
        final cmp = a.orden.compareTo(b.orden);
        return cmp != 0 ? cmp : a.nombre.compareTo(b.nombre);
      });
  }

  /// Marcas marcadas como destacadas para la portada, en su orden.
  List<CatalogoMarca> destacadas() {
    return marcas
        .where((m) => m.destacada)
        .toList()
      ..sort((a, b) => a.orden.compareTo(b.orden));
  }

  /// Normaliza una cadena a slug eliminando acentos y caracteres especiales.
  static String normalizarSlug(String texto) => slugify(texto);
}
