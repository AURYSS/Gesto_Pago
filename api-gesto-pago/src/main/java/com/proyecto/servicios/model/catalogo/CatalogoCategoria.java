package com.proyecto.servicios.model.catalogo;

import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

/**
 * Categoria funcional de una marca (tiempo aire, internet, television...).
 *
 * El nombre es el que declara el catalogo y sirve de texto plano: la app lo
 * traduce cuando conoce el slug y, cuando no, cae a este nombre. Por eso el
 * slug es la clave y no el nombre.
 */
@Getter
@Setter
@NoArgsConstructor
public class CatalogoCategoria {

    private String slug;

    private String nombre;

    private Integer orden;
}
