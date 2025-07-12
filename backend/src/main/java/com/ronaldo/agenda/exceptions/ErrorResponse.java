package com.ronaldo.agenda.exceptions;

import java.time.LocalDateTime;

public record ErrorResponse(
        LocalDateTime timestamp,
        int status,
        String error,
        String message,
        String path,
        String errorCode // Opcional para rastreamento
) {
}


