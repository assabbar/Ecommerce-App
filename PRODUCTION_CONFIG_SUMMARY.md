# ✅ CONFIGURATIONS PRODUCTION CRÉÉES

## 📋 Résumé des Modifications pour Production

### 1️⃣ **Application Properties Créées**

#### Product Service (MongoDB/CosmosDB)
- **File**: `backend/product-service/src/main/resources/application-production.properties`
- **Configuration**:
  - Spring Profile: `production`
  - MongoDB URI: `${COSMOSDB_URI}` (CosmosDB)
  - Database: `ecom-mongo-db`
  - Collections: 
    - `product` (Produits)
    - `users` (Utilisateurs/Auth)
  - Connection pooling: 50 max, 10 min
  - Monitoring: Prometheus + Loki

#### Order Service (MySQL)
- **File**: `backend/order-service/src/main/resources/application-production.properties`
- **Configuration**:
  - Spring Profile: `production`
  - MySQL Host: Azure MySQL Flexible Server
  - Database: `ecom_order_db`
  - Table: `t_orders`
  - Kafka: Azure Event Hub
  - HikariCP Connection Pool
  - Monitoring: Prometheus + Loki

#### Inventory Service (MySQL)
- **File**: `backend/inventory-service/src/main/resources/application-production.properties`
- **Configuration**:
  - Spring Profile: `production`
  - MySQL Host: Azure MySQL Flexible Server
  - Database: `ecom_inventory_db`
  - Table: `t_inventory`
  - HikariCP Connection Pool
  - Monitoring: Prometheus + Loki

#### Notification Service
- **File**: `backend/notification-service/src/main/resources/application-production.properties`
- **Configuration**:
  - Spring Profile: `production`
  - Kafka: Azure Event Hub
  - Email: SendGrid SMTP
  - Monitoring: Prometheus + Loki

---

### 2️⃣ **Helm Values Production Créées**

#### Product Service
- **File**: `Devops/helm/product-service/values-production.yaml`
- **Features**:
  - LoadBalancer Service (public IP)
  - 2-5 replicas (autoscaling)
  - CosmosDB secrets injected
  - Liveness & Readiness probes
  - Prometheus annotations
  - Upload volume

#### Order Service
- **File**: `Devops/helm/order-service/values-production.yaml`
- **Features**:
  - ClusterIP Service (internal)
  - 2-5 replicas (autoscaling)
  - MySQL secrets injected
  - Event Hub configuration
  - Prometheus metrics

#### Inventory Service
- **File**: `Devops/helm/inventory-service/values-production.yaml`
- **Features**:
  - ClusterIP Service (internal)
  - 2-5 replicas (autoscaling)
  - MySQL secrets injected
  - Prometheus metrics

#### Notification Service
- **File**: `Devops/helm/notification-service/values-production.yaml`
- **Features**:
  - ClusterIP Service (internal)
  - 2-5 replicas (autoscaling)
  - Event Hub configuration
  - SendGrid credentials
  - Prometheus metrics

#### API Gateway
- **File**: `Devops/helm/api-gateway/values-production.yaml`
- **Features**:
  - LoadBalancer Service (port 9000, public IP)
  - 2-5 replicas (autoscaling)
  - Routes to all backend services

#### Frontend
- **File**: `Devops/helm/frontend/values-production.yaml`
- **Features**:
  - LoadBalancer Service (port 80, public IP)
  - 2-4 replicas (autoscaling)
  - API Gateway URL injected

---

### 3️⃣ **Script Deploy-AKS Modifié**

**File**: `Devops/scripts/deploy-aks.sh`

**Additions**:
- Section 3.5: Database Credentials Secrets
  - CosmosDB credentials retrieval:
    - Host
    - Username
    - Password (Primary Key)
    - Connection URI
  - MySQL credentials retrieval:
    - Host (FQDN)
    - Username
    - Password
    - JDBC URL
  - Kubernetes Secrets creation:
    - `cosmosdb-credentials` in backend & monitoring namespaces
    - `mysql-credentials` in backend namespace

---

## 🚀 Architecture Production

```
Clients
  ↓
Frontend (LoadBalancer: port 80)
  ↓
API Gateway (LoadBalancer: port 9000)
  ↓
┌─────────────────────────────────────────┐
│         Backend Services (ClusterIP)    │
├─────────────────────────────────────────┤
│ Product Service  ────→ CosmosDB (MongoDB) │
│ Order Service    ────→ MySQL (ecom_order_db) │
│ Inventory Service ─→ MySQL (ecom_inventory_db) │
│ Notification Service → Event Hub (Kafka) │
└─────────────────────────────────────────┘
  ↓
Monitoring Stack
├─ Prometheus (metrics)
├─ Grafana (visualization)
├─ Loki (logs)
└─ AlertManager (alerting)
```

---

## 📊 Database Strategy

### **CosmosDB (MongoDB API)**
- **Databases**: `ecom-mongo-db`
- **Collections**:
  - `product` - Product catalog (from Product Service)
  - `users` - User authentication & profiles (from Product Service)
- **Why MongoDB**: 
  - Flexible schema (products with varied attributes)
  - User profiles with dynamic fields
  - Good performance for catalog reads

### **MySQL**
- **Databases**: 
  - `ecom_order_db` - Orders (Order Service)
  - `ecom_inventory_db` - Inventory (Inventory Service)
- **Why Relational**:
  - Orders need ACID transactions
  - Inventory requires strict consistency
  - Foreign key relationships

### **Event Hub (Kafka)**
- **Topics**:
  - `orders` - Order events
  - `notifications` - Notification events
  - `inventory` - Stock updates
- **Consumers**:
  - Notification Service (send emails/SMS)
  - Order Service (process events)

---

## 🔐 Security

### Secrets Management
- CosmosDB URI (with credentials): K8s Secret
- MySQL credentials: K8s Secret
- SendGrid API Key: K8s Secret
- ACR credentials: K8s Secret (docker-registry)

### Network
- Frontend & API Gateway: Public IPs (LoadBalancer)
- Backend services: Internal (ClusterIP)
- Database access: Private endpoints (via Terraform)

---

## ✅ Checklist Avant Build

- [ ] `application-production.properties` created for all 4 services
- [ ] `values-production.yaml` created for all 6 microservices
- [ ] `deploy-aks.sh` modified to create CosmosDB & MySQL secrets
- [ ] `setup-azure-jenkins.sh` executed (generates jenkins.env)
- [ ] K8s secrets `cosmosdb-credentials` and `mysql-credentials` exist
- [ ] Docker images in ACR for all services
- [ ] Helm values configured with correct namespaces

---

## 🎯 Déploiement Steps

1. **Run setup script**:
   ```bash
   bash setup-azure-jenkins.sh
   ```

2. **Start Jenkins**:
   ```bash
   docker compose -f Devops/jenkins/docker-compose.yml up -d
   ```

3. **Create Pipeline & Build**:
   - Jenkins UI → New Item → Pipeline
   - Jenkinsfile path: `Devops/jenkins/Jenkinsfile`
   - Build Now

4. **Verify Deployment**:
   ```bash
   # Check pods
   kubectl get pods -n backend
   kubectl get pods -n frontend
   
   # Check services
   kubectl get svc -n backend
   kubectl get svc -n frontend
   
   # Check secrets
   kubectl get secrets -n backend
   ```

5. **Verify CosmosDB Usage**:
   ```bash
   # Check logs for MongoDB connection
   kubectl logs deployment/product-service -n backend | grep -i mongo
   
   # Test Product API
   kubectl port-forward svc/product-service 8080:80 -n backend &
   curl http://localhost:8080/api/product
   ```

6. **Verify MySQL Usage**:
   ```bash
   # Check logs for MySQL connection
   kubectl logs deployment/order-service -n backend | grep -i mysql
   ```

---

## 📈 Monitoring

All services are configured with:
- **Prometheus metrics** on `/actuator/prometheus`
- **Loki logs** shipped to `http://loki:3100`
- **Health checks** on `/actuator/health/liveness` and `/actuator/health/readiness`
- **Grafana dashboards** pre-configured

Access Grafana:
```bash
kubectl port-forward svc/grafana 3000:80 -n monitoring
# Browser: http://localhost:3000
# Login: admin/admin
```

---

## 🔄 Environment Variables Flow

```
Jenkins (Devops/jenkins/jenkins.env)
  ↓ (sourced by Jenkinsfile)
Docker Build (BuildKit)
  ↓ (Docker image)
Docker Push (to ACR)
  ↓ (Image registry)
Helm Deploy (with values-production.yaml)
  ↓ (Kubernetes deployment)
K8s Secrets Creation
  ↓ (cosmosdb-credentials, mysql-credentials)
Pod Environment Variables
  ↓ (${COSMOSDB_URI}, ${MYSQL_JDBC_URL})
Spring Boot Application
  ↓ (Reads from environment)
application-production.properties
  ↓ (Resolved at runtime)
MongoDB/MySQL Connection
  ↓
Application Running ✅
```

---

**Status**: ✅ All configurations ready for production deployment!
