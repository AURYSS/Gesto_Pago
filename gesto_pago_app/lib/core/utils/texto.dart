/// Convierte un texto a un "slug" normalizado (minúsculas, sin acentos,
/// sin símbolos) para comparar nombres de marcas y servicios del catálogo.
String slugTexto(String nombre) {
  const desde = 'áàäâãéèëêíìïîóòöôõúùüûñçÁÀÄÂÃÉÈËÊÍÌÏÎÓÒÖÔÕÚÙÜÛÑÇ';
  const hacia = 'aaaaaeeeeiiiiooooouuuuncAAAAAEEEEIIIIOOOOOUUUUNC';
  final sb = StringBuffer();
  for (final ch in nombre.split('')) {
    final idx = desde.indexOf(ch);
    sb.write(idx >= 0 ? hacia[idx] : ch);
  }
  return sb
      .toString()
      .toLowerCase()
      .replaceAll('&', '')
      .replaceAll('+', '')
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');
}

/// Quita acentos y signos, conserva espacios. Útil para normalizar la búsqueda.
String normalizarBusqueda(String texto) {
  final base = texto
      .toLowerCase()
      .replaceAll('á', 'a')
      .replaceAll('é', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ú', 'u')
      .replaceAll('ñ', 'n')
      .replaceAll('ü', 'u');
  return base.replaceAll(RegExp(r'[^a-z0-9 ]+'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
}
