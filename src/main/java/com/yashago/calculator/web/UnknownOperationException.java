package com.yashago.calculator.web;

public class UnknownOperationException extends RuntimeException {

    public UnknownOperationException(String operation) {
        super("Unknown operation: " + operation);
    }
}
