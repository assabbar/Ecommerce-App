# 🚀 Configuration Jenkins Avant de Lancer le Pipeline

## Phase 1: Exécuter le Script d'Auto-Configuration (AVANT Jenkins)

### 1.1 Prérequis
```bash
✅ Azure CLI installé: az --version
✅ Terraform installé: terraform --version
✅ kubectl installé: kubectl version
✅ Helm 3 installé: helm version
✅ Git installé: git --version
```

### 1.2 Authentification Azure
```bash
# Position: C:\Users\DELL\Desktop\Projet_DevOps\malak
# Exécuter le script
bash Devops/scripts/setup-azure-jenkins.sh

# Le script va:
# 1. Demander authentification Azure (code device)
# 2. Récupérer les outputs Terraform (noms de ressources)
# 3. Créer les secrets Kubernetes
# 4. Générer les fichiers de config
```

**À quoi s'attendre:**
```
✅ [Azure Login] Successfully authenticated to Azure
✅ [Terraform] Retrieved outputs for resource group, AKS, ACR, databases
✅ [ACR] Got credentials for acrecomdev12191331.azurecr.io
✅ [AKS] Configured kubectl context
✅ [Kubernetes] Created secrets in backend, frontend, monitoring namespaces
✅ [Files] Generated:
   - Devops/jenkins/jenkins.env (contenants toutes les variables)
   - Devops/helm/values-production.yaml (config Helm)
   - DEPLOYMENT_INSTRUCTIONS.md (guide de déploiement)
```

### 1.3 Vérifier les fichiers générés
```bash
# Vérifier jenkins.env
cat Devops/jenkins/jenkins.env
# Devrait contenir:
#   - AZURE_SUBSCRIPTION_ID
#   - AZURE_RESOURCE_GROUP
#   - AZURE_AKS_NAME
#   - AZURE_ACR_NAME
#   - ACR_USERNAME
#   - ACR_PASSWORD
#   - AZURE_MYSQL_HOST
#   - AZURE_COSMOSDB_HOST
#   - Etc...

# Vérifier les secrets Kubernetes
kubectl get secrets -n backend
kubectl get secrets -n frontend  
kubectl get secrets -n monitoring
# Devraient afficher "acr-secret" dans chaque namespace

# Vérifier la connexion AKS
kubectl get nodes
# Devrait afficher les nodes du cluster
```

---

## Phase 2: Configurer Jenkins UI (Avant de créer le Job)

### 2.1 Accéder à Jenkins
```
URL: http://localhost:8080
Admin credentials: (voir Devops/jenkins/docker-compose.yml)
```

### 2.2 Configurer les Credentials (Jenkins → Manage Jenkins → Credentials)

**A. Ajouter Azure Service Principal (pour Azure CLI)**
```
Type: Microsoft Azure Service Principal
Subscription ID: (depuis jenkins.env → AZURE_SUBSCRIPTION_ID)
Client ID: (depuis script output)
Client Secret: (depuis script output)
Tenant ID: (depuis script output)
Scope: Global
ID: azure-sp
Description: Azure Service Principal for Jenkins
```

**B. Ajouter Docker Registry Credential (pour ACR)**
```
Type: Username with password
Username: (depuis jenkins.env → ACR_USERNAME)
Password: (depuis jenkins.env → ACR_PASSWORD)
ID: acr-credentials
Description: Azure Container Registry credentials
Scope: Global
```

**C. Ajouter GitHub Personal Access Token**
```
Type: Username with password (ou Secret text)
Username: (ton compte GitHub)
Password: (GitHub PAT token)
ID: github-credentials
Description: GitHub personal access token
Scope: Global
```

### 2.3 Configurer les Secrets Jenkins (Jenkins → Manage Jenkins → System → Global Properties)

Ajouter les variables d'environnement globales (depuis jenkins.env):
```
Variables à ajouter:
- AZURE_SUBSCRIPTION_ID
- AZURE_RESOURCE_GROUP
- AZURE_AKS_NAME
- AZURE_AKS_RG
- AZURE_ACR_NAME
- ACR_LOGIN_SERVER
- DOCKER_BUILDKIT = 1
- COMPOSE_DOCKER_CLI_BUILD = 1
```

### 2.4 Configuration de Docker (Jenkins → Manage Jenkins → Tools → Docker Installations)

Vérifier que Docker est disponible dans Jenkins:
```
Name: default
Install automatically: ✓ (décoché si Docker CLI déjà sur l'hôte)
Path to Docker executable: /usr/bin/docker (si manuel)
```

---

## Phase 3: Créer le Job Jenkins Pipeline

### 3.1 Créer un nouveau Pipeline Job
```
Jenkins → New Item
Name: ecommerce-app-pipeline
Type: Pipeline
Click: OK
```

### 3.2 Configurer le Job
```
Definition: Pipeline script from SCM
SCM: Git
Repository URL: https://github.com/assabbar/Ecommerce-App.git
Credentials: (sélectionner github-credentials)
Branch: */main
Script Path: Devops/jenkins/Jenkinsfile
```

### 3.3 Build Triggers (optionnel)
```
☐ GitHub hook trigger for GITScm polling
  (Pour déclencher auto sur chaque push GitHub)

☐ Poll SCM
  Cron: H */30 * * * (vérifier repo toutes les 30 min)
```

---

## Phase 4: Variables d'Environnement Jenkins à Sourcer

Le Jenkinsfile va charger **jenkins.env** généré par le script setup.

### 4.1 Structure du jenkins.env généré
```bash
# Azure Configuration (depuis terraform output)
AZURE_SUBSCRIPTION_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
AZURE_RESOURCE_GROUP=ecommerce-rg
AZURE_AKS_NAME=ecommerce-aks
AZURE_AKS_RG=ecommerce-rg
AZURE_ACR_NAME=acrecomdev12191331
ACR_LOGIN_SERVER=acrecomdev12191331.azurecr.io
AZURE_MYSQL_HOST=mysql-ecom.mysql.database.azure.com
AZURE_COSMOSDB_HOST=cosmosecomdb.mongo.cosmos.azure.com
AZURE_EVENTHUB_NAMESPACE=ecommerce-eventhub
AZURE_KEYVAULT_NAME=ecommerce-kv
AZURE_STORAGE_ACCOUNT=ecomstorage

# ACR Credentials (depuis az acr credential show)
ACR_USERNAME=acrecomdev12191331
ACR_PASSWORD=xxxxxxxxxxxxxxxxxxxxxxxxxxxxx

# Kubernetes Namespaces
K8S_BACKEND_NAMESPACE=backend
K8S_FRONTEND_NAMESPACE=frontend
K8S_MONITORING_NAMESPACE=monitoring

# Helm & Deployment
HELM_RELEASE_NAME=ecommerce
HELM_REPO=https://charts.example.com
DEPLOYMENT_REPLICAS=2
DEPLOYMENT_IMAGE_PULL_POLICY=Always
```

### 4.2 Comment le Jenkinsfile l'utilise
```groovy
// Le Jenkinsfile va auto-charger depuis jenkins.env
stage('Setup Azure Configuration') {
    steps {
        sh '''
            source Devops/jenkins/jenkins.env
            echo "ACR: $ACR_LOGIN_SERVER"
            echo "AKS: $AZURE_AKS_NAME"
            echo "MySQL: $AZURE_MYSQL_HOST"
        '''
    }
}
```

---

## Phase 5: Ordre d'Exécution Recommandé

### ✅ AVANT de lancer Jenkins
```
1. bash Devops/scripts/setup-azure-jenkins.sh
   ↓ (génère jenkins.env, values-production.yaml)

2. Vérifier fichiers générés
   - cat Devops/jenkins/jenkins.env
   - cat Devops/helm/values-production.yaml
   ↓

3. Vérifier connectivité K8s
   - kubectl get nodes
   - kubectl get ns
   ↓

4. Vérifier ACR
   - az acr login --name acrecomdev12191331
   ↓

5. Démarrer Jenkins
   - docker compose -f Devops/jenkins/docker-compose.yml up -d
```

### ✅ APRÈS avoir démarré Jenkins (UI)
```
1. Aller à Jenkins: http://localhost:8080
   ↓

2. Manage Jenkins → Credentials → Ajouter:
   - Azure Service Principal
   - ACR credentials
   - GitHub PAT
   ↓

3. Manage Jenkins → System → Global Properties
   - Ajouter variables depuis jenkins.env
   ↓

4. New Item → Pipeline
   - Repository: GitHub
   - Branch: main
   - Jenkinsfile path: Devops/jenkins/Jenkinsfile
   ↓

5. Save → Build Now
```

---

## Phase 6: Modification Jenkinsfile pour sourcer jenkins.env

⚠️ **Important:** Le Jenkinsfile doit être modifié pour:
1. Charger **jenkins.env** généré par le script
2. Ajouter une étape **Setup Azure Configuration** au début
3. Utiliser les variables depuis jenkins.env

### 6.1 Modification à faire
```groovy
// Ajouter après 'environment {}' et avant 'stages {}'

stages {
    stage('Setup Azure Configuration') {
        agent any
        steps {
            script {
                echo '====== Setup Azure Configuration ======'
                sh '''
                    # Source les variables depuis jenkins.env
                    source Devops/jenkins/jenkins.env
                    
                    echo "✅ Azure Configuration loaded:"
                    echo "   - ACR: $ACR_LOGIN_SERVER"
                    echo "   - AKS: $AZURE_AKS_NAME"
                    echo "   - MySQL: $AZURE_MYSQL_HOST"
                    echo "   - CosmosDB: $AZURE_COSMOSDB_HOST"
                    echo "   - Namespaces: backend, frontend, monitoring"
                    
                    # Vérifier connectivité
                    echo ""
                    echo "✅ Verifying AKS connection..."
                    kubectl get nodes
                    
                    echo ""
                    echo "✅ Verifying ACR credentials..."
                    echo $ACR_PASSWORD | docker login -u $ACR_USERNAME --password-stdin $ACR_LOGIN_SERVER
                    
                    echo ""
                    echo "✅ Azure Configuration: READY"
                '''
            }
        }
    }
    
    // ... rest of the stages
}
```

---

## Phase 7: Vérification Complète Avant Lancement

### ✅ Checklist
```
□ setup-azure-jenkins.sh exécuté avec succès
□ jenkins.env généré et contient toutes les variables
□ values-production.yaml généré
□ kubectl get nodes retourne les nodes AKS
□ kubectl get ns retourne backend, frontend, monitoring
□ kubectl get secrets -n backend affiche acr-secret
□ az acr login fonctionne avec ACR_USERNAME/PASSWORD
□ Jenkins démarré (docker ps affiche jenkins)
□ Jenkins accessible: http://localhost:8080
□ Credentials configurées dans Jenkins (3 types)
□ Global Properties contiennent variables
□ Jenkinsfile modifié avec Setup Azure Configuration stage
□ GitHub repository pushé avec dernier Jenkinsfile
```

---

## Phase 8: Lancer le Pipeline

### 8.1 Première exécution
```
Jenkins UI → ecommerce-app-pipeline → Build Now

Attend les stages:
1. Setup Azure Configuration (2 min)
2. Checkout (1 min)
3. Backend Tests (5 min)
4. Frontend Tests (3 min)
5. Integration Tests (5 min)
6. Build Images (10 min)
7. Azure Connectivity (2 min)
8. Push to ACR (2 min)
9. Initialize Databases (3 min)
10. Deploy to AKS (5 min)
11. Smoke Tests (2 min)
12. Deployment Summary (1 min)

Total: ~40 minutes
```

### 8.2 Surveiller les logs
```bash
# Depuis le terminal
docker logs -f $(docker ps | grep jenkins | awk '{print $1}')

# Ou via Jenkins UI
ecommerce-app-pipeline → #1 → Console Output
```

### 8.3 Succès = tous les pods running
```bash
kubectl get pods -n backend -w
kubectl get pods -n frontend -w
kubectl get svc -n backend
```

---

## 🎯 Résumé Rapide

| Étape | Commande | Résultat |
|-------|----------|----------|
| 1 | `bash setup-azure-jenkins.sh` | Génère jenkins.env + config files |
| 2 | Vérifier `jenkins.env` | Variables Azure auto-remplies ✅ |
| 3 | Démarrer Jenkins | UI accessible :8080 |
| 4 | Ajouter Credentials (3) | ACR, Azure SP, GitHub |
| 5 | Créer Pipeline Job | Jenkinsfile sourced |
| 6 | Modifier Jenkinsfile | Ajouter Setup Azure stage |
| 7 | Build Now | 12 stages executés |
| 8 | kubectl get pods | All pods running ✅ |

**Temps total:**
- Setup: 10-15 min
- Config Jenkins: 10 min
- Premier build: 40 min
- **Total: ~65 min pour déploiement complet**
