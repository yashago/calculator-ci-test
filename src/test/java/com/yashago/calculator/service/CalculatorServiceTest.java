package com.yashago.calculator.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.math.BigDecimal;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;

class CalculatorServiceTest {

    private final CalculatorService calculator = new CalculatorService();

    @ParameterizedTest(name = "{0} + {1} = {2}")
    @CsvSource({"1, 2, 4", "-5, 5, 0", "0.1, 0.2, 0.3", "1000000, 2000000, 3000000"})
    void add(String a, String b, String expected) {
        assertThat(calculator.add(bd(a), bd(b))).isEqualByComparingTo(expected);
    }

    @ParameterizedTest(name = "{0} - {1} = {2}")
    @CsvSource({"5, 3, 2", "3, 5, -2", "0.3, 0.1, 0.2"})
    void subtract(String a, String b, String expected) {
        assertThat(calculator.subtract(bd(a), bd(b))).isEqualByComparingTo(expected);
    }

    @ParameterizedTest(name = "{0} * {1} = {2}")
    @CsvSource({"3, 4, 12", "-2, 3, -6", "0, 99, 0", "1.5, 2, 3"})
    void multiply(String a, String b, String expected) {
        assertThat(calculator.multiply(bd(a), bd(b))).isEqualByComparingTo(expected);
    }

    @ParameterizedTest(name = "{0} / {1} = {2}")
    @CsvSource({"10, 2, 5", "1, 4, 0.25", "-9, 3, -3", "1, 3, 0.3333333333333333"})
    void divide(String a, String b, String expected) {
        assertThat(calculator.divide(bd(a), bd(b))).isEqualByComparingTo(expected);
    }

    @Test
    void divideByZeroThrows() {
        assertThatThrownBy(() -> calculator.divide(BigDecimal.ONE, BigDecimal.ZERO))
                .isInstanceOf(ArithmeticException.class)
                .hasMessage("Division by zero");
    }

    private static BigDecimal bd(String value) {
        return new BigDecimal(value);
    }
}
