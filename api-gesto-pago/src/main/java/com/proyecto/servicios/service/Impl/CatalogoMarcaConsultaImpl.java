package com.proyecto.servicios.service.Impl;

import com.proyecto.servicios.model.catalogo.CatalogoCategoria;
import com.proyecto.servicios.model.catalogo.CatalogoMarca;
import com.proyecto.servicios.model.catalogo.CatalogoMarcasResponse;
import com.proyecto.servicios.service.CatalogoMarcaConsulta;
import lombok.extern.slf4j.Slf4j;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Service;

@Service
@Slf4j
public class CatalogoMarcaConsultaImpl implements CatalogoMarcaConsulta {

    private static final String SQL_CATEGORIAS =
            "SELECT slug, nombre, orden FROM catalogo_categorias ORDER BY orden, slug";

    private static final String SQL_MARCAS =
            "SELECT slug, nombre, categoria, color_hex, logo_asset, destacada, orden "
                    + "FROM catalogo_marcas WHERE activo ORDER BY orden, nombre, slug";

    private static final RowMapper<CatalogoCategoria> CATEGORIA_MAPPER = (rs, n) -> {
        CatalogoCategoria c = new CatalogoCategoria();
        c.setSlug(rs.getString("slug"));
        c.setNombre(rs.getString("nombre"));
        c.setOrden(rs.getInt("orden"));
        return c;
    };

    private static final RowMapper<CatalogoMarca> MARCA_MAPPER = (rs, n) -> {
        CatalogoMarca m = new CatalogoMarca();
        m.setSlug(rs.getString("slug"));
        m.setNombre(rs.getString("nombre"));
        m.setCategoria(rs.getString("categoria"));
        m.setColorHex(rs.getString("color_hex"));
        m.setLogoAsset(rs.getString("logo_asset"));
        m.setDestacada(rs.getBoolean("destacada"));
        m.setOrden(rs.getInt("orden"));
        return m;
    };

    private final JdbcTemplate jdbcTemplate;

    public CatalogoMarcaConsultaImpl(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    @Override
    public CatalogoMarcasResponse obtenerMarcas() {
        CatalogoMarcasResponse respuesta = new CatalogoMarcasResponse();
        respuesta.setCategorias(jdbcTemplate.query(SQL_CATEGORIAS, CATEGORIA_MAPPER));
        respuesta.setMarcas(jdbcTemplate.query(SQL_MARCAS, MARCA_MAPPER));
        log.info("Catalogo de marcas servido desde BD ({} marcas, {} categorias)",
                respuesta.getMarcas().size(), respuesta.getCategorias().size());
        return respuesta;
    }
}
