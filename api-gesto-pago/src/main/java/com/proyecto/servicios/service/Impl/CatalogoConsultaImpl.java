package com.proyecto.servicios.service.Impl;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.proyecto.servicios.model.CatalogoProductoCache;
import com.proyecto.servicios.service.CatalogoConsulta;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;

@Service
@Slf4j
public class CatalogoConsultaImpl implements CatalogoConsulta {

    private static final RowMapper<CatalogoProductoCache> MAPPER = (rs, n) -> {
        CatalogoProductoCache c = new CatalogoProductoCache();
        c.setIdServicio(rs.getInt("id_servicio"));
        c.setIdProducto(rs.getInt("id_producto"));
        c.setServicio(rs.getString("servicio"));
        c.setProducto(rs.getString("producto"));
        c.setIdCatTipoServicio(rs.getInt("id_cat_tipo_servicio"));
        c.setTipoFront(rs.getShort("tipo_front"));
        c.setTipoReferencia(rs.getString("tipo_referencia"));
        c.setPrecio(rs.getBigDecimal("precio"));
        c.setLegend(rs.getString("legend"));
        c.setHasDigitoVerificador(rs.getBoolean("has_digito_verificador"));
        c.setShowAyuda(rs.getBoolean("show_ayuda"));
        return c;
    };

    private final JdbcTemplate jdbcTemplate;
    private final StringRedisTemplate redisTemplate;
    private final ObjectMapper objectMapper;
    private final String schema;
    private final String redisClave;

    public CatalogoConsultaImpl(JdbcTemplate jdbcTemplate,
                                StringRedisTemplate redisTemplate,
                                ObjectMapper objectMapper,
                                @Value("${spring.flyway.schemas:gestor_pagos}") String schema,
                                @Value("${catalogo.redis.key:catalogo:productos:activos}") String redisClave) {
        this.jdbcTemplate = jdbcTemplate;
        this.redisTemplate = redisTemplate;
        this.objectMapper = objectMapper;
        this.schema = schema;
        this.redisClave = redisClave;
    }

    @Override
    public Optional<CatalogoProductoCache> buscarActivo(Integer idServicio, Integer idProducto) {
        if (idServicio == null || idProducto == null) {
            return Optional.empty();
        }

        // 1. Buscar en cache de Redis (catalogo activo)
        try {
            String json = redisTemplate.opsForValue().get(redisClave);
            if (json != null && !json.isBlank()) {
                List<CatalogoProductoCache> cache = objectMapper.readValue(json, new TypeReference<List<CatalogoProductoCache>>() {});
                if (cache != null) {
                    Optional<CatalogoProductoCache> encontrado = cache.stream()
                            .filter(p -> idServicio.equals(p.getIdServicio()) && idProducto.equals(p.getIdProducto()))
                            .findFirst();
                    if (encontrado.isPresent()) {
                        log.info("[buscarActivo] Producto encontrado en Redis: idServicio={}, idProducto={}", idServicio, idProducto);
                        return encontrado;
                    }
                }
            }
        } catch (Exception e) {
            log.warn("[buscarActivo] No se pudo consultar Redis: {}", e.getMessage());
        }

        // 2. Fallback a vista en base de datos
        String sql = "SELECT id_servicio, id_producto, servicio, producto, id_cat_tipo_servicio, "
                + "tipo_front, tipo_referencia, precio, legend, has_digito_verificador, show_ayuda "
                + "FROM " + schema + ".v_catalogo_activo WHERE id_servicio = ? AND id_producto = ?";
        List<CatalogoProductoCache> res = jdbcTemplate.query(sql, MAPPER, idServicio, idProducto);
        log.info("[buscarActivo] BD schema='{}', idServicio={}, idProducto={} -> encontrados: {}",
                schema, idServicio, idProducto, res.size());
        return res.stream().findFirst();
    }
}
