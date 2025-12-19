package com.techie.microservices.product;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.testcontainers.containers.MongoDBContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

@Testcontainers
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@DisplayName("Product Service Integration Tests with Testcontainers")
class ProductServiceIT {

    @Container
    static MongoDBContainer mongo = new MongoDBContainer("mongo:7.0.5");

    @DynamicPropertySource
    static void mongoProps(DynamicPropertyRegistry registry) {
        registry.add("spring.data.mongodb.uri", mongo::getConnectionString);
    }

    @Test
    @DisplayName("Context should load with MongoDB container")
    void contextLoads() {
        // If context loads without errors, test passes
        assert mongo.isRunning() : "MongoDB container should be running";
    }
}
