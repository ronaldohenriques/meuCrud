package com.ronaldo.agenda.exceptions;

import org.springframework.http.HttpStatus;

import java.util.List;

public class ValidationException extends ApiException {
    private static final String ERROR_CODE_PREFIX = "VALIDATION_ERROR";

    public ValidationException(String message) {
        super(HttpStatus.BAD_REQUEST, ERROR_CODE_PREFIX, message);
    }

    public ValidationException(String message, List<String> details) {
        super(HttpStatus.BAD_REQUEST, ERROR_CODE_PREFIX, message, details);
    }

    public ValidationException(List<String> errors) {
        super(
                HttpStatus.BAD_REQUEST,
                ERROR_CODE_PREFIX,
                "Falha na validação dos dados de entrada",
                errors
        );
    }
}

