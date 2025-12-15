.PHONY: help build start stop logs clean docker-up docker-down frontend backend

# Colors
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[1;33m
NC := \033[0m # No Color

PROJECT_DIR := $(shell pwd)
BACKEND_DIR := $(PROJECT_DIR)/backend
FRONTEND_DIR := $(PROJECT_DIR)/frontend
LOGS_DIR := $(PROJECT_DIR)/logs

help:
	@echo "$(YELLOW)E-Commerce Microservices - Available Commands:$(NC)"
	@echo ""
	@echo "$(GREEN)Docker:$(NC)"
	@echo "  make docker-up         - Start all services with Docker Compose"
	@echo "  make docker-down       - Stop all Docker services"
	@echo "  make docker-logs       - View Docker logs"
	@echo ""
	@echo "$(GREEN)Backend (Java/Maven):$(NC)"
	@echo "  make backend-build     - Build all microservices"
	@echo "  make backend-start     - Start microservices (requires JAR files)"
	@echo "  make backend-stop      - Stop all microservices"
	@echo ""
	@echo "$(GREEN)Frontend (Angular):$(NC)"
	@echo "  make frontend-install  - Install Angular dependencies"
	@echo "  make frontend-start    - Start Angular development server"
	@echo ""
	@echo "$(GREEN)Combined:$(NC)"
	@echo "  make start             - Start everything (Docker + Frontend)"
	@echo "  make stop              - Stop everything"
	@echo "  make clean             - Clean all generated files"
	@echo ""

# Docker Commands
docker-up:
	@echo "$(YELLOW)Starting Docker services...$(NC)"
	docker-compose up -d
	@echo "$(GREEN)Docker services started!$(NC)"
	@echo ""
	@echo "$(YELLOW)Service URLs:$(NC)"
	@echo "  MongoDB:     mongodb://localhost:27017"
	@echo "  MySQL:       localhost:3306"
	@echo "  Kafka UI:    http://localhost:8086"
	@echo "  Grafana:     http://localhost:3000"
	@echo "  Prometheus:  http://localhost:9090"
	@echo "  Keycloak:    http://localhost:8080"

docker-down:
	@echo "$(YELLOW)Stopping Docker services...$(NC)"
	docker-compose down
	@echo "$(GREEN)Docker services stopped!$(NC)"

docker-logs:
	docker-compose logs -f

docker-ps:
	docker-compose ps

# Backend Commands
backend-build:
	@echo "$(YELLOW)Building backend services...$(NC)"
	cd $(BACKEND_DIR) && mvn clean package -DskipTests
	@echo "$(GREEN)Backend built successfully!$(NC)"

backend-start: backend-build
	@echo "$(YELLOW)Starting microservices...$(NC)"
	@mkdir -p $(LOGS_DIR)
	@echo "$(GREEN)Services starting in background. Check logs in $(LOGS_DIR)$(NC)"
	@echo ""
	@echo "$(YELLOW)Service URLs:$(NC)"
	@echo "  Product Service:    http://localhost:8080/swagger-ui.html"
	@echo "  Order Service:      http://localhost:8081/swagger-ui.html"
	@echo "  Inventory Service:  http://localhost:8082/swagger-ui.html"
	@echo "  API Gateway:        http://localhost:9000/swagger-ui.html"

backend-stop:
	@echo "$(YELLOW)Stopping microservices...$(NC)"
	@pkill -f "java -jar.*product-service" || true
	@pkill -f "java -jar.*order-service" || true
	@pkill -f "java -jar.*inventory-service" || true
	@pkill -f "java -jar.*api-gateway" || true
	@echo "$(GREEN)Microservices stopped!$(NC)"

# Frontend Commands
frontend-install:
	@echo "$(YELLOW)Installing Angular dependencies...$(NC)"
	cd $(FRONTEND_DIR) && npm install
	@echo "$(GREEN)Angular dependencies installed!$(NC)"

frontend-start: frontend-install
	@echo "$(YELLOW)Starting Angular dev server...$(NC)"
	@echo "$(GREEN)Frontend will be available at http://localhost:4200$(NC)"
	cd $(FRONTEND_DIR) && npm run start

frontend-build:
	@echo "$(YELLOW)Building Angular project...$(NC)"
	cd $(FRONTEND_DIR) && npm run build
	@echo "$(GREEN)Angular build complete!$(NC)"

# Combined Commands
start: docker-up frontend-start
	@echo "$(GREEN)All services started!$(NC)"

stop: docker-down backend-stop
	@echo "$(GREEN)All services stopped!$(NC)"

clean:
	@echo "$(YELLOW)Cleaning project...$(NC)"
	rm -rf $(LOGS_DIR)
	cd $(BACKEND_DIR) && mvn clean
	cd $(FRONTEND_DIR) && rm -rf node_modules dist
	@echo "$(GREEN)Project cleaned!$(NC)"

status:
	@echo "$(YELLOW)Docker Services:$(NC)"
	@docker-compose ps || echo "No Docker services running"
	@echo ""
	@echo "$(YELLOW)Java Processes:$(NC)"
	@ps aux | grep java | grep -v grep || echo "No Java processes running"

# Development commands
dev-backend:
	cd $(BACKEND_DIR) && mvn spring-boot:run -pl api-gateway

dev-product:
	cd $(BACKEND_DIR) && mvn spring-boot:run -pl product-service

dev-order:
	cd $(BACKEND_DIR) && mvn spring-boot:run -pl order-service

dev-inventory:
	cd $(BACKEND_DIR) && mvn spring-boot:run -pl inventory-service

.DEFAULT_GOAL := help
