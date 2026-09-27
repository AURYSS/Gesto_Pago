import 'package:flutter/material.dart';

/// Campo de busqueda del catalogo.
///
/// Se llama `GpSearchBar` y no `SearchBar` a proposito: Material ya define
/// un widget `SearchBar` y nombrarlo igual lo haria colisionar en cualquier
/// archivo que importe `package:flutter/material.dart`.
///
/// A diferencia del `TextField` crudo, este componente ya trae la forma, el
/// relleno y el comportamiento de limpiar alineados con el resto del tema.
class GpSearchBar extends StatelessWidget {
  const GpSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    this.hintText,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String? hintText;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final tieneTexto = value.text.isNotEmpty;
        return TextField(
          controller: controller,
          onChanged: onChanged,
          autofocus: autofocus,
          textInputAction: TextInputAction.search,
          style: Theme.of(context).textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: hintText,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: scheme.onSurfaceVariant,
              size: 22,
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            suffixIcon: tieneTexto
                ? IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
                    onPressed: () {
                      controller.clear();
                      // `clear()` no dispara onChanged, hay que avisar a mano
                      // para que la lista se filtre al instante.
                      onChanged('');
                    },
                  )
                : null,
          ),
        );
      },
    );
  }
}

/// Encabezado de seccion: titulo en negrita, accion opcional a la derecha.
///
/// Unifica la jerarquia tipografica de "Servicios populares", "Pagos
/// pendientes" y "Todos los servicios" sin repetir el mismo `Row` tres veces.
class GpSeccionHeader extends StatelessWidget {
  const GpSeccionHeader({
    super.key,
    required this.titulo,
    this.subtitulo,
    this.accion,
  });

  final String titulo;
  final String? subtitulo;
  final Widget? accion;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titulo, style: theme.textTheme.titleLarge),
              if (subtitulo != null) ...[
                const SizedBox(height: 2),
                Text(subtitulo!, style: theme.textTheme.bodySmall),
              ],
            ],
          ),
        ),
        ?accion,
      ],
    );
  }
}
