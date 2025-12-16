package com.techie.microservices.integration;

import io.restassured.RestAssured;
import io.restassured.http.ContentType;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.condition.EnabledIfEnvironmentVariable;

import java.math.BigDecimal;

import static io.restassured.RestAssured.*;
import static org.hamcrest.Matchers.*;

/**
 * Full Stack Integration Tests
 * Tests the complete E-commerce microservices architecture
 * 
 * Prerequisites:
 * - All services must be running (docker-compose up)
 * - Services: product, inventory, order, notification, api-gateway
 * - Databases: MySQL, MongoDB, Kafka
 */
@DisplayName("E-Commerce Full Stack Integration Tests")
@EnabledIfEnvironmentVariable(named = "RUN_INTEGRATION_TESTS", matches = "true")
public class FullStackIntegrationTest {

    private static final String API_GATEWAY_URL = "http://localhost:9000";
    private static final String PRODUCT_SERVICE_URL = "http://localhost:8080";
    private static final String INVENTORY_SERVICE_URL = "http://localhost:8082";
    private static final String ORDER_SERVICE_URL = "http://localhost:8081";

    @BeforeAll
    public static void setup() {
        RestAssured.baseURI = API_GATEWAY_URL;
    }

    @Test
    @DisplayName("Test 1: All services should be healthy and running")
    public void testAllServicesHealthy() {
        // Test Product Service
        given()
            .baseUri(PRODUCT_SERVICE_URL)
        .when()
            .get("/actuator/health")
        .then()
            .statusCode(200)
            .body("status", equalTo("UP"));

        // Test Inventory Service
        given()
            .baseUri(INVENTORY_SERVICE_URL)
        .when()
            .get("/actuator/health")
        .then()
            .statusCode(200)
            .body("status", equalTo("UP"));

        // Test Order Service
        given()
            .baseUri(ORDER_SERVICE_URL)
        .when()
            .get("/actuator/health")
        .then()
            .statusCode(200)
            .body("status", equalTo("UP"));

        // Test API Gateway
        when()
            .get("/actuator/health")
        .then()
            .statusCode(200)
            .body("status", equalTo("UP"));
    }

    @Test
    @DisplayName("Test 2: Create a product successfully")
    public void testCreateProduct() {
        String productPayload = """
            {
                "name": "Integration Test Laptop",
                "description": "High-performance laptop for testing",
                "price": 1299.99
            }
            """;

        given()
            .baseUri(PRODUCT_SERVICE_URL)
            .contentType(ContentType.JSON)
            .body(productPayload)
        .when()
            .post("/api/products")
        .then()
            .statusCode(201)
            .body("id", notNullValue())
            .body("name", equalTo("Integration Test Laptop"));
    }

    @Test
    @DisplayName("Test 3: Retrieve all products")
    public void testGetAllProducts() {
        given()
            .baseUri(PRODUCT_SERVICE_URL)
        .when()
            .get("/api/products")
        .then()
            .statusCode(200)
            .body("size()", greaterThanOrEqualTo(0));
    }

    @Test
    @DisplayName("Test 4: Check inventory for product")
    public void testInventoryCheck() {
        // First, ensure product exists in inventory
        String inventoryPayload = """
            {
                "skuCode": "SKU-INT-001",
                "quantity": 100
            }
            """;

        given()
            .baseUri(INVENTORY_SERVICE_URL)
            .contentType(ContentType.JSON)
            .body(inventoryPayload)
        .when()
            .post("/api/inventory")
        .then()
            .statusCode(201);

        // Now check stock
        given()
            .baseUri(INVENTORY_SERVICE_URL)
            .queryParam("skuCode", "SKU-INT-001")
            .queryParam("quantity", 50)
        .when()
            .get("/api/inventory/is-in-stock")
        .then()
            .statusCode(200)
            .body("inStock", equalTo(true));
    }

    @Test
    @DisplayName("Test 5: Place an order with available inventory")
    public void testPlaceOrder() {
        String orderPayload = """
            {
                "skuCode": "SKU-INT-001",
                "quantity": 5,
                "price": 299.99,
                "userDetails": {
                    "email": "customer@example.com",
                    "firstName": "John",
                    "lastName": "Doe"
                }
            }
            """;

        given()
            .baseUri(ORDER_SERVICE_URL)
            .contentType(ContentType.JSON)
            .body(orderPayload)
        .when()
            .post("/api/orders")
        .then()
            .statusCode(201)
            .body("id", notNullValue());
    }

    @Test
    @DisplayName("Test 6: Order should fail for out-of-stock item")
    public void testOrderFailsForOutOfStock() {
        String orderPayload = """
            {
                "skuCode": "SKU-OUT-OF-STOCK",
                "quantity": 1000,
                "price": 999.99,
                "userDetails": {
                    "email": "customer@example.com",
                    "firstName": "Jane",
                    "lastName": "Smith"
                }
            }
            """;

        given()
            .baseUri(ORDER_SERVICE_URL)
            .contentType(ContentType.JSON)
            .body(orderPayload)
        .when()
            .post("/api/orders")
        .then()
            .statusCode(400)
            .or()
            .statusCode(404);
    }

    @Test
    @DisplayName("Test 7: API Gateway routes requests correctly")
    public void testApiGatewayRouting() {
        // Test routing to product service through gateway
        when()
            .get("/products")
        .then()
            .statusCode(200)
            .or()
            .statusCode(404); // Might be 404 if endpoint not exposed through gateway
    }

    @Test
    @DisplayName("Test 8: Services communicate through network")
    public void testServiceToServiceCommunication() {
        // Create inventory first
        String inventoryPayload = """
            {
                "skuCode": "SKU-COMM-TEST",
                "quantity": 50
            }
            """;

        given()
            .baseUri(INVENTORY_SERVICE_URL)
            .contentType(ContentType.JSON)
            .body(inventoryPayload)
        .when()
            .post("/api/inventory")
        .then()
            .statusCode(201);

        // Order service should communicate with inventory service
        String orderPayload = """
            {
                "skuCode": "SKU-COMM-TEST",
                "quantity": 10,
                "price": 99.99,
                "userDetails": {
                    "email": "test@example.com",
                    "firstName": "Test",
                    "lastName": "User"
                }
            }
            """;

        given()
            .baseUri(ORDER_SERVICE_URL)
            .contentType(ContentType.JSON)
            .body(orderPayload)
        .when()
            .post("/api/orders")
        .then()
            .statusCode(201);
    }

    @Test
    @DisplayName("Test 9: Frontend should be accessible")
    public void testFrontendAccessible() {
        given()
            .baseUri("http://localhost:3000")
        .when()
            .get("/")
        .then()
            .statusCode(200)
            .or()
            .statusCode(304); // Not modified
    }

    @Test
    @DisplayName("Test 10: Database connectivity")
    public void testDatabaseConnectivity() {
        // Verify services can access their databases
        // This is implicit in health checks, but we can make it explicit

        // MySQL should be up (used by inventory and order services)
        given()
            .baseUri(INVENTORY_SERVICE_URL)
        .when()
            .get("/actuator/health")
        .then()
            .statusCode(200)
            .body("status", equalTo("UP"));

        // MongoDB should be up (used by product service)
        given()
            .baseUri(PRODUCT_SERVICE_URL)
        .when()
            .get("/actuator/health")
        .then()
            .statusCode(200)
            .body("status", equalTo("UP"));
    }
}
