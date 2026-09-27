package com.proyecto.servicios.model.catalogo;

import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.util.ArrayList;
import java.util.List;

/**
 * Catalogo de marcas y categorias en una sola respuesta.
 *
 * Van juntas porque el cliente siempre necesita las dos: la marca da el logo,
 * el nombre y el color, y la categoria es la que agrupa a las marcas en los
 * chips de filtro. Separarlas en dos endpoints obligaria a dos viajes para
 * pintar la misma pantalla.
 */
@Getter
@Setter
@NoArgsConstructor
public class CatalogoMarcasResponse {

    private List<CatalogoCategoria> categorias = new ArrayList<>();

    private List<CatalogoMarca> marcas = new ArrayList<>();
}
