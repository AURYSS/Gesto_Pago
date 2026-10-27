package com.proyecto.servicios.exception;

import com.proyecto.servicios.model.ErrorResponse;
import jakarta.validation.ConstraintViolationException;
import lombok.extern.slf4j.Slf4j;
import org.slf4j.MDC;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.core.AuthenticationException;
import org.springframework.web.HttpRequestMethodNotSupportedException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.MissingServletRequestParameterException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException;

import java.util.stream.Collectors;

@RestControllerAdvice
@Slf4j
public class GlobalExceptionHandler {

    @ExceptionHandler(ApiException.class)
    public ResponseEntity<ErrorResponse> apiException(ApiException e) {
        log.warn("Error de negocio code={} message={}", e.getCode(), e.getMessage());
        ErrorResponse body = new ErrorResponse(e.getCode(), e.getMessage(), traceId());
        return ResponseEntity.status(e.getStatus()).body(body);
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ErrorResponse> validacion(MethodArgumentNotValidException e) {
        String detalles = e.getBindingResult().getFieldErrors().stream()
                .map(f -> f.getField() + ": " + f.getDefaultMessage())
                .collect(Collectors.joining("; "));
        log.warn("Error de validacion: {}", detalles);
        ErrorResponse body = new ErrorResponse(ErrorCodes.VAL_001, detalles, traceId());
        return ResponseEntity.badRequest().body(body);
    }

    @ExceptionHandler(ConstraintViolationException.class)
    public ResponseEntity<ErrorResponse> constraintViolation(ConstraintViolationException e) {
        String detalles = e.getConstraintViolations().stream()
                .map(v -> v.getPropertyPath() + ": " + v.getMessage())
                .collect(Collectors.joining("; "));
        log.warn("Restriccion de validacion incumplida: {}", detalles);
        ErrorResponse body = new ErrorResponse(ErrorCodes.VAL_001, detalles, traceId());
        return ResponseEntity.badRequest().body(body);
    }

    @ExceptionHandler({
            HttpMessageNotReadableException.class,
            MethodArgumentTypeMismatchException.class,
            MissingServletRequestParameterException.class,
            IllegalArgumentException.class
    })
    public ResponseEntity<ErrorResponse> solicitudMalformada(Exception e) {
        log.warn("Solicitud con formato o parametros invalidos: {}", e.getClass().getSimpleName());
        ErrorResponse body = new ErrorResponse(ErrorCodes.VAL_001,
                "Formato de solicitud o parametros invalidos", traceId());
        return ResponseEntity.badRequest().body(body);
    }

    @ExceptionHandler(AuthenticationException.class)
    public ResponseEntity<ErrorResponse> noAutenticado(AuthenticationException e) {
        log.warn("Fallo de autenticacion: {}", e.getClass().getSimpleName());
        ErrorResponse body = new ErrorResponse(ErrorCodes.AUTH_005,
                "Autenticacion requerida", traceId());
        return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(body);
    }

    @ExceptionHandler(AccessDeniedException.class)
    public ResponseEntity<ErrorResponse> accesoDenegado(AccessDeniedException e) {
        log.warn("Acceso denegado a recurso protegido");
        ErrorResponse body = new ErrorResponse(ErrorCodes.PERM_001,
                "No tiene permisos para este recurso", traceId());
        return ResponseEntity.status(HttpStatus.FORBIDDEN).body(body);
    }

    @ExceptionHandler(HttpRequestMethodNotSupportedException.class)
    public ResponseEntity<ErrorResponse> metodoNoSoportado(HttpRequestMethodNotSupportedException e) {
        log.warn("Metodo HTTP no soportado: {}", e.getMethod());
        ErrorResponse body = new ErrorResponse(ErrorCodes.VAL_001,
                "Metodo HTTP no permitido para este endpoint", traceId());
        return ResponseEntity.status(HttpStatus.METHOD_NOT_ALLOWED).body(body);
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<ErrorResponse> generico(Exception e) {
        log.error("Error no controlado ({})", e.getClass().getSimpleName());
        ErrorResponse body = new ErrorResponse(ErrorCodes.UNK_001,
                "Error interno del servidor", traceId());
        return ResponseEntity.internalServerError().body(body);
    }

    private String traceId() {
        String tid = MDC.get("traceId");
        return tid == null ? null : tid;
    }
}