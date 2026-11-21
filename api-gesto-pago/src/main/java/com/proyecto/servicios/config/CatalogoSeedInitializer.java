package com.proyecto.servicios.config;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.proyecto.servicios.model.CatalogoProductoCache;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.CommandLineRunner;
import org.springframework.core.annotation.Order;
import org.springframework.core.io.ClassPathResource;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

import java.io.InputStream;
import java.math.BigDecimal;
import java.util.List;
import java.util.Map;

@Component
@Order(10)
@Slf4j
public class CatalogoSeedInitializer implements CommandLineRunner {

    private final JdbcTemplate jdbcTemplate;
    private final ObjectMapper objectMapper;
    private final StringRedisTemplate redisTemplate;
    private final String schema;
    private final String redisClave;

    public CatalogoSeedInitializer(JdbcTemplate jdbcTemplate,
                                   ObjectMapper objectMapper,
                                   StringRedisTemplate redisTemplate,
                                   @Value("${spring.flyway.schemas:gestor_pagos}") String schema,
                                   @Value("${catalogo.redis.key:catalogo:productos:activos}") String redisClave) {
        this.jdbcTemplate = jdbcTemplate;
        this.objectMapper = objectMapper;
        this.redisTemplate = redisTemplate;
        this.schema = schema;
        this.redisClave = redisClave;
    }

    @Override
    public void run(String... args) {
        try {
            // 1. Sincronizar catálogo activo desde archivo semilla si no existe versión activa
            Integer activas = jdbcTemplate.queryForObject(
                    "SELECT COUNT(*) FROM " + schema + ".catalogo_versiones WHERE estado = 'ACTIVA'",
                    Integer.class
            );

            Long activeVersionId = null;

            if (activas == null || activas == 0) {
                log.info("No se encontro version activa de catalogo en '{}'. Inicializando catalogo semilla...", schema);

                ClassPathResource resource = new ClassPathResource("catalogo_servicios.json");
                if (resource.exists()) {
                    List<Map<String, Object>> items;
                    try (InputStream is = resource.getInputStream()) {
                        items = objectMapper.readValue(is, new TypeReference<>() {});
                    }

                    if (items != null && !items.isEmpty()) {
                        activeVersionId = jdbcTemplate.queryForObject(
                                "INSERT INTO " + schema + ".catalogo_versiones "
                                        + "(version, estado, total_productos, checksum, fecha_inicio, fecha_fin) "
                                        + "VALUES (1, 'ACTIVA', ?, 'seed-initial', NOW(), NOW()) RETURNING id",
                                Long.class, items.size()
                        );

                        String sqlInsert = "INSERT INTO " + schema + ".productos "
                                + "(version_id, id_servicio, id_producto, servicio, producto, id_cat_tipo_servicio, "
                                + "tipo_front, tipo_referencia, precio, legend, activo) "
                                + "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, TRUE)";

                        final Long seedVersionId = activeVersionId;
                        jdbcTemplate.batchUpdate(sqlInsert, items, items.size(), (ps, item) -> {
                            ps.setLong(1, seedVersionId);
                            ps.setInt(2, ((Number) item.getOrDefault("idServicio", 1)).intValue());
                            ps.setInt(3, ((Number) item.getOrDefault("idProducto", 1)).intValue());
                            ps.setString(4, String.valueOf(item.getOrDefault("servicio", "Servicio")));
                            ps.setString(5, String.valueOf(item.getOrDefault("producto", "Producto")));
                            ps.setInt(6, 1);

                            BigDecimal precio = BigDecimal.ZERO;
                            Object pObj = item.get("precio");
                            if (pObj != null) {
                                try {
                                    precio = new BigDecimal(pObj.toString());
                                } catch (Exception ignored) {}
                            }

                            short tipoFront = precio.compareTo(BigDecimal.ZERO) > 0 ? (short) 1 : (short) 2;
                            ps.setShort(7, tipoFront);
                            ps.setString(8, "a");
                            ps.setBigDecimal(9, precio);
                            ps.setString(10, String.valueOf(item.getOrDefault("producto", "")));
                        });

                        log.info("[OK] Catalogo semilla poblado con {} productos en version #{} (ID: {})",
                                items.size(), 1, activeVersionId);
                    }
                }
            } else {
                log.info("Catalogo activo ya existe en la base de datos ({} version activa).", activas);
                activeVersionId = jdbcTemplate.queryForObject(
                        "SELECT id FROM " + schema + ".catalogo_versiones WHERE estado = 'ACTIVA' ORDER BY id DESC LIMIT 1",
                        Long.class
                );
            }

            // 2. Sincronizar productos completos desde Redis a la base de datos si Redis tiene catalogo
            if (activeVersionId != null) {
                try {
                    String redisJson = redisTemplate.opsForValue().get(redisClave);
                    if (redisJson != null && !redisJson.isBlank()) {
                        List<CatalogoProductoCache> cacheProds = objectMapper.readValue(
                                redisJson, new TypeReference<List<CatalogoProductoCache>>() {}
                        );
                        if (cacheProds != null && !cacheProds.isEmpty()) {
                            final Long targetVersionId = activeVersionId;
                            String sqlSync = "INSERT INTO " + schema + ".productos "
                                    + "(version_id, id_servicio, id_producto, servicio, producto, id_cat_tipo_servicio, "
                                    + "tipo_front, tipo_referencia, precio, legend, has_digito_verificador, show_ayuda, activo) "
                                    + "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, TRUE) "
                                    + "ON CONFLICT (version_id, id_servicio, id_producto) DO NOTHING";

                            jdbcTemplate.batchUpdate(sqlSync, cacheProds, cacheProds.size(), (ps, cp) -> {
                                ps.setLong(1, targetVersionId);
                                ps.setInt(2, cp.getIdServicio());
                                ps.setInt(3, cp.getIdProducto());
                                ps.setString(4, cp.getServicio() != null ? cp.getServicio() : "Servicio");
                                ps.setString(5, cp.getProducto() != null ? cp.getProducto() : "Producto");
                                ps.setInt(6, cp.getIdCatTipoServicio() != null ? cp.getIdCatTipoServicio() : 1);
                                ps.setShort(7, cp.getTipoFront() != null ? cp.getTipoFront() : (short) 1);
                                ps.setString(8, cp.getTipoReferencia() != null ? cp.getTipoReferencia() : "a");
                                ps.setBigDecimal(9, cp.getPrecio() != null ? cp.getPrecio() : BigDecimal.ZERO);
                                ps.setString(10, cp.getLegend());
                                ps.setBoolean(11, Boolean.TRUE.equals(cp.getHasDigitoVerificador()));
                                ps.setBoolean(12, Boolean.TRUE.equals(cp.getShowAyuda()));
                            });
                            log.info("[OK] Sincronizados {} productos de Redis en gestor_pagos.productos", cacheProds.size());
                        }
                    }
                } catch (Exception re) {
                    log.warn("No se pudo sincronizar catalogo de Redis a base de datos: {}", re.getMessage());
                }
            }

        } catch (Exception e) {
            log.error("Error al inicializar catalogo: {}", e.getMessage(), e);
        }
    }
}
