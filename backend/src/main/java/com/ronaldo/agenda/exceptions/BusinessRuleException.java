package com.ronaldo.agenda.exceptions;

import org.springframework.http.HttpStatus;

import java.util.List;

public class BusinessRuleException extends ApiException {
    private static final String ERROR_CODE_PREFIX = "BUSINESS_RULE_VIOLATION";

    public BusinessRuleException(String message) {
        super(HttpStatus.CONFLICT, ERROR_CODE_PREFIX, message);
    }

    public BusinessRuleException(String message, List<String> resolutionSteps) {
        super(HttpStatus.CONFLICT, ERROR_CODE_PREFIX, message, resolutionSteps);
    }

}