package com.yashago.calculator.web;

import java.math.BigDecimal;
import java.util.Map;
import java.util.function.BinaryOperator;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.yashago.calculator.service.CalculatorService;

@RestController
@RequestMapping("/api/v" + CalculatorController.API_VERSION)
public class CalculatorController {

    /** Version of the API contract; also the path segment, so the two can't drift apart. */
    static final String API_VERSION = "1";

    private final Map<String, BinaryOperator<BigDecimal>> operations;
    private final String version;

    public CalculatorController(CalculatorService calculator,
                                @Value("${app.version:dev}") String version) {
        this.operations = Map.of(
                "add", calculator::add,
                "subtract", calculator::subtract,
                "multiply", calculator::multiply,
                "divide", calculator::divide);
        this.version = version;
    }

    @GetMapping("/{operation}")
    public CalculationResult calculate(@PathVariable String operation,
                                       @RequestParam BigDecimal a,
                                       @RequestParam BigDecimal b) {
        BinaryOperator<BigDecimal> op = operations.get(operation);
        if (op == null) {
            throw new UnknownOperationException(operation);
        }
        return new CalculationResult(operation, a, b, op.apply(a, b), API_VERSION);
    }

    @GetMapping("/version")
    public Map<String, String> version() {
        return Map.of("version", version);
    }

    public record CalculationResult(String operation, BigDecimal a, BigDecimal b, BigDecimal result,
                                    String version) {
    }
}
