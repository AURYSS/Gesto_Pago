package com.proyecto.servicios.service;

import com.proyecto.servicios.model.pago.TransaccionDto;

import java.util.List;
import java.util.Optional;

/**
 * Cache del historial de pagos por usuario.
 *
 * <p>Postgres es la fuente de verdad: este cache solo evita repetir la consulta cuando
 * el usuario abre la pantalla de historial. Redis es la lectura prioritaria y Postgres
 * se consulta unicamente en un cache miss.
 *
 * <p>Ninguna operacion puede propagar un fallo: si Redis no responde, la cache degrada
 * a "vacia" y el llamador sigue trabajando contra Postgres.
 */
public interface HistorialPagosCache {

    /**
     * @return el historial cacheado, o vacio si no hay entrada en cache (o Redis no responde)
     */
    Optional<List<TransaccionDto>> obtener(Long usuarioId);

    /**
     * Reemplaza por completo la entrada de cache. Se usa en el llenado en frío desde Postgres.
     */
    void guardar(Long usuarioId, List<TransaccionDto> historial);

    /**
     * Inserta o actualiza una sola transaccion sin invalidar el resto del historial.
     * Si no hay entrada en cache todavia no hace nada: la siguiente lectura la llenara
     * desde Postgres.
     */
    void registrar(Long usuarioId, TransaccionDto transaccion);

    void invalidar(Long usuarioId);
}
