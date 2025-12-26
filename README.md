# E-Commerce Platform

**Plateforme e-commerce microservices complète déployée sur Azure Kubernetes Service (AKS)**

---

## 📋 Table des matières

- [Vue d'ensemble](#vue-densemble)
- [Architecture](#architecture)
- [Technologies](#technologies)
- [Prérequis](#prérequis)
- [Installation](#installation)
- [Structure du projet](#structure-du-projet)
- [Microservices](#microservices)
- [Base de données](#base-de-données)
- [API & Endpoints](#api--endpoints)
- [Déploiement](#déploiement)
- [Infrastructure as Code](#infrastructure-as-code)
- [CI/CD Pipeline](#cicd-pipeline)
- [Tests](#tests)
- [Monitoring & Logging](#monitoring--logging)
- [Documentation](#documentation)

---

## 📌 Vue d'ensemble

**E-Commerce Platform** est une application e-commerce moderne basée sur une architecture microservices avec:

- **5 microservices Java 21** (Spring Boot 3)
- **Frontend Angular 18** responsive
- **Kubernetes (AKS)** pour orchestration
- **Azure cloud services** pour infrastructure complète
- **CI/CD automatisé** avec Jenkins
- **Monitoring en temps réel** (Prometheus, Grafana, Loki)
- **Terraform** pour Infrastructure as Code

### Objectifs clés
✅ Scalabilité horizontale automatique  
✅ Résilience & haute disponibilité  
✅ Séparation des responsabilités  
✅ Déploiement automated  
✅ Observabilité complète  

---

## 🏗️ Architecture

### Vue globale

```
Client (Browser)
    ↓
Frontend (Angular 18) - Kubernetes Pod
    ↓
Ingress NGINX Controller
    ↓
API Gateway (LoadBalancer) - Spring Boot 3
    ↓
Microservices (5 services) - Kubernetes Pods
    ↓
Azure Resources
├── MySQL (Orders, Inventory, Users, Notifications)
├── Cosmos DB MongoDB (Products)
├── Storage Account (Images)
├── Event Hubs (Async messaging)
└── Key Vault (Secrets)
```

### Composants principaux

| Composant | Technologie | Rôle |
|-----------|-------------|------|
| **Frontend** | Angular 18, Nginx | Interface utilisateur |
| **API Gateway** | Spring Boot 3, Java 21 | Point d'entrée API |
| **Microservices** | Spring Boot 3, Java 21 | Logique métier |
| **Orchestration** | Kubernetes (AKS) | Gestion containers |
| **Bases de données** | MySQL, Cosmos DB | Persistance |
| **Messaging** | Event Hubs | Communication async |
| **Infrastructure** | Terraform | Provisioning Azure |
| **CI/CD** | Jenkins | Automation |

---

## 🛠️ Technologies

### Backend
- **Java 21** - Langage principal
- **Spring Boot 3.2.x** - Framework web
- **Spring Cloud** - Services distribués
- **Spring Data JPA** - ORM MySQL
- **Spring Data MongoDB** - Cosmos DB client
- **Spring Cloud Stream** - Event Hubs integration
- **Maven 3.9.x** - Build tool

### Frontend
- **Angular 18** - Framework web
- **TypeScript** - Language
- **Tailwind CSS** - Styling
- **RxJS** - Reactive programming
- **Nginx** - Web server

### Infrastructure
- **Docker** - Containerization
- **Kubernetes (AKS)** - Orchestration
- **Azure** - Cloud provider
- **Terraform** - IaC
- **Helm** - K8s package manager

### Monitoring
- **Prometheus** - Metrics collection
- **Grafana** - Visualization
- **Loki** - Log aggregation
- **Tempo** - Distributed tracing
- **Application Insights** - Azure monitoring

### CI/CD
- **Jenkins** - Automation server
- **Docker Hub / ACR** - Image registry
- **GitOps** - Infrastructure as Code

---

## 📋 Prérequis

### Développement local
- **Java 21 JDK** (OpenJDK ou Eclipse Temurin)
- **Maven 3.9.x** ou Gradle 8.x
- **Node.js 20+** & npm/yarn
- **Docker Desktop** (pour tests locaux)
- **Git** pour version control

### Déploiement Azure
- **Abonnement Azure** actif
- **Azure CLI** (`az` command)
- **kubectl** (Kubernetes CLI)
- **Helm 3.x**
- **Terraform 1.6+**

### Outils recommandés
- **VS Code** avec extensions Java/Angular
- **Postman** pour API testing
- **Azure Storage Explorer** pour blob management

---

## 🚀 Installation

### 1. Cloner le repository

```bash
git clone https://github.com/your-org/ecommerce-platform.git
cd ecommerce-platform
```

### 2. Backend - Maven Build

```bash
cd backend
mvn clean install
```

### 3. Frontend - Node Setup

```bash
cd frontend
npm install
npm run build
```

### 4. Docker - Build images

```bash
# Chaque service
cd backend/api-gateway
docker build -t ecommerce/api-gateway:latest .

cd backend/product-service
docker build -t ecommerce/product-service:latest .

# ... (faire pareil pour les autres services)

# Frontend
cd frontend
docker build -t ecommerce/angular-app:latest .
```

### 5. Kubernetes - Deploy locally

```bash
# Démarrer minikube ou Docker Desktop K8s
minikube start

# Créer namespaces
kubectl create namespace backend
kubectl create namespace frontend

# Appliquer ConfigMaps & Secrets
kubectl apply -f k8s/configmaps/ -n backend
kubectl apply -f k8s/secrets/ -n backend

# Déployer services
kubectl apply -f k8s/deployments/ -n backend
kubectl apply -f k8s/deployments/ -n frontend
```

---

## 📁 Structure du projet

```
ecommerce-platform/
├── backend/                          # Tous les microservices Java
│   ├── api-gateway/                  # Service passerelle
│   │   ├── src/
│   │   │   ├── main/java/
│   │   │   │   └── com/ecom/gateway/
│   │   │   │       ├── config/
│   │   │   │       ├── controller/
│   │   │   │       └── filter/
│   │   │   └── test/
│   │   ├── Dockerfile
│   │   └── pom.xml
│   │
│   ├── product-service/              # Gestion produits
│   ├── order-service/                # Gestion commandes
│   ├── inventory-service/            # Gestion stocks
│   ├── notification-service/         # Notifications
│   │
│   ├── maven-settings.xml
│   └── pom.xml (parent)
│
├── frontend/                         # Application Angular
│   ├── src/
│   │   ├── app/
│   │   │   ├── components/
│   │   │   ├── services/
│   │   │   ├── models/
│   │   │   └── guards/
│   │   ├── assets/
│   │   └── styles/
│   ├── Dockerfile
│   ├── nginx.conf
│   ├── package.json
│   └── tailwind.config.js
│
├── Devops/                           # Infrastructure & CI/CD
│   ├── terraform/                    # Terraform configs
│   │   ├── main.tf
│   │   ├── mysql.tf
│   │   ├── cosmosdb.tf
│   │   ├── keyvault_storage.tf
│   │   ├── eventhubs.tf
│   │   └── k8s-namespaces.tf
│   ├── helm/                         # Helm charts
│   ├── jenkins/                      # Jenkins configuration
│   ├── scripts/                      # Scripts utilitaires
│   └── monitoring/                   # Configs monitoring
│
├── diagrams/                         # Architecture diagrams
│   ├── 08_devops_complete_process.puml
│   ├── 09_azure_detailed_cluster.puml
│   └── 10_database_schema.puml
│
├── rapport/                          # Documentation LaTeX
│   ├── main.tex
│   ├── 01_overview.tex
│   ├── 02_backend.tex
│   └── ...
│
├── k8s/                              # Kubernetes manifests
│   ├── deployments/
│   ├── services/
│   ├── configmaps/
│   ├── secrets/
│   └── ingress/
│
├── docker-compose.yml
├── Makefile
├── README.md
└── TEST_GUIDE.md
```

---

## 🔧 Microservices

### API Gateway (Port 8080)
**Responsabilités:**
- Point d'entrée unique pour toutes les requêtes
- Routage vers microservices
- Authentification JWT
- Rate limiting
- Load balancing

**Endpoints principaux:**
```
GET    /api/products              (product-service)
GET    /api/products/{id}
POST   /api/orders                (order-service)
GET    /api/orders/{id}
GET    /api/inventory/{sku}       (inventory-service)
```

### Product Service (Port 8001)
**Base de données:** Cosmos DB MongoDB  
**Collections:** `product`, `users`  
**Responsabilités:**
- Catalogue produits
- Recherche & filtrage
- Gestion images
- Authentification utilisateurs

### Order Service (Port 8002)
**Base de données:** MySQL  
**Tables:** `t_orders`, `t_users`  
**Responsabilités:**
- Création & suivi commandes
- Validation stock
- Calcul prix/taxes
- Publication événements

### Inventory Service (Port 8003)
**Base de données:** MySQL  
**Tables:** `t_inventory`  
**Responsabilités:**
- Gestion stock
- Réservation produits
- Alertes rupture

### Notification Service (Port 8004)
**Base de données:** MySQL  
**Tables:** `t_notifications`  
**Responsabilités:**
- Consommation Event Hubs
- Envoi emails/SMS
- Historique notifications

---

## 💾 Base de données

### MySQL Flexible Server

**Serveur:** `mysql-ecom` (SKU: B_Standard_B2s)  
**Version:** 8.0.21  
**Base:** `ecomdb` (charset: utf8mb4)

#### Tables

| Table | Service | Colonnes principales |
|-------|---------|----------------------|
| `t_users` | Authentication | id, username, email, password, role, enabled |
| `t_orders` | order-service | id, order_number, user_id, sku_code, price, quantity |
| `t_inventory` | inventory-service | id, sku_code, quantity |
| `t_notifications` | notification-service | id, order_id, type, status, recipient, sent_at |

#### Relations
```
t_orders.user_id → t_users.id (N:1)
t_orders.sku_code → t_inventory.sku_code (N:1)
t_notifications.order_id → t_orders.id (N:1)
```

### Cosmos DB MongoDB

**Compte:** `ecom-mongo-db` (API: MongoDB)  
**Consistency:** Session Level  
**Throughput:** 400 RU/s

#### Collections

| Collection | Service | Documents |
|------------|---------|-----------|
| `product` | product-service | name, description, skuCode, price, category, images, rating, colors, sizes |

---

## 🌐 API & Endpoints

### Base URL
```
http://api-gateway:8080/api/v1
```

### Authentification
Tous les endpoints nécessitent un JWT token:
```
Authorization: Bearer {token}
```

### Produits
```
GET    /products                    # Liste tous
GET    /products/{id}               # Détail
GET    /products?category=electronics
POST   /products                    # Créer (admin)
PUT    /products/{id}               # Modifier (admin)
DELETE /products/{id}               # Supprimer (admin)
```

### Commandes
```
GET    /orders                      # Mes commandes
GET    /orders/{id}                 # Détail
POST   /orders                      # Créer
PUT    /orders/{id}/status          # Changer statut
GET    /orders/{id}/tracking        # Tracking
```

### Stock
```
GET    /inventory/{sku}             # Quantité disponible
POST   /inventory/reserve           # Réserver stock
POST   /inventory/release           # Libérer réservation
```

---

## 🚀 Déploiement

### Sur Azure avec Terraform

```bash
cd Devops/terraform

# Initialiser Terraform
terraform init

# Vérifier plan
terraform plan

# Appliquer configuration
terraform apply

# Output: Resource Group, AKS cluster, databases
```

### Sur Kubernetes avec Helm

```bash
# Ajouter Helm repo
helm repo add ecommerce https://your-helm-repo
helm repo update

# Installer backend
helm install backend ecommerce/backend \
  --namespace backend \
  --values Devops/helm/backend-values.yaml

# Installer frontend
helm install frontend ecommerce/frontend \
  --namespace frontend \
  --values Devops/helm/frontend-values.yaml

# Vérifier déploiement
kubectl get pods -n backend
kubectl get pods -n frontend
```

### Mise à jour continue

```bash
# Push image ACR
docker push ecommerce/api-gateway:v1.0.0

# Kubernetes détecte & redéploie automatiquement
kubectl rollout status deployment/api-gateway -n backend

# Rollback si nécessaire
kubectl rollout undo deployment/api-gateway -n backend
```

---

## 📐 Infrastructure as Code

### Terraform - Ressources Azure

**Resource Group:** `rg-ecom-dev` (eastus)

#### Ressources provisionnées

1. **Container Registry (ACR)**
   - Stockage images Docker
   - Admin: Enabled
   - SKU: Basic

2. **Azure Kubernetes Service (AKS)**
   - 2 worker nodes (Standard_D2s_v3)
   - System node pool
   - Azure CNI networking
   - Standard Load Balancer

3. **MySQL Flexible Server**
   - SKU: B_Standard_B2s
   - Version: 8.0.21
   - Backup: 7 jours
   - Database: ecomdb

4. **Cosmos DB**
   - API: MongoDB
   - Consistency: Session
   - Database: ecom-mongo-db

5. **Storage Account**
   - Replication: LRS
   - Static website: Enabled
   - Blob container: product-images

6. **Event Hubs**
   - Namespace: eh-ecom
   - SKU: Standard
   - 2 partitions, 1 jour rétention

7. **Key Vault**
   - Secrets management
   - Soft delete: 7 jours

8. **Virtual Network**
   - Address space: 10.0.0.0/16
   - AKS subnet, AppGateway subnet

#### Temps de provisioning: 10-15 minutes

---

## 🔄 CI/CD Pipeline

### Jenkins Workflow

```
GitHub Commit
    ↓
├─ Build (Maven)           ~5 min
├─ Unit Tests              ~8 min
├─ Security Scan (SonarQube)
├─ Docker Build & Push     ~4 min
│   └─ ACR push
└─ Terraform Deploy        ~10-15 min
    └─ Azure resources
```

**Total time:** 25-30 minutes per build

### Stages

1. **Checkout** - Clone repository
2. **Build** - Maven clean install
3. **Test** - Unit & integration tests
4. **Security** - Code quality & vulnerabilities
5. **Docker** - Build images, push to ACR
6. **Deploy** - Terraform apply
7. **K8s Rollout** - Helm deploy to AKS
8. **Smoke Tests** - Vérify deployment

---

## ✅ Tests

### Unit Tests

```bash
cd backend
mvn test
```

### Integration Tests

```bash
cd backend
mvn verify
```

### Frontend Tests

```bash
cd frontend
npm run test
npm run test:watch
```

### E2E Tests

```bash
cd frontend
npm run e2e
```

### API Testing

```bash
# Avec Postman collection
postman run ./Devops/postman/ecommerce-api.json

# Ou manuellement
curl -X GET http://localhost:8080/api/products \
  -H "Authorization: Bearer {token}"
```

---

## 📊 Monitoring & Logging

### Prometheus Metrics

- **Application metrics:** Requests, latency, errors
- **JVM metrics:** Memory, threads, GC
- **Kubernetes metrics:** CPU, memory, disk
- **Database metrics:** Connections, queries

**Scrape interval:** 30 secondes  
**Retention:** 90 jours

### Grafana Dashboards

- **System Health** - Infrastructure overview
- **Application Performance** - Request metrics
- **Kubernetes Cluster** - Pod, node status
- **Database Metrics** - MySQL, Cosmos DB

**Access:** `https://grafana.your-domain`

### Loki Log Aggregation

- **Application logs** - All microservices
- **Kubernetes logs** - System & workload
- **Docker logs** - Container runtime

**Retention:** 30 jours

### Tempo Distributed Tracing

- **Request tracing** - End-to-end visibility
- **Performance analysis** - Latency breakdown
- **Error troubleshooting** - Root cause analysis

**Retention:** 504 heures (21 jours)

---

## 📚 Documentation

### Diagrammes d'architecture

| Diagram | Description |
|---------|-------------|
| **08_devops_complete_process.puml** | Pipeline CI/CD complet |
| **09_azure_detailed_cluster.puml** | Infrastructure Azure + Kubernetes |
| **10_database_schema.puml** | Schéma bases de données |

### Rapports

- **rapport/main.tex** - Documentation complète (LaTeX)
  - Overview
  - Architecture backend
  - Frontend
  - Monitoring
  - Infrastructure
  - DevOps

### Guides

- **TEST_GUIDE.md** - Guide complet des tests
- **DEPLOYMENT_GUIDE.md** - Instructions déploiement
- **API_DOCUMENTATION.md** - Référence API

---

## 🔐 Sécurité

### Authentification
- JWT tokens (HS256)
- Token expiration: 24h
- Refresh tokens: 7 jours

### Autorisation
- Role-Based Access Control (RBAC)
- Roles: `user`, `admin`
- Policy-based restrictions

### Chiffrement
- Secrets in Key Vault
- TLS/HTTPS everywhere
- Database encryption at rest

### Network Security
- Network Policies (Kubernetes)
- Default: Deny all
- Allow: Service-to-service only
- WAF: Application Gateway (optional)

---

## 📈 Performance

### Scalability
- Horizontal Pod Autoscaler (HPA)
- Min replicas: 2
- Max replicas: 10
- Target CPU: 70%

### Caching
- Redis (optional)
- API response caching
- TTL: configurable

### Database Optimization
- Connection pooling (HikariCP)
- Query optimization
- Indexes on foreign keys

---

## 🆘 Troubleshooting

### Pod not starting
```bash
kubectl describe pod <pod-name> -n backend
kubectl logs <pod-name> -n backend
```

### Database connection issues
```bash
# Vérifier connexion MySQL
mysql -h mysql-ecom.mysql.database.azure.com -u adminuser

# Vérifier Cosmos DB
mongosh "mongodb://connection-string"
```

### API Gateway errors
```bash
# Logs
kubectl logs deployment/api-gateway -n backend -f

# Health check
curl http://api-gateway:8080/actuator/health
```

---

## 📞 Support & Contribution

### Issues
Pour rapporter un bug ou suggestion, créer une issue sur GitHub.

### Pull Requests
1. Fork le repository
2. Créer une branche feature: `git checkout -b feature/my-feature`
3. Commit: `git commit -m "Add feature"`
4. Push: `git push origin feature/my-feature`
5. Créer PR

### Code Standards
- Java: Google Java Style Guide
- TypeScript: Angular Style Guide
- Commits: Conventional Commits
- Tests: Minimum 80% coverage

---

## 📄 License

MIT License - Voir [LICENSE](LICENSE)

---

## 👥 Équipe

**Développé par:** DevOps & Engineering Team  
**Année:** 2024-2025  
**Organisation:** E-Commerce Platform Project

---

**Last Updated:** December 2024  
**Status:** ✅ Production Ready
