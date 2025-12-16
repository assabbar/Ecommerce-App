# E-Commerce Microservices - Test Suite

## Overview

This project includes comprehensive unit tests and integration tests following professional DevOps practices.

### Test Structure

```
Unit Tests (CI - runs in Jenkins)
├── Product Service - ProductServiceTest.java (5 test cases)
├── Order Service - OrderServiceTest.java (5 test cases)
├── Inventory Service - InventoryServiceTest.java (7 test cases)
├── Notification Service - NotificationServiceTest.java (6 test cases)
├── API Gateway - ApiGatewayApplicationTest.java (2 test cases)
└── Frontend - app.component.spec.ts (6 test cases)

Integration Tests (Manual/Local - full stack)
└── FullStackIntegrationTest.java (10 test cases)
```

## Unit Tests

All unit tests use **Mockito** for mocking dependencies. No external services required.

### Backend Unit Tests

**Location:** `backend/[service]/src/test/java/com/techie/microservices/[service]/service/`

#### Product Service Tests
```bash
mvn test -pl product-service -Dtest=ProductServiceTest
```
- ✓ Create product with valid data
- ✓ Get all products
- ✓ Get product by ID (success)
- ✓ Get product by ID (not found)
- ✓ Delete product

#### Order Service Tests
```bash
mvn test -pl order-service -Dtest=OrderServiceTest
```
- ✓ Place order when product in stock → saves order + sends Kafka message
- ✓ Place order when product out of stock → throws exception
- ✓ Order when inventory client fails → throws exception
- ✓ Order with large quantity → calculates price correctly
- ✓ Order with minimum quantity → succeeds

#### Inventory Service Tests
```bash
mvn test -pl inventory-service -Dtest=InventoryServiceTest
```
- ✓ Check stock when product available with sufficient quantity
- ✓ Check stock when product not available
- ✓ Check stock with zero quantity
- ✓ Check stock with large quantity request
- ✓ Check stock with different SKU codes
- ✓ Check stock with null SKU code → throws exception
- ✓ Check stock with negative quantity

#### Notification Service Tests
```bash
mvn test -pl notification-service -Dtest=NotificationServiceTest
```
- ✓ Send email when order placed event received
- ✓ Throw exception when email sending fails
- ✓ Send email with valid order event
- ✓ Send email for multiple events
- ✓ Handle null event
- ✓ Handle empty email address

#### API Gateway Tests
```bash
mvn test -pl api-gateway -Dtest=ApiGatewayApplicationTest
```
- ✓ Context loads successfully
- ✓ Gateway responds to health check

### Frontend Unit Tests

**Location:** `frontend/src/app/app.component.spec.ts`

```bash
cd frontend
npm test -- --watch=false --code-coverage --browsers=ChromeHeadless
```

Test cases:
- ✓ Create the app component
- ✓ Have correct title "microservices-shop-frontend"
- ✓ Check authentication on init (authenticated)
- ✓ Handle unauthenticated state
- ✓ Render header component
- ✓ Have router outlet for navigation

## Running All Unit Tests

### Backend Unit Tests
```bash
cd backend
mvn test -Dtest=*ServiceTest
```

### Frontend Unit Tests
```bash
cd frontend
npm test -- --watch=false --code-coverage --browsers=ChromeHeadless
```

## Integration Tests

Full stack integration tests verify service-to-service communication and end-to-end workflows.

### Prerequisites

All services running with their dependencies:

```bash
docker-compose -f docker-compose.test.yml up
```

This starts:
- MySQL, MongoDB, Kafka
- All 5 backend services
- Frontend
- MailHog (for email testing)

### Run Integration Tests

```bash
cd backend
mvn test -pl order-service -Dtest=FullStackIntegrationTest
```

Or use the provided script:

```bash
./test-integration.sh
```

### Integration Test Cases

1. **Test 1:** All services healthy and running
   - Verifies product, inventory, order, notification services and API gateway are UP

2. **Test 2:** Create a product successfully
   - POST `/api/products` → 201 Created

3. **Test 3:** Retrieve all products
   - GET `/api/products` → 200 OK

4. **Test 4:** Check inventory for product
   - Verify stock check returns correct availability

5. **Test 5:** Place an order with available inventory
   - Order placed → Saved to database + Kafka message sent

6. **Test 6:** Order fails for out-of-stock item
   - Order with unavailable product → 400/404 error

7. **Test 7:** API Gateway routes requests correctly
   - Gateway properly routes to backend services

8. **Test 8:** Services communicate through network
   - Order service calls Inventory service via Docker network

9. **Test 9:** Frontend is accessible
   - GET `/` → 200 OK

10. **Test 10:** Database connectivity
    - MySQL and MongoDB are accessible from services

## CI/CD Pipeline (Jenkins)

### Pipeline Stages

1. **Checkout** - Pull code from GitHub (5 min timeout)
2. **Backend Compilation** - `mvn clean compile` (30 min timeout)
3. **Unit Tests** - Run all unit tests with mocks (30 min timeout)
4. **Integration Tests** - Informational display (skipped in CI)
5. **Build Docker Images** - Build 6 service images (60 min timeout)

### Overall Timeout
180 minutes (3 hours)

### Running Jenkins Pipeline

```bash
# Build from GitHub
git push origin main
# Jenkins automatically triggers on push

# Or manually trigger in Jenkins UI
# Job: E-Commerce-Pipeline
```

## Test Best Practices Applied

✅ **Unit Tests** - Use Mocks (Mockito)
- No database dependencies
- No external service calls
- Fast execution (< 1 min for all backend unit tests)
- Isolated test cases

✅ **Integration Tests** - Full Stack
- Verify service-to-service communication
- Test with real databases (via docker-compose)
- Test Kafka messaging
- Test end-to-end workflows

✅ **CI/CD Practices**
- Unit tests run in CI pipeline
- Integration tests run separately (require full stack)
- Per-stage timeouts to prevent hanging
- Clear error messages and logging
- Retry logic for Docker builds

## Debugging Failed Tests

### Backend Unit Test Failures
```bash
# Run with verbose output
mvn test -pl order-service -Dtest=OrderServiceTest -X

# Run single test
mvn test -pl order-service -Dtest=OrderServiceTest#placeOrder_WhenProductInStock_ShouldSaveOrderAndSendKafkaMessage
```

### Frontend Test Failures
```bash
# Run with debug logging
ng test --watch=true --browsers=Chrome

# Check karma configuration
cat karma.conf.js
```

### Integration Test Failures
```bash
# Check service logs
docker logs order-service
docker logs inventory-service
docker logs kafka

# Check database connectivity
docker exec mysql mysql -u root -pmysql -e "SELECT 1;"
docker exec mongodb mongosh --eval "db.adminCommand('ping')"
```

## Test Coverage

To generate coverage reports:

### Backend
```bash
mvn clean test jacoco:report
# Report: target/site/jacoco/index.html
```

### Frontend
```bash
ng test --code-coverage
# Report: coverage/
```

## Adding New Tests

### New Backend Unit Test
1. Create `YourServiceTest.java` in `src/test/java/...`
2. Use `@ExtendWith(MockitoExtension.class)`
3. Mock dependencies with `@Mock`
4. Inject into service with `@InjectMocks`
5. Write test cases with assertions and verify mock calls

Example:
```java
@ExtendWith(MockitoExtension.class)
class YourServiceTest {
    @Mock
    private YourRepository repository;
    
    @InjectMocks
    private YourService service;
    
    @Test
    void testYourScenario() {
        when(repository.findById(1)).thenReturn(/* mock data */);
        // Act & Assert
    }
}
```

### New Frontend Unit Test
1. Add test case to `app.component.spec.ts` or create new `.spec.ts`
2. Use TestBed for component testing
3. Mock services with jasmine.createSpyObj()
4. Test component lifecycle and user interactions

## Continuous Improvement

- Regularly review test coverage reports
- Add tests for new features before implementation (TDD)
- Refactor tests to reduce duplication
- Update tests when requirements change
- Monitor test execution time and optimize slow tests

## References

- [Mockito Documentation](https://javadoc.io/doc/org.mockito/mockito-core/latest/org/mockito/Mockito.html)
- [Angular Testing Guide](https://angular.io/guide/testing)
- [JUnit 5 User Guide](https://junit.org/junit5/docs/current/user-guide/)
- [RestAssured Documentation](https://rest-assured.io/)
