package com.ronaldo.agenda.exceptions;

import lombok.Getter;
import org.springframework.http.HttpStatus;

import java.util.List;


@Getter
public abstract class ApiException extends RuntimeException {
    // Getters
    private final HttpStatus status;
    private final String errorCode;
    private final List<String> details;

    protected ApiException(HttpStatus status, String errorCode, String message) {
        this(status, errorCode, message, null);
    }

    protected ApiException(HttpStatus status, String errorCode, String message, List<String> details) {
        super(message);
        this.status = status;
        this.errorCode = errorCode;
        this.details = details;
    }

}



