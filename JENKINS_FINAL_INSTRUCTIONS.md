# 🚀 FINAL: INSTRUCTIONS JENKINS + DÉPLOIEMENT CLOUD

## 📊 Architecture Finale

```
┌─────────────────────────────────────────────────────────────┐
│                     Azure Cloud (Production)                │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌─────────────────────────────────────────────────────┐    │
│  │ AKS Cluster (Kubernetes)                            │    │
│  │                                                      │    │
│  │  ┌─ Backend Namespace ─────────────────────────┐   │    │
│  │  │ Product Service     → CosmosDB (MongoDB)    │   │    │
│  │  │ Order Service       → MySQL (t_orders)      │   │    │
│  │  │ Inventory Service   → MySQL (t_inventory)   │   │    │
│  │  │ Notification Service→ Event Hub (Kafka)     │   │    │
│  │  │ API Gateway         → Routes all services   │   │    │
│  │  └─────────────────────────────────────────────┘   │    │
│  │                                                      │    │
│  │  ┌─ Frontend Namespace ────────────────────────┐   │    │
│  │  │ Angular Frontend  → API Gateway             │   │    │
│  │  └─────────────────────────────────────────────┘   │    │
│  │                                                      │    │
│  │  ┌─ Monitoring Namespace ──────────────────────┐   │    │
│  │  │ Prometheus     → Metrics                    │   │    │
│  │  │ Grafana        → Dashboards                 │   │    │
│  │  │ Loki           → Log aggregation            │   │    │
│  │  │ AlertManager   → Alerts                     │   │    │
│  │  └─────────────────────────────────────────────┘   │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                              │
│  ┌─────────────────────────────────────────────────────┐    │
│  │ Databases                                           │    │
│  │                                                     │    │
│  │ CosmosDB (MongoDB API)                            │    │
│  │ ├─ ecom-mongo-db                                 │    │
│  │ │  ├─ product (Product Service)                 │    │
│  │ │  └─ users (User Authentication)               │    │
│  │                                                     │    │
│  │ MySQL Flexible Server                             │    │
│  │ └─ ecom_app (Single database)                     │    │
│  │    ├─ t_orders (Order Service)                   │    │
│  │    └─ t_inventory (Inventory Service)            │    │
│  │                                                     │    │
│  │ Event Hub (Kafka)                                 │    │
│  │ └─ ecommerce-eventhub (Messaging)                │    │
│  │                                                     │    │
│  │ Key Vault (Secrets)                               │    │
│  │ └─ ecommerce-kv                                   │    │
│  │                                                     │    │
│  │ Container Registry (Images)                        │    │
│  │ └─ acrecomdev12191331.azurecr.io                │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## ✅ ÉTAPE 1: PRÉ-REQUIS (5 min)

```bash
# Vérifier que tu as:
✅ Azure CLI installé: az --version
✅ kubectl installé: kubectl version
✅ Terraform installé: terraform --version
✅ Helm 3 installé: helm version
✅ Docker installé: docker --version
✅ Git installé: git --version

# Vérifier connexion Azure
az account show
# Devrait afficher ton subscription ID
```

---

## ✅ ÉTAPE 2: AUTO-CONFIGURATION AZURE (10 min)

```bash
# Position: C:\Users\DELL\Desktop\Projet_DevOps\malak

bash Devops/scripts/setup-azure-jenkins.sh

# Cela va:
# 1. Te demander de te connecter Azure (code device)
# 2. Récupérer les outputs Terraform
# 3. Créer les secrets Kubernetes
# 4. Générer jenkins.env (toutes les variables)
# 5. Générer values-production.yaml (config Helm)

# À quoi s'attendre:
✅ Successfully authenticated to Azure
✅ Retrieved Terraform outputs
✅ ACR credentials obtained
✅ kubectl context configured
✅ Kubernetes secrets created (backend, frontend, monitoring)
✅ Files generated: jenkins.env, values-production.yaml
```

---

## ✅ ÉTAPE 3: VÉRIFICATIONS (5 min)

```bash
# 1. Vérifier jenkins.env
cat Devops/jenkins/jenkins.env | grep -E "^(AZURE|ACR|COSMOSDB|MYSQL)"
# Devrait afficher 20+ variables

# 2. Vérifier K8s secrets
kubectl get secrets -n backend | grep -E "acr|cosmosdb|mysql"
# Devrait afficher: acr-secret, cosmosdb-credentials, mysql-credentials

# 3. Vérifier AKS
kubectl get nodes
# Devrait afficher 2-3 nodes

# 4. Vérifier ACR
az acr login --name acrecomdev12191331
# Devrait dire: Login Succeeded
```

---

## ✅ ÉTAPE 4: DÉMARRER JENKINS (5 min)

```bash
cd Devops/jenkins

docker compose up -d

# Attendre 2-3 min que ça démarre
docker logs -f jenkins
# Chercher: "Started LegacySecurityRealm"
# Puis CTRL+C

# Accès: http://localhost:8080
# Admin: admin/admin
```

---

## ✅ ÉTAPE 5: AJOUTER CREDENTIALS JENKINS (10 min)

**Jenkins → Manage Jenkins → Credentials → System → Global credentials**

### Credential 1: ACR
```
Type: Username with password
Username: $(grep ACR_USERNAME Devops/jenkins/jenkins.env | cut -d= -f2)
Password: $(grep ACR_PASSWORD Devops/jenkins/jenkins.env | cut -d= -f2)
ID: acr-credentials
```

### Credential 2: Azure SP (optionnel si déjà setup)
```
Type: Microsoft Azure Service Principal
(Récupérer depuis setup-azure-jenkins.sh output)
ID: azure-sp
```

### Credential 3: GitHub (optionnel)
```
Type: Secret text
Secret: (ton GitHub PAT)
ID: github-token
```

---

## ✅ ÉTAPE 6: CRÉER LE JOB JENKINS (5 min)

**Jenkins → New Item**

```
Name: ecommerce-app-pipeline
Type: Pipeline
Definition: Pipeline script from SCM

Repository:
├─ SCM: Git
├─ URL: https://github.com/assabbar/Ecommerce-App.git
├─ Branch: */main
├─ Script path: Devops/jenkins/Jenkinsfile
└─ Save
```

---

## ✅ ÉTAPE 7: LANCER LE BUILD (40 min)

```
Jenkins UI → ecommerce-app-pipeline → Build Now

Stages (dans l'ordre):
1. Setup Azure Configuration (2 min)
   └─ Source jenkins.env, vérifie AKS, ACR, K8s secrets

2. Checkout (1 min)
   └─ Clone GitHub repo

3. Backend Unit Tests (5 min)
   └─ Maven tests pour product, order, inventory, notification

4. Frontend Unit Tests (3 min)
   └─ Angular Karma tests

5. Integration Tests (5 min)
   └─ docker-compose.test.yml (MongoDB + services)

6. Build Docker Images (10 min)
   └─ Build 6 services + frontend avec BuildKit

7. Azure Connectivity Test (2 min)
   └─ Test ACR et AKS

8. Push to ACR (2 min)
   └─ Push all images avec tag BUILD_NUMBER

9. Initialize Databases (3 min)
   └─ Create MySQL tables et CosmosDB collections

10. Deploy to AKS (5 min)
    └─ Helm deploy avec values-production.yaml

11. Smoke Tests (2 min)
    └─ Health checks sur tous les services

12. Deployment Summary (1 min)
    └─ Affiche les URLs et statuts

BUILD: SUCCESS ✅
```

---

## ✅ ÉTAPE 8: VÉRIFIER LE DÉPLOIEMENT (5 min)

```bash
# 1. Vérifier que tous les pods tournent
kubectl get pods -n backend
kubectl get pods -n frontend
kubectl get pods -n monitoring

# Output attendu: tous les pods doivent être "Running"

# 2. Vérifier les services (LoadBalancer)
kubectl get svc -n backend
kubectl get svc -n frontend

# Output attendu:
# - product-service: LoadBalancer (IP externe)
# - api-gateway: LoadBalancer (IP externe)
# - frontend: LoadBalancer (IP externe)

# 3. Accéder aux services
API_GW_IP=$(kubectl get svc api-gateway -n backend -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "API Gateway: http://$API_GW_IP:9000"

FE_IP=$(kubectl get svc frontend -n frontend -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "Frontend: http://$FE_IP"

# 4. Vérifier les logs
kubectl logs deployment/product-service -n backend | tail -20
# Devrait afficher: "Connected to MongoDB" ou CosmosDB connection

# 5. Test API
curl http://$API_GW_IP:9000/api/product
# Devrait retourner les produits depuis CosmosDB
```

---

## 🗄️ BASES DE DONNÉES - CONFIGURATION FINALE

### **CosmosDB (MongoDB API)**
```
Server: cosmosecomdb.mongo.cosmos.azure.com:10255
Database: ecom-mongo-db
Collections:
  ├─ product (Catalog)
  │  └─ Utilisé par: Product Service
  │     Entité: Product.java (@Document("product"))
  │     Opérations: CRUD sur produits
  │
  └─ users (User Catalog)
     └─ Utilisé par: Product Service (Auth)
        Entité: User.java (@Document("users"))
        Opérations: Register, Login, Validation
```

### **MySQL Flexible Server - ecom_app**
```
Server: mysql-ecom.mysql.database.azure.com:3306
Database: ecom_app (unique, partagée)
Tables:
  ├─ t_orders
  │  └─ Utilisé par: Order Service
  │     Entité: Order.java (@Table("t_orders"))
  │     Opérations: Créer/lister commandes
  │
  └─ t_inventory
     └─ Utilisé par: Inventory Service
        Entité: Inventory.java (@Table("t_inventory"))
        Opérations: Gérer stock

JDBC URL: jdbc:mysql://mysql-ecom.mysql.database.azure.com:3306/ecom_app?allowPublicKeyRetrieval=true&useSSL=false
```

### **Event Hub (Kafka)**
```
Namespace: ecommerce-eventhub
Broker: ecommerce-eventhub.servicebus.windows.net:9092
Topics:
  ├─ order-events (Order Service → Notification Service)
  ├─ inventory-events (Inventory Service → Notification Service)
  └─ notification-events (Notification Service)
```

---

## 🔐 CREDENTIALS - OÙ SONT STOCKÉS

| Service | Dev | Jenkins | Kubernetes | Production |
|---------|-----|---------|------------|------------|
| **MySQL** | .env (plaintext) | Credentials Store | K8s Secret (mysql-credentials) | ✅ Utilisé |
| **CosmosDB** | .env (plaintext) | Credentials Store | K8s Secret (cosmosdb-credentials) | ✅ Utilisé |
| **ACR** | .env (plaintext) | Credentials Store | K8s Secret (acr-secret) | ✅ Pull images |
| **Azure SP** | N/A | Credentials Store | Service Account | ✅ RBAC |

---

## 📝 FICHIERS DE CONFIGURATION CRÉÉS

### Application Properties (Production Profiles)
```
backend/
├─ product-service/src/main/resources/
│  ├─ application.properties (dev)
│  └─ application-production.properties ← NEW (CosmosDB)
│
├─ order-service/src/main/resources/
│  ├─ application.properties (dev)
│  └─ application-production.properties ← NEW (MySQL ecom_app)
│
├─ inventory-service/src/main/resources/
│  ├─ application.properties (dev)
│  └─ application-production.properties ← NEW (MySQL ecom_app)
│
├─ notification-service/src/main/resources/
│  ├─ application.properties (dev)
│  └─ application-production.properties ← NEW (Event Hub)
│
└─ api-gateway/src/main/resources/
   └─ application.properties (already set up)
```

### Helm Values (Production)
```
Devops/helm/
├─ product-service/values-production.yaml ← NEW
├─ order-service/values-production.yaml ← NEW
├─ inventory-service/values-production.yaml ← NEW
├─ notification-service/values-production.yaml ← NEW
├─ api-gateway/values-production.yaml ← NEW
└─ frontend/values-production.yaml ← NEW
```

### Scripts Modifiés
```
Devops/scripts/
├─ deploy-aks.sh ← MODIFIED (CosmosDB & MySQL secrets)
├─ setup-azure-jenkins.sh (auto-configuration)
└─ init-databases.sh (init script)
```

---

## 🎯 RÉSUMÉ FINAL

| Phase | Temps | Action |
|-------|-------|--------|
| 1 | 5 min | Vérifier prérequis |
| 2 | 10 min | `bash setup-azure-jenkins.sh` |
| 3 | 5 min | Vérifier jenkins.env et K8s secrets |
| 4 | 5 min | Démarrer Jenkins |
| 5 | 10 min | Ajouter credentials Jenkins |
| 6 | 5 min | Créer job pipeline |
| 7 | **40 min** | **Build Now (12 stages)** |
| 8 | 5 min | Vérifier déploiement |
| **TOTAL** | **~85 min** | **Production ready** |

---

## 🎉 SUCCESS CRITERIA

✅ Tous les stages Jenkins complétés
✅ kubectl get pods -n backend: ALL RUNNING
✅ kubectl get pods -n frontend: ALL RUNNING  
✅ kubectl get pods -n monitoring: ALL RUNNING
✅ curl http://$API_GW_IP:9000/api/product: retourne produits
✅ Frontend accessible: http://$FE_IP
✅ Grafana accessible: http://$GRAFANA_IP:3000 (admin/admin)
✅ Logs dans Loki visibles
✅ Métriques dans Prometheus visibles

---

## 🚨 TROUBLESHOOTING RAPIDE

### Build échoue à "Setup Azure Configuration"
```bash
# Vérifier jenkins.env existe
test -f Devops/jenkins/jenkins.env && echo OK || echo MISSING

# Relancer setup
bash Devops/scripts/setup-azure-jenkins.sh
```

### Pods ne démarrent pas
```bash
# Vérifier le statut
kubectl describe pod <pod-name> -n backend

# Vérifier les secrets
kubectl get secrets -n backend

# Vérifier les logs
kubectl logs deployment/product-service -n backend
```

### ACR images ne pullent pas
```bash
# Vérifier credentials
kubectl get secret acr-secret -n backend -o yaml

# Re-créer secret
kubectl delete secret acr-secret -n backend
bash Devops/scripts/deploy-aks.sh
```

### MySQL ou CosmosDB ne connectent pas
```bash
# Vérifier secrets
kubectl get secret mysql-credentials -n backend -o yaml
kubectl get secret cosmosdb-credentials -n backend -o yaml

# Vérifier logs du service
kubectl logs deployment/product-service -n backend | grep -i mongo
kubectl logs deployment/order-service -n backend | grep -i mysql
```

---

**Prêt? Commence par l'ÉTAPE 1! 🚀**
