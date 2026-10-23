package com.proyecto.servicios.service.Impl;

import com.proyecto.servicios.model.gestopago.Firma;
import com.proyecto.servicios.service.FirmaService;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import javax.crypto.Cipher;
import javax.crypto.spec.IvParameterSpec;
import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.Arrays;
import java.util.Base64;

@Service
public class FirmaServiceImpl implements FirmaService {

    private static final String ALGORITMO_TRANSFORMACION = "AES/CBC/PKCS5Padding";
    private static final String ALGORITMO_LLAVE = "AES";

    private final SecretKeySpec secretKey;
    private final IvParameterSpec ivSpec;

    public FirmaServiceImpl(@Value("${gestopago.auth.password:gestopago-secret}") String secret) {
        try {
            MessageDigest sha256 = MessageDigest.getInstance("SHA-256");
            byte[] keyBytes = sha256.digest(secret.getBytes(StandardCharsets.UTF_8));
            this.secretKey = new SecretKeySpec(keyBytes, ALGORITMO_LLAVE);
            this.ivSpec = new IvParameterSpec(Arrays.copyOfRange(keyBytes, 0, 16));
        } catch (Exception e) {
            throw new IllegalStateException("No se pudo inicializar el servicio de encriptacion de Firma", e);
        }
    }

    @Override
    public String encriptar(Firma firma) {
        if (firma == null) {
            throw new IllegalArgumentException("El objeto Firma no puede ser nulo");
        }
        try {
            Cipher cipher = Cipher.getInstance(ALGORITMO_TRANSFORMACION);
            cipher.init(Cipher.ENCRYPT_MODE, secretKey, ivSpec);
            byte[] cifrado = cipher.doFinal(firma.cadenaOriginal().getBytes(StandardCharsets.UTF_8));
            return Base64.getEncoder().encodeToString(cifrado);
        } catch (Exception e) {
            throw new IllegalStateException("Error al encriptar la Firma de la transaccion", e);
        }
    }

    @Override
    public Firma desencriptar(String firmaEncriptada) {
        if (firmaEncriptada == null || firmaEncriptada.isBlank()) {
            throw new IllegalArgumentException("La firma encriptada no puede estar vacia");
        }
        try {
            Cipher cipher = Cipher.getInstance(ALGORITMO_TRANSFORMACION);
            cipher.init(Cipher.DECRYPT_MODE, secretKey, ivSpec);
            byte[] decodificado = Base64.getDecoder().decode(firmaEncriptada);
            String cadena = new String(cipher.doFinal(decodificado), StandardCharsets.UTF_8);
            String[] partes = cadena.split("\\|", -1);
            if (partes.length < 10) {
                throw new IllegalArgumentException("Formato de firma desencriptada invalido");
            }
            return Firma.builder()
                    .idDistribuidor(entero(partes[0]))
                    .codigoDispositivo(vacioANull(partes[1]))
                    .idServicio(entero(partes[2]))
                    .idProducto(entero(partes[3]))
                    .telefono(vacioANull(partes[4]))
                    .referencia(vacioANull(partes[5]))
                    .horaLocal(vacioANull(partes[6]))
                    .montoPago(vacioANull(partes[7]))
                    .upc(vacioANull(partes[8]))
                    .unidad(vacioANull(partes[9]))
                    .build();
        } catch (IllegalArgumentException e) {
            throw e;
        } catch (Exception e) {
            throw new IllegalStateException("Error al desencriptar la Firma", e);
        }
    }

    private Integer entero(String valor) {
        if (valor == null || valor.isBlank()) {
            return null;
        }
        return Integer.valueOf(valor.trim());
    }

    private String vacioANull(String valor) {
        return (valor == null || valor.isEmpty()) ? null : valor;
    }
}
