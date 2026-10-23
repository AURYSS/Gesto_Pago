package com.proyecto.servicios.service;

import com.proyecto.servicios.model.gestopago.Firma;

public interface FirmaService {

    /**
     * Encripta el objeto Firma en una cadena Base64 segura (AES-256).
     */
    String encriptar(Firma firma);

    /**
     * Desencripta una firma en Base64 y reconstruye el objeto Firma original.
     */
    Firma desencriptar(String firmaEncriptada);
}
