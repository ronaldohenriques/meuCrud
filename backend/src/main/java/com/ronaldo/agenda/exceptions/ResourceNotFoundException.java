package com.ronaldo.agenda.exceptions;

import org.springframework.http.HttpStatus;

import java.util.List;

public class ResourceNotFoundException extends ApiException {
    private static final String ERROR_CODE_PREFIX = "RESOURCE_NOT_FOUND";

    public ResourceNotFoundException(String resourceType, Long id) {
        super(
                HttpStatus.NOT_FOUND,
                ERROR_CODE_PREFIX,
                String.format("%s com ID %d não encontrado", resourceType, id),
                List.of(
                        "Verifique se o identificador está correto",
                        "Confira a lista de recursos disponíveis"
                )
        );
    }
}
