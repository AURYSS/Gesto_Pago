package com.proyecto.servicios.service;

import com.proyecto.servicios.model.catalogo.CatalogoMarcasResponse;

/**
 * Consulta del catalogo de marcas y categorias funcionales.
 *
 * Es la fuente de verdad de la presentacion de cada marca (nombre, categoria,
 * color y logo). El catalogo de productos del proveedor no trae ninguno de
 * esos datos, asi que se administran aqui y no en el cliente: corregir un
 * color o dar de alta una categoria nueva es un UPDATE, no un release.
 */
public interface CatalogoMarcaConsulta {

    CatalogoMarcasResponse obtenerMarcas();
}
