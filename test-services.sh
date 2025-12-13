#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}    MICROSERVICES TEST SUITE${NC}"
echo -e "${BLUE}========================================${NC}\n"

# Function to test a service
test_service() {
    local service=$1
    local url=$2
    local port=$3
    
    echo -ne "${YELLOW}Testing $service...${NC} "
    
    response=$(curl -s -o /dev/null -w "%{http_code}" "$url")
    
    if [ "$response" = "200" ] || [ "$response" = "201" ]; then
        echo -e "${GREEN}✓ OK (Status: $response)${NC}"
        return 0
    else
        echo -e "${RED}✗ FAILED (Status: $response)${NC}"
        return 1
    fi
}

# Function to test endpoint
test_endpoint() {
    local name=$1
    local method=$2
    local url=$3
    local data=$4
    
    echo -ne "${YELLOW}Test: $name...${NC} "
    
    if [ -z "$data" ]; then
        response=$(curl -s -X "$method" "$url" -H "Content-Type: application/json" -w "\n%{http_code}")
    else
        response=$(curl -s -X "$method" "$url" -H "Content-Type: application/json" -d "$data" -w "\n%{http_code}")
    fi
    
    http_code=$(echo "$response" | tail -1)
    body=$(echo "$response" | head -n -1)
    
    if [ "$http_code" = "200" ] || [ "$http_code" = "201" ]; then
        echo -e "${GREEN}✓ OK${NC}"
        echo "$body" | jq . 2>/dev/null || echo "$body"
        return 0
    else
        echo -e "${RED}✗ FAILED (Status: $http_code)${NC}"
        echo "$body"
        return 1
    fi
}

# Test Health Checks
echo -e "${BLUE}1. Testing Health Checks${NC}"
echo "============================="
test_service "Product Service" "http://localhost:8080/actuator/health" "8080"
test_service "Order Service" "http://localhost:8081/actuator/health" "8081"
test_service "Inventory Service" "http://localhost:8082/actuator/health" "8082"
test_service "API Gateway" "http://localhost:9000/actuator/health" "9000"
test_service "Frontend" "http://localhost:4200" "4200"

echo -e "\n${BLUE}2. Testing Infrastructure${NC}"
echo "============================="
test_service "MongoDB" "http://localhost:27017" "27017" &
test_service "MySQL" "http://localhost:3306" "3306" &
test_service "Kafka UI" "http://localhost:8086" "8086"
test_service "Grafana" "http://localhost:3000" "3000"

echo -e "\n${BLUE}3. Testing Product Service APIs${NC}"
echo "================================="

# Get all products
test_endpoint "GET all products" "GET" "http://localhost:8080/api/product"

# Create a product
echo -e "\n${YELLOW}Creating a test product...${NC}"
PRODUCT_DATA='{
  "name": "Test Laptop",
  "description": "A powerful test laptop",
  "price": 1299.99
}'

test_endpoint "POST new product" "POST" "http://localhost:8080/api/product" "$PRODUCT_DATA"

echo -e "\n${BLUE}4. Testing Inventory Service APIs${NC}"
echo "===================================="

# Create inventory entry
echo -e "\n${YELLOW}Creating inventory entry...${NC}"
INVENTORY_DATA='{
  "skuCode": "TEST-LAPTOP-001",
  "quantity": 100
}'

test_endpoint "POST inventory" "POST" "http://localhost:8082/api/inventory" "$INVENTORY_DATA"

# Check stock
echo -e "\n${YELLOW}Checking stock availability...${NC}"
test_endpoint "GET inventory" "GET" "http://localhost:8082/api/inventory/TEST-LAPTOP-001"

echo -e "\n${BLUE}5. Testing Order Service APIs${NC}"
echo "================================"

# Create an order
echo -e "\n${YELLOW}Creating a test order...${NC}"
ORDER_DATA='{
  "orderLineItemsList": [
    {
      "skuCode": "TEST-LAPTOP-001",
      "price": 1299.99,
      "quantity": 2
    }
  ]
}'

test_endpoint "POST new order" "POST" "http://localhost:8081/api/order" "$ORDER_DATA"

# Get all orders
echo -e "\n${YELLOW}Retrieving all orders...${NC}"
test_endpoint "GET all orders" "GET" "http://localhost:8081/api/order"

echo -e "\n${BLUE}6. Testing API Gateway${NC}"
echo "======================="

test_endpoint "Gateway - GET products" "GET" "http://localhost:9000/api/product"
test_endpoint "Gateway - GET orders" "GET" "http://localhost:9000/api/order"
test_endpoint "Gateway - GET inventory" "GET" "http://localhost:9000/api/inventory"

echo -e "\n${BLUE}7. Swagger Documentation${NC}"
echo "=========================="
test_service "Product Service Swagger" "http://localhost:8080/swagger-ui.html" "8080"
test_service "Order Service Swagger" "http://localhost:8081/swagger-ui.html" "8081"
test_service "Inventory Service Swagger" "http://localhost:8082/swagger-ui.html" "8082"
test_service "API Gateway Swagger" "http://localhost:9000/swagger-ui.html" "9000"

echo -e "\n${BLUE}8. Metrics and Monitoring${NC}"
echo "=========================="
test_service "Prometheus" "http://localhost:9090" "9090"
test_service "Grafana" "http://localhost:3000" "3000"

echo -e "\n${BLUE}========================================${NC}"
echo -e "${GREEN}Test Suite Complete!${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "\n${YELLOW}Service URLs:${NC}"
echo "  Frontend: http://localhost:4200"
echo "  Product Service: http://localhost:8080"
echo "  Order Service: http://localhost:8081"
echo "  Inventory Service: http://localhost:8082"
echo "  API Gateway: http://localhost:9000"
echo ""
echo -e "${YELLOW}Documentation:${NC}"
echo "  See TESTING_GUIDE.md for detailed testing instructions"
