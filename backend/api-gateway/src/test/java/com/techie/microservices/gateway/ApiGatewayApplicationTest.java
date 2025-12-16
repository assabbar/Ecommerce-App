package com.techie.microservices.gateway;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.reactive.AutoConfigureWebTestClient;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.cloud.contract.wiremock.AutoConfigureWireMock;
import org.springframework.test.web.reactive.server.WebTestClient;

/**
 * API Gateway Application Tests
 * Tests the gateway routing and basic connectivity
 */
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@AutoConfigureWebTestClient
@AutoConfigureWireMock(port = 0)
class ApiGatewayApplicationTest {

    @Autowired
    private WebTestClient webTestClient;

    @Test
    void contextLoads() {
        // Test that the application context loads successfully
        assert webTestClient != null;
    }

    @Test
    void gatewayIsRunning() {
        // Test that the gateway responds
        webTestClient.get()
                .uri("/actuator/health")
                .exchange()
                .expectStatus()
                .isOk();
    }
}
