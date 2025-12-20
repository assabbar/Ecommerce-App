# 🔧 Variables Jenkins: Configuration Complète

## Où Viennent les Variables?

### 1️⃣ **setup-azure-jenkins.sh génère `jenkins.env`**

Ce script exécute:
```bash
# Sources dynamiques (récupérées en temps réel)
az login --use-device-code                    # ← Authentification Azure
terraform output -raw                         # ← Noms des ressources
az acr credential show                        # ← Credentials ACR
az aks get-credentials                        # ← Config Kubernetes
```

Résultat: **`Devops/jenkins/jenkins.env`** (auto-rempli, **NE PAS ÉDITER MANUELLEMENT**)

---

## 📋 Variables Complètes du jenkins.env

### **Azure Subscription**
```bash
AZURE_SUBSCRIPTION_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
AZURE_TENANT_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```

### **Azure Resource Group**
```bash
AZURE_RESOURCE_GROUP=ecommerce-rg
AZURE_LOCATION=France Central
```

### **Azure Container Registry (ACR)**
```bash
ACR_NAME=acrecomdev12191331
ACR_LOGIN_SERVER=acrecomdev12191331.azurecr.io
ACR_USERNAME=00000000-0000-0000-0000-000000000000
ACR_PASSWORD=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```
*Source: `az acr credential show --name acrecomdev12191331`*

### **Azure Kubernetes Service (AKS)**
```bash
AZURE_AKS_NAME=ecommerce-aks
AZURE_AKS_RG=ecommerce-aks-nodes-rg
KUBERNETES_CONTEXT=ecommerce-aks
```
*Source: `terraform output -raw aks_cluster_name`*

### **Azure MySQL Flexible Server**
```bash
AZURE_MYSQL_HOST=mysql-ecom.mysql.database.azure.com
AZURE_MYSQL_PORT=3306
AZURE_MYSQL_USER=adminuser
AZURE_MYSQL_PASSWORD=S3cur3!Passw0rd
AZURE_MYSQL_DATABASES=ecomdb,ecom_order_db,ecom_inventory_db
```
*Source: `terraform output -raw mysql_server_fqdn`*

### **Azure CosmosDB (MongoDB)**
```bash
AZURE_COSMOSDB_ACCOUNT=cosmosecomdb
AZURE_COSMOSDB_HOST=cosmosecomdb.mongo.cosmos.azure.com
AZURE_COSMOSDB_KEY=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
AZURE_COSMOSDB_CONNECTION_STRING=mongodb://cosmosecomdb:xxxxxxxxxxxxx@cosmosecomdb.mongo.cosmos.azure.com:10255/?ssl=true
```
*Source: `terraform output -raw cosmosdb_connection_string`*

### **Azure Event Hubs**
```bash
AZURE_EVENTHUB_NAMESPACE=ecommerce-eventhub
AZURE_EVENTHUB_HOSTNAME=ecommerce-eventhub.servicebus.windows.net
AZURE_EVENTHUB_KEY=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```
*Source: `terraform output -raw eventhub_namespace`*

### **Azure Key Vault**
```bash
AZURE_KEYVAULT_NAME=ecommerce-kv
AZURE_KEYVAULT_URL=https://ecommerce-kv.vault.azure.net/
```
*Source: `terraform output -raw key_vault_name`*

### **Azure Storage Account**
```bash
AZURE_STORAGE_ACCOUNT=ecomstorage
AZURE_STORAGE_KEY=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```
*Source: `terraform output -raw storage_account_name`*

### **Kubernetes Configuration**
```bash
K8S_BACKEND_NAMESPACE=backend
K8S_FRONTEND_NAMESPACE=frontend
K8S_MONITORING_NAMESPACE=monitoring
K8S_CLUSTER_IP=x.x.x.x
```

### **Helm & Deployment**
```bash
HELM_RELEASE_NAME=ecommerce
HELM_CHART_REPO=https://charts.example.com
HELM_VALUES_FILE=Devops/helm/values-production.yaml
DEPLOYMENT_REPLICAS=2
DEPLOYMENT_IMAGE_PULL_POLICY=Always
DEPLOYMENT_NAMESPACE=backend
```

### **Monitoring Stack**
```bash
PROMETHEUS_STORAGE=50Gi
PROMETHEUS_RETENTION=30d
GRAFANA_ADMIN_USER=admin
GRAFANA_ADMIN_PASSWORD=admin
LOKI_RETENTION=7d
```

---

## 🔄 Comment le Jenkinsfile Les Utilise

### Dans la Stage "Setup Azure Configuration"
```groovy
stage('Setup Azure Configuration') {
    steps {
        sh '''
            # Source jenkins.env
            source Devops/jenkins/jenkins.env
            
            # Utilise les variables
            echo "ACR: $ACR_LOGIN_SERVER"
            echo "AKS: $AZURE_AKS_NAME"
            echo "MySQL: $AZURE_MYSQL_HOST"
            
            # Authentication
            kubectl config use-context $KUBERNETES_CONTEXT
            docker login -u $ACR_USERNAME -p $ACR_PASSWORD $ACR_LOGIN_SERVER
        '''
    }
}
```

### Dans la Stage "Push to ACR"
```groovy
stage('Push to ACR') {
    steps {
        sh '''
            source Devops/jenkins/jenkins.env
            
            # Tag images with ACR registry
            docker tag product-service $ACR_LOGIN_SERVER/product-service:$IMAGE_TAG
            docker push $ACR_LOGIN_SERVER/product-service:$IMAGE_TAG
        '''
    }
}
```

### Dans la Stage "Deploy to AKS"
```groovy
stage('Deploy to AKS') {
    steps {
        sh '''
            source Devops/jenkins/jenkins.env
            
            # Deploy using Helm with values from jenkins.env
            helm upgrade --install $HELM_RELEASE_NAME Devops/helm/product-service \\
                --namespace $K8S_BACKEND_NAMESPACE \\
                --values $HELM_VALUES_FILE \\
                --set image.repository=$ACR_LOGIN_SERVER/product-service
        '''
    }
}
```

---

## ⚙️ Configuration Jenkins Credentials

Ces variables viennent aussi des **Jenkins Credentials Store**:

### 1. **Azure Service Principal Credential**
```
Type: Microsoft Azure Service Principal
ID: azure-sp

Contient:
  - Subscription ID
  - Client ID
  - Client Secret
  - Tenant ID

Utilisé dans: Deploy to AKS, Initialize Databases
```

### 2. **Docker Registry Credential (ACR)**
```
Type: Username with password
ID: acr-credentials

Contient:
  - Username: ACR_USERNAME
  - Password: ACR_PASSWORD

Utilisé dans: Push to ACR, Docker login
```

### 3. **GitHub Credential**
```
Type: Personal Access Token / Username with password
ID: github-token

Contient:
  - GitHub username
  - GitHub PAT

Utilisé dans: Checkout (SCM)
```

---

## 🔐 Sécurité: Où Stockées Les Passwords?

| Password | Local Dev | Jenkins | Production |
|----------|-----------|---------|------------|
| ACR | `.env` (plaintext) | Jenkins Store (encrypted) | K8s Secrets |
| MySQL | `.env` (plaintext) | Jenkins Store (encrypted) | K8s Secrets → Pod |
| CosmosDB | `.env` (plaintext) | Jenkins Store (encrypted) | K8s Secrets → Pod |
| Azure SP | N/A | Jenkins Store (encrypted) | Service Account |

**Important:**
- ✅ `.env` est local seulement, jamais dans Git
- ✅ Jenkins Store est chiffré
- ✅ K8s Secrets sont base64 (pas sécurisé, utiliser Azure KeyVault pour production)

---

## 📝 Fichiers Générés par setup-azure-jenkins.sh

### 1. **`Devops/jenkins/jenkins.env`**
```bash
# Source: script setup, Terraform outputs, Azure CLI
# Utilisé par: Jenkinsfile (source Devops/jenkins/jenkins.env)
# Contenu: ALL variables listed above
# Modification: Auto-généré, NE PAS ÉDITER MANUELLEMENT
```

### 2. **`Devops/helm/values-production.yaml`**
```yaml
# Source: script setup, variables jenkins.env
# Utilisé par: helm upgrade/install
# Contenu: ACR_LOGIN_SERVER, replicas, resources, etc.
# Modification: Peut être édité après génération
```

### 3. **`DEPLOYMENT_INSTRUCTIONS.md`**
```markdown
# Source: script setup
# Contenu: Étapes de déploiement spécifiques
# Modification: Pour référence seulement
```

---

## 🚀 Workflow Complet: Variables à Déploiement

```
1. bash setup-azure-jenkins.sh
   ↓ Génère
2. Devops/jenkins/jenkins.env
   ↓ Utilisé par
3. Jenkinsfile (stage "Setup Azure Configuration")
   ↓ Source
4. sh 'source Devops/jenkins/jenkins.env'
   ↓ Variables disponibles
5. Docker build, push, Helm deploy
   ↓ Utilise
6. ACR_LOGIN_SERVER, AZURE_AKS_NAME, etc.
   ↓ Résultat
7. Images dans ACR, Pods dans AKS, Secrets dans K8s
```

---

## ✅ Vérifier les Variables

Après exécution de setup-azure-jenkins.sh:

```bash
# Afficher toutes les variables
cat Devops/jenkins/jenkins.env

# Compter les variables
cat Devops/jenkins/jenkins.env | wc -l
# Devrait afficher: 30+ variables

# Vérifier les principales
grep -E "^(ACR_LOGIN_SERVER|AZURE_AKS_NAME|AZURE_MYSQL_HOST)" Devops/jenkins/jenkins.env

# Sourcer dans shell courant pour test
source Devops/jenkins/jenkins.env
echo "ACR: $ACR_LOGIN_SERVER"
echo "AKS: $AZURE_AKS_NAME"
```

---

## 🔧 Modifier une Variable (Si Nécessaire)

**Cas: ACR password a changé**

```bash
# Option 1: Re-exécuter le script
bash Devops/scripts/setup-azure-jenkins.sh
# Va rafraîchir jenkins.env automatiquement

# Option 2: Éditer manuellement (pas recommandé)
# ATTENTION: Fichier auto-généré, édits perdus au prochain run du script
nano Devops/jenkins/jenkins.env
# Éditer ACR_PASSWORD=new_password
# Sauvegarder et redémarrer Jenkins

# Option 3: Passer la variable via Jenkins UI
# Jenkins → Configure → Environment variables
# AJOUTER: ACR_PASSWORD=new_password
# (Cela override la valeur de jenkins.env)
```

---

## 📚 Variables Utilisées par Service

### Product Service
```
AZURE_MYSQL_HOST → SPRING_DATASOURCE_URL
ACR_LOGIN_SERVER → Image registry
K8S_BACKEND_NAMESPACE → Deployment namespace
```

### Order Service
```
AZURE_MYSQL_HOST → SPRING_DATASOURCE_URL (ecom_order_db)
AZURE_EVENTHUB_HOSTNAME → spring.cloud.stream.kafka.binder.brokers
ACR_LOGIN_SERVER → Image registry
```

### Inventory Service
```
AZURE_MYSQL_HOST → SPRING_DATASOURCE_URL (ecom_inventory_db)
ACR_LOGIN_SERVER → Image registry
```

### Notification Service
```
AZURE_EVENTHUB_HOSTNAME → Email/SMS gateway config
ACR_LOGIN_SERVER → Image registry
```

### API Gateway
```
AZURE_AKS_NAME → Service discovery (K8s DNS)
ACR_LOGIN_SERVER → Image registry
```

### Frontend
```
ACR_LOGIN_SERVER → Image registry
API_GATEWAY_URL → http://api-gateway:9000 (K8s service discovery)
```

---

## 🎯 Résumé

| Question | Réponse |
|----------|---------|
| **Où viennent les variables?** | `setup-azure-jenkins.sh` les génère dans `jenkins.env` |
| **Peut-on éditer jenkins.env?** | Non, c'est auto-généré. Réexécuter le script si changement |
| **Combien de variables?** | 30+ variables (toutes les resources Azure + K8s) |
| **Qui les utilise?** | Jenkinsfile les source dans chaque stage |
| **Sont-elles sécurisées?** | Jenkins Store les chiffre, K8s utilise Secrets |
| **Et les passwords?** | Jenkins Store (chiffré), jamais dans Git |
| **Que faire si erreur?** | Relancer `setup-azure-jenkins.sh` |
