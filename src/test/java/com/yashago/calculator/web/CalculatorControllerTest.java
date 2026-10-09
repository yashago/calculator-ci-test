package com.yashago.calculator.web;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.web.servlet.MockMvc;

import com.yashago.calculator.service.CalculatorService;

@WebMvcTest(CalculatorController.class)
@Import(CalculatorService.class)
@TestPropertySource(properties = "app.version=sha-test123")
class CalculatorControllerTest {

    @Autowired
    private MockMvc mvc;

    @Test
    void addReturnsResult() throws Exception {
        mvc.perform(get("/api/v1/add").param("a", "2").param("b", "3"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.operation").value("add"))
                .andExpect(jsonPath("$.result").value(5))
                .andExpect(jsonPath("$.version").value("1"));
    }

    @Test
    void divideReturnsResult() throws Exception {
        mvc.perform(get("/api/v1/divide").param("a", "1").param("b", "4"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.result").value(0.25));
    }

    @Test
    void divideByZeroIsBadRequest() throws Exception {
        mvc.perform(get("/api/v1/divide").param("a", "1").param("b", "0"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.detail").value("Division by zero"));
    }

    @Test
    void unknownOperationIsNotFound() throws Exception {
        mvc.perform(get("/api/v1/power").param("a", "2").param("b", "3"))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.detail").value("Unknown operation: power"));
    }

    @Test
    void nonNumericInputIsBadRequest() throws Exception {
        mvc.perform(get("/api/v1/add").param("a", "two").param("b", "3"))
                .andExpect(status().isBadRequest());
    }

    @Test
    void missingParameterIsBadRequest() throws Exception {
        mvc.perform(get("/api/v1/add").param("a", "2"))
                .andExpect(status().isBadRequest());
    }

    @Test
    void versionIsExposed() throws Exception {
        mvc.perform(get("/api/v1/version"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.version").value("sha-test123"));
    }
}
