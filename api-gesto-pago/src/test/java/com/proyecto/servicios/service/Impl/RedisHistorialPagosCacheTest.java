package com.proyecto.servicios.service.Impl;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.proyecto.servicios.model.pago.TransaccionDto;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.redis.RedisConnectionFailureException;
import org.springframework.data.redis.core.HashOperations;
import org.springframework.data.redis.core.StringRedisTemplate;

import java.time.Duration;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatCode;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
@DisplayName("RedisHistorialPagosCache")
class RedisHistorialPagosCacheTest {

    @Mock
    private StringRedisTemplate redisTemplate;
    @Mock
    private HashOperations<String, Object, Object> hashOperations;

    private final ObjectMapper objectMapper = new ObjectMapper();
    private RedisHistorialPagosCache cache;

    @BeforeEach
    void setUp() {
        lenient().when(redisTemplate.opsForHash()).thenReturn(hashOperations);
        cache = new RedisHistorialPagosCache(redisTemplate, objectMapper, true, "pagos:historial", 900, 50);
    }

    @Test
    @DisplayName("devuelve el historial cacheado y no lo vuelve a pedir a Postgres")
    void obtenerDevuelveLoQueHayEnRedis() {
        Map<Object, Object> entradas = new LinkedHashMap<>();
        entradas.put("7", json(dto(7L, "Spotify")));
        entradas.put("9", json(dto(9L, "Netflix")));
        when(hashOperations.entries("pagos:historial:5")).thenReturn(entradas);

        Optional<List<TransaccionDto>> resultado = cache.obtener(5L);

        assertThat(resultado).isPresent();
        assertThat(resultado.get()).extracting(TransaccionDto::getId).containsExactly(9L, 7L);
        assertThat(resultado.get()).extracting(TransaccionDto::getProducto)
                .containsExactly("Netflix", "Spotify");
    }

    @Test
    @DisplayName("cache miss cuando la clave no existe")
    void obtenerVacioSiNoHayClave() {
        when(hashOperations.entries("pagos:historial:5")).thenReturn(Map.of());

        assertThat(cache.obtener(5L)).isEmpty();
    }

    @Test
    @DisplayName("si Redis falla se degrada a vacio en vez de propagar el error")
    void obtenerDegradaSiRedisEstaCaido() {
        when(hashOperations.entries(anyString()))
                .thenThrow(new RedisConnectionFailureException("no hay redis"));

        assertThatCode(() -> assertThat(cache.obtener(5L)).isEmpty()).doesNotThrowAnyException();
    }

    @Test
    @DisplayName("una entrada corrupta se descarta sin tumbar el resto del historial")
    void obtenerDescartaEntradasIlegibles() {
        Map<Object, Object> entradas = new LinkedHashMap<>();
        entradas.put("7", json(dto(7L, "Netflix")));
        entradas.put("8", "{esto-no-es-json");
        when(hashOperations.entries("pagos:historial:5")).thenReturn(entradas);

        Optional<List<TransaccionDto>> resultado = cache.obtener(5L);

        assertThat(resultado).isPresent();
        assertThat(resultado.get()).extracting(TransaccionDto::getId).containsExactly(7L);
    }

    @Test
    @DisplayName("guardar deja la entrada en el hash y renueva el TTL")
    void guardarEscribeEnElHashYPoneTtl() {
        cache.guardar(5L, List.of(dto(7L, "Netflix"), dto(9L, "Spotify")));

        verify(redisTemplate).delete("pagos:historial:5");
        verify(hashOperations).put(eq("pagos:historial:5"), eq("7"), anyString());
        verify(hashOperations).put(eq("pagos:historial:5"), eq("9"), anyString());
        verify(redisTemplate).expire("pagos:historial:5", Duration.ofSeconds(900));
    }

    @Test
    @DisplayName("guardar un historial vacio solo borra, no deja hash colgando")
    void guardarVacioSoloBorra() {
        cache.guardar(5L, List.of());

        verify(redisTemplate).delete("pagos:historial:5");
        verify(redisTemplate, never()).expire(anyString(), any(Duration.class));
    }

    @Test
    @DisplayName("registrar hace upsert de una sola transaccion sin invalidar el resto")
    void registrarHaceUpsertDeUnaTransaccion() {
        when(redisTemplate.hasKey("pagos:historial:5")).thenReturn(true);

        cache.registrar(5L, dto(11L, "Amazon"));

        verify(hashOperations).put(eq("pagos:historial:5"), eq("11"), anyString());
        verify(redisTemplate, never()).delete("pagos:historial:5");
        verify(redisTemplate).expire("pagos:historial:5", Duration.ofSeconds(900));
    }

    @Test
    @DisplayName("registrar no hace nada si todavia no hay entrada en cache")
    void registrarNoEscribeSiNoHayEntrada() {
        when(redisTemplate.hasKey("pagos:historial:5")).thenReturn(false);

        cache.registrar(5L, dto(11L, "Amazon"));

        verify(hashOperations, never()).put(anyString(), anyString(), anyString());
    }

    @Test
    @DisplayName("registrar ignora transacciones sin id")
    void registrarIgnoraTransaccionSinId() {
        cache.registrar(5L, dto(null, "Amazon"));

        verify(redisTemplate, never()).hasKey(anyString());
    }

    @Test
    @DisplayName("recorta las entradas mas viejas cuando se supera el maximo")
    void registrarRecortaEntradasViejas() {
        RedisHistorialPagosCache chico =
                new RedisHistorialPagosCache(redisTemplate, objectMapper, true, "pagos:historial", 900, 2);
        when(redisTemplate.hasKey("pagos:historial:5")).thenReturn(true);
        when(hashOperations.size("pagos:historial:5")).thenReturn(4L);
        when(hashOperations.keys("pagos:historial:5"))
                .thenReturn(new LinkedHashSet<>(List.of("1", "2", "3", "4")));

        chico.registrar(5L, dto(4L, "Amazon"));

        verify(hashOperations).delete("pagos:historial:5", "1", "2");
    }

    @Test
    @DisplayName("no recorta cuando el historial todavia cabe")
    void registrarNoRecortaSiNoSePasaDelMaximo() {
        when(redisTemplate.hasKey("pagos:historial:5")).thenReturn(true);
        when(hashOperations.size("pagos:historial:5")).thenReturn(3L);

        cache.registrar(5L, dto(4L, "Amazon"));

        verify(hashOperations, never()).delete(eq("pagos:historial:5"), any(Object[].class));
    }

    @Test
    @DisplayName("un fallo de Redis al escribir no rompe el flujo del pago")
    void escribirNoPropagaErrores() {
        when(redisTemplate.hasKey(anyString()))
                .thenThrow(new RedisConnectionFailureException("no hay redis"));

        assertThatCode(() -> cache.registrar(5L, dto(11L, "Amazon"))).doesNotThrowAnyException();
        assertThatCode(() -> cache.guardar(5L, List.of(dto(1L, "Netflix")))).doesNotThrowAnyException();
        assertThatCode(() -> cache.invalidar(5L)).doesNotThrowAnyException();
    }

    @Test
    @DisplayName("con el cache deshabilitado nunca toca Redis")
    void deshabilitadoNoTocaRedis() {
        RedisHistorialPagosCache apagado =
                new RedisHistorialPagosCache(redisTemplate, objectMapper, false, "pagos:historial", 900, 50);

        assertThat(apagado.obtener(5L)).isEmpty();
        apagado.guardar(5L, List.of(dto(1L, "Netflix")));
        apagado.registrar(5L, dto(1L, "Netflix"));
        apagado.invalidar(5L);

        verify(redisTemplate, never()).opsForHash();
    }

    private TransaccionDto dto(Long id, String producto) {
        TransaccionDto dto = new TransaccionDto();
        dto.setId(id);
        dto.setProducto(producto);
        dto.setEstado("APROBADA");
        dto.setMonto("50.00");
        return dto;
    }

    private String json(TransaccionDto dto) {
        try {
            return objectMapper.writeValueAsString(dto);
        } catch (Exception e) {
            throw new IllegalStateException(e);
        }
    }
}
