#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

PROJECT_DIR="/home/josh/Malak_Josh"
BACKEND_DIR="$PROJECT_DIR/backend"

echo -e "${YELLOW}Starting microservices (without notification-service)...${NC}\n"

# Function to start a service
start_service() {
    local service=$1
    local jar=$2
    local port=$3
    
    if [ ! -f "$jar" ]; then
        echo -e "${RED}ERROR: JAR not found: $jar${NC}"
        return 1
    fi
    
    echo -e "${GREEN}Starting $service on port $port...${NC}"
    nohup java -jar "$jar" > "$PROJECT_DIR/logs/$service.log" 2>&1 &
    echo $! > "$PROJECT_DIR/logs/$service.pid"
    sleep 3
}

# Create logs directory
mkdir -p "$PROJECT_DIR/logs"

# Start services
start_service "product-service" "$BACKEND_DIR/product-service/target/product-service-1.0-SNAPSHOT.jar" "8080"
start_service "order-service" "$BACKEND_DIR/order-service/target/order-service-1.0-SNAPSHOT.jar" "8081"
start_service "inventory-service" "$BACKEND_DIR/inventory-service/target/inventory-service-1.0-SNAPSHOT.jar" "8082"
start_service "api-gateway" "$BACKEND_DIR/api-gateway/target/api-gateway-0.0.1-SNAPSHOT.jar" "9000"

sleep 5

echo -e "\n${GREEN}Services started!${NC}"
echo -e "${YELLOW}Service URLs:${NC}"
echo "  Product Service: http://localhost:8080/swagger-ui.html"
echo "  Order Service: http://localhost:8081/swagger-ui.html"
echo "  Inventory Service: http://localhost:8082/swagger-ui.html"
echo "  API Gateway: http://localhost:9000/swagger-ui.html"
echo "  Frontend: http://localhost:4200"
echo -e "\n${YELLOW}Infrastructure:${NC}"
echo "  Kafka UI: http://localhost:8086"
echo "  Grafana: http://localhost:3000"
echo "  Prometheus: http://localhost:9090"
echo -e "\n${YELLOW}Status:${NC}"
ps aux | grep "java -jar" | grep -v grep
