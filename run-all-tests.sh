#!/bin/bash

# Script to run all tests (Backend + Frontend)

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}Running All Tests (Backend + Frontend)${NC}"
echo -e "${YELLOW}========================================${NC}\n"

# Test Backend
echo -e "${YELLOW}[1/2] Running Backend Tests...${NC}\n"
cd backend

echo -e "${YELLOW}Running Product Service Tests...${NC}"
mvn test -pl product-service -DskipITs || { echo -e "${RED}Product Service tests failed${NC}"; exit 1; }

echo -e "${YELLOW}Running Order Service Tests...${NC}"
mvn test -pl order-service -DskipITs || { echo -e "${RED}Order Service tests failed${NC}"; exit 1; }

echo -e "${YELLOW}Running Inventory Service Tests...${NC}"
mvn test -pl inventory-service -DskipITs || { echo -e "${RED}Inventory Service tests failed${NC}"; exit 1; }

echo -e "${YELLOW}Running Notification Service Tests...${NC}"
mvn test -pl notification-service -DskipITs || { echo -e "${RED}Notification Service tests failed${NC}"; exit 1; }

echo -e "${GREEN}✓ All Backend Tests Passed!${NC}\n"

# Test Frontend
echo -e "${YELLOW}[2/2] Running Frontend Tests...${NC}\n"
cd ../frontend

npm test -- --watch=false --browsers=ChromeHeadless || { echo -e "${RED}Frontend tests failed${NC}"; exit 1; }

echo -e "${GREEN}✓ Frontend Tests Passed!${NC}\n"

# Summary
echo -e "${YELLOW}========================================${NC}"
echo -e "${GREEN}✓ All Tests Completed Successfully!${NC}"
echo -e "${YELLOW}========================================${NC}\n"

echo -e "${YELLOW}Test Coverage Reports:${NC}"
echo "Backend: cd backend && mvn jacoco:report"
echo "Frontend: cd frontend && npm test -- --code-coverage"
