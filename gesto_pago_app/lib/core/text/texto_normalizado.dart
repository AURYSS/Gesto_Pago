/// Normalizacion de texto para busquedas y para resolver logos.
///
/// Antes cada consumidor traia su propio par de cadenas paralelas
/// (`desde`/`hacia`) para quitar acentos. Los dos tenian un caracter de
/// diferencia: el mapa se corria a partir del indice 17, asi que "ñ" se
/// convertia en "c", "û" en "n", "õ" en "u" y "ç" se quedaba sin quitar. En
/// `GpAssets` eso rompia el slug de cualquier marca con eñe y hacia que el
/// servicio no encontrara su logo.
///
/// Un mapa por clave hace imposible ese desalineado: si falta una vocal
/// acentuada, simplemente no se quita.
library;

/// Acentos y enye de uso corriente en español, catalogo y nombres de marca.
const _reemplazos = <String, String>{
  'á': 'a', 'à': 'a', 'ä': 'a', 'â': 'a', 'ã': 'a', 'å': 'a',
  'é': 'e', 'è': 'e', 'ë': 'e', 'ê': 'e',
  'í': 'i', 'ì': 'i', 'ï': 'i', 'î': 'i',
  'ó': 'o', 'ò': 'o', 'ö': 'o', 'ô': 'o', 'õ': 'o',
  'ú': 'u', 'ù': 'u', 'ü': 'u', 'û': 'u',
  'ñ': 'n', 'ç': 'c',
  // El provider tambien trae marcas con diéresis y letras eslavas.
  'š': 's', 'ž': 'z', 'č': 'c', 'ř': 'r', 'ě': 'e', 'ů': 'u', 'ň': 'n',
  'ý': 'y', 'ÿ': 'y', 'ß': 'ss', 'æ': 'ae', 'œ': 'oe',
};

/// Rango de marcas diacriticas combinantes (Unicode Combining Diacritical
/// Marks, U+0300..U+036F).
///
/// Los teclados de Android e iOS no siempre envían "í" como un solo caracter:
/// escriben "i" seguido del acento combinante U+0301. Si solo se reemplazan
/// los acentos precompuestos, esa forma se escapa de la busqueda.
const _inicioCombinantes = 0x0300;
const _finCombinantes = 0x036F;

/// Minúsculas, sin acentos y con espacios colapsados.
///
/// "  Televía  " y "televia" dan el mismo resultado, en cualquiera de las dos
/// formas Unicode en que el usuario haya escrito el acento.
String normalizarTexto(String texto) {
  final salida = StringBuffer();
  for (final rune in texto.toLowerCase().runes) {
    if (rune >= _inicioCombinantes && rune <= _finCombinantes) {
      continue;
    }
    final caracter = String.fromCharCode(rune);
    salida.write(_reemplazos[caracter] ?? caracter);
  }
  return salida.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
}

/// [normalizarTexto] más guiones bajos donde había separadores.
///
/// Es la forma que usan las claves de `GpAssets.marcas`: "AT-T" y "AT&T"
/// deben resolver al mismo slug `att`.
String slugify(String texto) {
  return normalizarTexto(texto).replaceAll(RegExp(r'[^a-z0-9]+'), '_').replaceAll(RegExp(r'^_+|_+$'), '');
}
