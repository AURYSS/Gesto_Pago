package com.proyecto.servicios.model.catalogo;

import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

/**
 * Marca del catalogo con su presentacion en la app.
 *
 * `logoAsset` es la ruta del logo dentro del paquete de assets del cliente y
 * `colorHex` el color de la marca; ambos pueden venir null, y la app lo
 * contempla: sin logo dibuja iniciales y sin color deja la franja neutra en
 * lugar de inventar un tinte.
 */
@Getter
@Setter
@NoArgsConstructor
public class CatalogoMarca {

    private String slug;

    private String nombre;

    private String categoria;

    private String colorHex;

    private String logoAsset;

    private Boolean destacada;

    private Integer orden;
}
