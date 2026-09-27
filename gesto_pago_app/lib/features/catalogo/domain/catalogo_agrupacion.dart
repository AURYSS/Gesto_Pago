import '../../../core/text/texto_normalizado.dart';
import 'catalogo_marca.dart';
import 'catalogo_producto.dart';

/// Resumen de una marca dentro del catalogo.
///
/// La cuadricula de "Servicios populares" no muestra productos sueltos sino
/// marcas: "Telcel Datos", "Telcel Paquetes Amigo" y "Telcel Pospago" son
/// tres servicios del catalogo que el usuario percibe como uno. Esta clase
/// es el resultado de esa agrupacion.
class MarcaResumen {
  const MarcaResumen({
    required this.slug,
    required this.nombre,
    required this.cantidadProductos,
    required this.precioDesde,
    required this.idServicio,
    required this.idProducto,
    this.marca,
  });

  /// Slug de la marca.
  final String slug;

  /// Nombre legible de la marca.
  final String nombre;

  /// Cuantos productos del catalogo pertenecen a la marca.
  final int cantidadProductos;

  /// Precio del producto mas barato, en texto.
  final String precioDesde;

  /// Producto mas barato, para abrir la pantalla de pago directamente.
  final int idServicio;
  final int idProducto;

  /// Datos completos de la marca desde BD (color, logoAsset, destacada).
  final CatalogoMarca? marca;
}

/// Agrupa el catalogo por marca y devuelve las mas relevantes.
///
/// Las marcas marcadas como destacadas en la BD van primero y en su orden; el
/// resto se ordena por cantidad de productos descendente, de modo que las
/// marcas con mas cobertura llenan las plazas libres.
///
/// Dentro de cada marca se toma el producto mas barato como punto de entrada.
///
/// Solo entran marcas con registro en el catalogo de marcas del backend.
///
/// Si [categoriaSlug] no es `null`, el resumen se limita a esa categoria
/// funcional.
List<MarcaResumen> resumenMarcas(
  List<CatalogoProducto> productos,
  CatalogoMarcas catalogoMarcas, {
  String? categoriaSlug,
  int limite = 6,
}) {
  final acumulado = <String, _Acumulador>{};

  for (final producto in productos) {
    final slug = catalogoMarcas.slugDe(producto.servicio);
    if (slug == null) {
      continue;
    }
    final marca = catalogoMarcas.porSlug(slug);
    if (marca == null) {
      continue;
    }
    if (categoriaSlug != null && marca.categoria != categoriaSlug) {
      continue;
    }
    final precio = double.tryParse(producto.precio) ?? double.infinity;
    final actual = acumulado[slug];
    if (actual == null) {
      acumulado[slug] = _Acumulador(
        nombre: marca.nombre.isNotEmpty ? marca.nombre : producto.servicio,
        cantidad: 1,
        precioDesde: precio,
        precioTexto: producto.precio,
        idServicio: producto.idServicio,
        idProducto: producto.idProducto,
        marca: marca,
      );
    } else {
      actual.cantidad += 1;
      // Empate en precio: se queda el primer producto, para que el resultado
      // sea estable entre recargas en lugar de depender del orden del JSON.
      if (precio < actual.precioDesde) {
        actual.precioDesde = precio;
        actual.precioTexto = producto.precio;
        actual.idServicio = producto.idServicio;
        actual.idProducto = producto.idProducto;
      }
    }
  }

  final lista = acumulado.entries
      .map((e) => MarcaResumen(
            slug: e.key,
            nombre: e.value.nombre,
            cantidadProductos: e.value.cantidad,
            precioDesde: e.value.precioTexto,
            idServicio: e.value.idServicio,
            idProducto: e.value.idProducto,
            marca: e.value.marca,
          ))
      .toList()
    ..sort((a, b) {
      final porCantidad = b.cantidadProductos.compareTo(a.cantidadProductos);
      return porCantidad != 0 ? porCantidad : a.nombre.compareTo(b.nombre);
    });

  // Las marcas destacadas de BD van primero y en su orden.
  final destacadasBd = catalogoMarcas.destacadas();
  final fijadas = destacadasBd
      .map((destacada) => lista.where((m) => m.slug == destacada.slug))
      .where((m) => m.isNotEmpty)
      .map((m) => m.first)
      .toList();

  for (final marca in fijadas) {
    lista.remove(marca);
  }

  return [...fijadas, ...lista].take(limite).toList();
}

/// Filtra el catalogo por categoria y por texto libre.
///
/// Vive en el dominio porque lo usan dos pantallas: la portada (que busca
/// sobre todo el catalogo) y la pantalla de "Todos los servicios".
///
/// El texto se compara contra el nombre del servicio y del producto, en
/// minusculas y sin acentos.
List<CatalogoProducto> filtrarCatalogo(
  List<CatalogoProducto> productos,
  CatalogoMarcas catalogoMarcas, {
  String busqueda = '',
  String? categoriaSlug,
}) {
  final texto = normalizarTexto(busqueda);
  return productos.where((producto) {
    if (categoriaSlug != null && catalogoMarcas.categoriaDe(producto.servicio) != categoriaSlug) {
      return false;
    }
    if (texto.isEmpty) {
      return true;
    }
    return normalizarTexto(producto.servicio).contains(texto) ||
        normalizarTexto(producto.producto).contains(texto);
  }).toList();
}

/// Cuenta cuantos productos del catalogo caen en cada categoria.
///
/// Se usa para poner el numero en el chip y para descartar del filtro
/// horizontal las categorias vacias.
Map<String, int> conteoPorCategoria(
  List<CatalogoProducto> productos,
  CatalogoMarcas catalogoMarcas,
) {
  final conteo = <String, int>{};
  for (final producto in productos) {
    final categoria = catalogoMarcas.categoriaDe(producto.servicio);
    if (categoria == null || categoria.isEmpty) {
      continue;
    }
    conteo[categoria] = (conteo[categoria] ?? 0) + 1;
  }
  return conteo;
}

/// Acumulador mutable durante el agrupado. Privado de este archivo.
class _Acumulador {
  _Acumulador({
    required this.nombre,
    required this.cantidad,
    required this.precioDesde,
    required this.precioTexto,
    required this.idServicio,
    required this.idProducto,
    required this.marca,
  });

  final String nombre;
  int cantidad;
  double precioDesde;
  String precioTexto;
  int idServicio;
  int idProducto;
  final CatalogoMarca marca;
}
