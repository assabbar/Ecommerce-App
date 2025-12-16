#!/bin/bash

# Integration Test Script
# Tests the complete microservices stack
# Prerequisites: docker-compose.test.yml running

echo "====== Full Stack Integration Tests ======"
echo "Starting integration tests for complete microservices stack..."
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
API_GATEWAY_URL="http://localhost:9000"
PRODUCT_SERVICE_URL="http://localhost:8080"
INVENTORY_SERVICE_URL="http://localhost:8082"
ORDER_SERVICE_URL="http://localhost:8081"
NOTIFICATION_SERVICE_URL="http://localhost:8083"
FRONTEND_URL="http://localhost:3000"
MAX_RETRIES=30
RETRY_DELAY=2

echo "Checking if docker-compose stack is running..."
echo ""

# Function to check service health
check_service_health() {
    local url=$1
    local service_name=$2
    local retries=0
    
    while [ $retries -lt $MAX_RETRIES ]; do
        response=$(curl -s -o /dev/null -w "%{http_code}" "$url/actuator/health" 2>/dev/null || echo "000")
        
        if [ "$response" = "200" ]; then
            echo -e "${GREEN}✓${NC} $service_name is UP"
            return 0
        fi
        
        retries=$((retries + 1))
        sleep $RETRY_DELAY
    done
    
    echo -e "${RED}✗${NC} $service_name is DOWN or unreachable"
    return 1
}

# Check all services
check_service_health "$PRODUCT_SERVICE_URL" "Product Service"
check_service_health "$INVENTORY_SERVICE_URL" "Inventory Service"
check_service_health "$ORDER_SERVICE_URL" "Order Service"
check_service_health "$NOTIFICATION_SERVICE_URL" "Notification Service"
check_service_health "$API_GATEWAY_URL" "API Gateway"

echo ""
echo "Running integration tests..."
echo ""

cd backend

# Run integration tests
mvn test \
  -pl order-service \
  -Dtest=FullStackIntegrationTest \
  -Dorg.slf4j.simpleLogger.defaultLogLevel=warn \
  -q

TEST_EXIT_CODE=$?

echo ""
echo "================================================"

if [ $TEST_EXIT_CODE -eq 0 ]; then
    echo -e "${GREEN}✅ Full Stack Integration Tests PASSED${NC}"
    echo "================================================"
    echo "All microservices are working correctly:"
    echo "  ✓ Service-to-service communication"
    echo "  ✓ Database connectivity"
    echo "  ✓ Message queue (Kafka)"
    echo "  ✓ API Gateway routing"
    echo ""
    exit 0
else
    echo -e "${RED}❌ Full Stack Integration Tests FAILED${NC}"
    echo "================================================"
    echo "Check the logs above for details."
    echo ""
    exit 1
fi
