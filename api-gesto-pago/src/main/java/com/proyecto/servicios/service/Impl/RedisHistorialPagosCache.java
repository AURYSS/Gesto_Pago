package com.proyecto.servicios.service.Impl;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.proyecto.servicios.model.pago.TransaccionDto;
import com.proyecto.servicios.service.HistorialPagosCache;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;

import java.time.Duration;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.Optional;

/**
 * Historial de pagos en Redis. Un hash por usuario: campo = id de transaccion, valor = JSON del DTO.
 *
 * <p>Se usa un hash y no una lista porque HSET es atomico por campo: dos pagos concurrentes
 * del mismo usuario nunca se pisan entre si. La ordenacion se hace al leer, recortando a
 * {@code maxEntradas} (el id es BIGSERIAL, asi que orden descendente por id equivale al
 * {@code ORDER BY created_at DESC} de Postgres).
 */
@Service
@Slf4j
public class RedisHistorialPagosCache implements HistorialPagosCache {

    private final StringRedisTemplate redisTemplate;
    private final ObjectMapper objectMapper;
    private final boolean enabled;
    private final String prefijo;
    private final Duration ttl;
    private final int maxEntradas;

    public RedisHistorialPagosCache(StringRedisTemplate redisTemplate,
                                    ObjectMapper objectMapper,
                                    @Value("${pagos.historial.redis.enabled:true}") boolean enabled,
                                    @Value("${pagos.historial.redis.key:pagos:historial}") String prefijo,
                                    @Value("${pagos.historial.redis.ttl-seconds:900}") long ttlSegundos,
                                    @Value("${pagos.historial.redis.max-entradas:50}") int maxEntradas) {
        this.redisTemplate = redisTemplate;
        this.objectMapper = objectMapper;
        this.enabled = enabled;
        this.prefijo = prefijo;
        this.ttl = Duration.ofSeconds(ttlSegundos);
        this.maxEntradas = maxEntradas;
    }

    @Override
    public Optional<List<TransaccionDto>> obtener(Long usuarioId) {
        if (!enabled) {
            return Optional.empty();
        }
        String clave = clave(usuarioId);
        try {
            Map<Object, Object> entradas = redisTemplate.opsForHash().entries(clave);
            if (entradas == null || entradas.isEmpty()) {
                return Optional.empty();
            }
            List<TransaccionDto> historial = new ArrayList<>(entradas.size());
            for (Map.Entry<Object, Object> entrada : entradas.entrySet()) {
                try {
                    historial.add(objectMapper.readValue((String) entrada.getValue(), TransaccionDto.class));
                } catch (Exception e) {
                    log.warn("Entrada de historial ilegible en Redis, se descarta clave={} campo={}: {}",
                            clave, entrada.getKey(), e.getMessage());
                }
            }
            historial.sort(Comparator.comparing(TransaccionDto::getId).reversed());
            if (historial.size() > maxEntradas) {
                return Optional.of(List.copyOf(historial.subList(0, maxEntradas)));
            }
            return Optional.of(List.copyOf(historial));
        } catch (Exception e) {
            log.warn("Redis no disponible para leer el historial de usuario {}, se ira a Postgres: {}",
                    usuarioId, e.getMessage());
            return Optional.empty();
        }
    }

    @Override
    public void guardar(Long usuarioId, List<TransaccionDto> historial) {
        if (!enabled || historial == null) {
            return;
        }
        String clave = clave(usuarioId);
        try {
            redisTemplate.delete(clave);
            if (historial.isEmpty()) {
                return;
            }
            List<TransaccionDto> recortado = historial.size() > maxEntradas
                    ? historial.subList(0, maxEntradas)
                    : historial;
            for (TransaccionDto dto : recortado) {
                redisTemplate.opsForHash().put(clave, campo(dto), serializar(dto));
            }
            redisTemplate.expire(clave, ttl);
        } catch (Exception e) {
            log.warn("No se pudo cachear el historial de usuario {}: {}", usuarioId, e.getMessage());
        }
    }

    @Override
    public void registrar(Long usuarioId, TransaccionDto transaccion) {
        if (!enabled || usuarioId == null || transaccion == null || transaccion.getId() == null) {
            return;
        }
        String clave = clave(usuarioId);
        try {
            if (!Boolean.TRUE.equals(redisTemplate.hasKey(clave))) {
                return;
            }
            redisTemplate.opsForHash().put(clave, campo(transaccion), serializar(transaccion));
            redisTemplate.expire(clave, ttl);
            recortar(clave);
        } catch (Exception e) {
            log.warn("No se pudo actualizar el historial cacheado de usuario {}: {}", usuarioId, e.getMessage());
        }
    }

    @Override
    public void invalidar(Long usuarioId) {
        if (!enabled || usuarioId == null) {
            return;
        }
        try {
            redisTemplate.delete(clave(usuarioId));
        } catch (Exception e) {
            log.warn("No se pudo invalidar el historial cacheado de usuario {}: {}", usuarioId, e.getMessage());
        }
    }

    /**
     * Deja solo las {@code maxEntradas} mas recientes. Best effort: si dos pagos entran a la vez
     * y el recorte se entrelaza, lo peor que pasa es que se borre una entrada vieja, y en el
     * peor de los casos la siguiente lectura vuelve a llenarse desde Postgres.
     */
    private void recortar(String clave) {
        Long total = redisTemplate.opsForHash().size(clave);
        if (total == null || total <= maxEntradas) {
            return;
        }
        List<String> campos = new ArrayList<>(redisTemplate.opsForHash().keys(clave).stream()
                .map(String::valueOf)
                .sorted(Comparator.comparingLong(this::idDeCampo))
                .limit(total - maxEntradas)
                .toList());
        if (!campos.isEmpty()) {
            redisTemplate.opsForHash().delete(clave, campos.toArray());
        }
    }

    private long idDeCampo(String campo) {
        try {
            return Long.parseLong(campo);
        } catch (NumberFormatException e) {
            return Long.MAX_VALUE;
        }
    }

    private String serializar(TransaccionDto dto) {
        try {
            return objectMapper.writeValueAsString(dto);
        } catch (Exception e) {
            throw new IllegalStateException("No se pudo serializar la transaccion " + dto.getId(), e);
        }
    }

    private String clave(Long usuarioId) {
        return prefijo + ":" + usuarioId;
    }

    private String campo(TransaccionDto dto) {
        return String.valueOf(dto.getId());
    }
}
