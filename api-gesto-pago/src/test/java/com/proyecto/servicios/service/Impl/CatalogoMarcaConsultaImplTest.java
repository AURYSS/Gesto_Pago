package com.proyecto.servicios.service.Impl;

import com.proyecto.servicios.model.catalogo.CatalogoCategoria;
import com.proyecto.servicios.model.catalogo.CatalogoMarca;
import com.proyecto.servicios.model.catalogo.CatalogoMarcasResponse;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;

import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.contains;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class CatalogoMarcaConsultaImplTest {

    @Mock
    private JdbcTemplate jdbcTemplate;

    private CatalogoMarcaConsultaImpl service;

    @BeforeEach
    void setUp() {
        service = new CatalogoMarcaConsultaImpl(jdbcTemplate);
    }

    @Test
    @SuppressWarnings("unchecked")
    void obtenerMarcasDevuelveCategoriasYMarcasDesdeBd() {
        CatalogoCategoria cat = new CatalogoCategoria();
        cat.setSlug("tiempo_aire");
        cat.setNombre("Tiempo Aire");
        cat.setOrden(1);

        CatalogoMarca marca = new CatalogoMarca();
        marca.setSlug("telcel");
        marca.setNombre("Telcel");
        marca.setCategoria("tiempo_aire");
        marca.setColorHex("#00A9E0");
        marca.setLogoAsset("assets/images/marcas/telcel.png");
        marca.setDestacada(true);
        marca.setOrden(1);

        when(jdbcTemplate.query(contains("catalogo_categorias"), any(RowMapper.class)))
                .thenReturn(List.of(cat));
        when(jdbcTemplate.query(contains("catalogo_marcas"), any(RowMapper.class)))
                .thenReturn(List.of(marca));

        CatalogoMarcasResponse res = service.obtenerMarcas();

        assertNotNull(res);
        assertEquals(1, res.getCategorias().size());
        assertEquals("tiempo_aire", res.getCategorias().get(0).getSlug());
        assertEquals(1, res.getMarcas().size());
        assertEquals("telcel", res.getMarcas().get(0).getSlug());
        assertTrue(res.getMarcas().get(0).getDestacada());

        verify(jdbcTemplate).query(contains("catalogo_categorias"), any(RowMapper.class));
        verify(jdbcTemplate).query(contains("catalogo_marcas"), any(RowMapper.class));
    }
}
