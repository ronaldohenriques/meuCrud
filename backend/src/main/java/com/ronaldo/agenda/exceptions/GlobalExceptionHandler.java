package com.ronaldo.agenda.exceptions;


import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.context.request.WebRequest;

import java.time.LocalDateTime;
import java.util.stream.Collectors;

@RestControllerAdvice
public class GlobalExceptionHandler {

    private static final String INTERNAL_ERROR_CODE_PREFIX = "INT-";
    private static final String VALIDATION_ERROR_CODE_PREFIX = "VAL-";
    private static final String NOT_FOUND_ERROR_CODE_PREFIX = "NF-";

    private static final Logger logger = LoggerFactory.getLogger(GlobalExceptionHandler.class);

    @ExceptionHandler(ResourceNotFoundException.class)
    public ResponseEntity<ErrorResponse> handleResourceNotFound(ResourceNotFoundException ex, WebRequest request) {
        String errorCode = NOT_FOUND_ERROR_CODE_PREFIX + generateShortErrorId();
        logError(ex, errorCode);
        return buildErrorResponse(
                HttpStatus.NOT_FOUND,
                "Recurso não encontrado",
                ex.getMessage(),
                getRequestPath(request),
                errorCode
        );
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ErrorResponse> handleValidationExceptions(MethodArgumentNotValidException ex, WebRequest request) {
        String errorDetails = ex.getBindingResult().getFieldErrors()
                .stream()
                .map(error -> String.format("[%s: %s]", error.getField(), error.getDefaultMessage()))
                .collect(Collectors.joining(" "));

        String errorCode = VALIDATION_ERROR_CODE_PREFIX + generateShortErrorId();
        logError(ex, errorCode);

        return buildErrorResponse(
                HttpStatus.BAD_REQUEST,
                "Dados inválidos",
                errorDetails,
                getRequestPath(request),
                errorCode
        );
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<ErrorResponse> handleAllExceptions(Exception ex, WebRequest request) {
        String errorCode = INTERNAL_ERROR_CODE_PREFIX + generateShortErrorId();
        logError(ex, errorCode);
        return buildErrorResponse(
                HttpStatus.INTERNAL_SERVER_ERROR,
                "Erro interno no servidor",
                "Ocorreu um erro inesperado. Código: " + errorCode,
                getRequestPath(request),
                errorCode
        );
    }

    private ResponseEntity<ErrorResponse> buildErrorResponse(
            HttpStatus status,
            String errorTitle,
            String errorDetail,
            String path,
            String errorCode
    ) {
        return new ResponseEntity<>(
                new ErrorResponse(
                        LocalDateTime.now(),
                        status.value(),
                        errorTitle,
                        errorDetail,
                        path,
                        errorCode
                ),
                status
        );
    }

    private String generateShortErrorId() {
        return Long.toHexString(System.currentTimeMillis()).substring(0, 6).toUpperCase();
    }

    private String getRequestPath(WebRequest request) {
        return request.getDescription(false)
                .replace("uri=", "")
                .split(";")[0]; // Remove parâmetros adicionais
    }

    private void logError(Exception ex, String errorCode) {
        String logMessage = String.format(
                "[%s] %s - %s",
                errorCode,
                ex.getClass().getSimpleName(),
                ex.getMessage()
        );
        logger.error(logMessage, ex);
    }

}
