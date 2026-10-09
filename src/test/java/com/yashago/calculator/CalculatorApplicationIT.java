package com.yashago.calculator;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.context.SpringBootTest.WebEnvironment;
import org.springframework.boot.test.web.server.LocalServerPort;
import org.springframework.web.client.RestClient;

/**
 * Boots the full application on a random port and exercises it over real HTTP,
 * including the actuator endpoints Kubernetes and Prometheus depend on.
 */
@SpringBootTest(webEnvironment = WebEnvironment.RANDOM_PORT)
class CalculatorApplicationIT {

    @LocalServerPort
    private int port;

    private RestClient client;

    @BeforeEach
    void setUp() {
        client = RestClient.builder()
                .baseUrl("http://localhost:" + port)
                .defaultStatusHandler(status -> true, (request, response) -> { })
                .build();
    }

    @Test
    void multiplyOverHttp() {
        String body = client.get().uri("/api/v1/multiply?a=6&b=7").retrieve().body(String.class);
        assertThat(body).contains("\"result\":42", "\"version\":\"1\"");
    }

    @Test
    void livenessAndReadinessProbesAreUp() {
        assertThat(client.get().uri("/actuator/health/liveness").retrieve().body(String.class)).contains("UP");
        assertThat(client.get().uri("/actuator/health/readiness").retrieve().body(String.class)).contains("UP");
    }

    @Test
    void prometheusMetricsAreExposed() {
        client.get().uri("/api/v1/add?a=1&b=1").retrieve().toBodilessEntity();
        String metrics = client.get().uri("/actuator/prometheus").retrieve().body(String.class);
        assertThat(metrics).contains("http_server_requests_seconds");
    }
}
