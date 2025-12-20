# .env vs Secrets vs Jenkins vs Kubernetes

## .env File (Devops/.env)

**Usage**: Local development ONLY

```bash
# Utilisé pour:
- Docker Compose local (docker-compose.yml)
- Scripts manuels (test-integration.sh, etc.)
- Development workflow

# Raison: Simple, facile à configurer localement
MYSQL_PASSWORD=mysql
MYSQL_SERVER=localhost
```

**IMPORTANT**: `.env` est **JAMAIS** utilisé en production!

---

## Real Deployment Chain (Production)

### 1. GitHub → Jenkins
```
git push origin main
        ↓
Jenkins détecte changement
        ↓
Récupère Jenkinsfile
```

### 2. Jenkins → Azure
```
Jenkins run:
  az login (service principal)
  ↓
  terraform output (récupère noms ressources dynamiquement)
  ↓
  az acr credential show (récupère ACR credentials)
  ↓
  az aks get-credentials (récupère kubeconfig)
```

**Fichiers utilisés**:
- `Devops/jenkins/Jenkinsfile` (stocké en Git)
- `Devops/jenkins/jenkins.env` (généré par script setup)
- Jenkins Credentials Store (dans Jenkins, pas en fichier)

### 3. Jenkins → Kubernetes (Deployment)

```
Jenkins exécute:
  docker build (création images)
  ↓
  docker push (push vers ACR)
  ↓
  kubectl apply / helm deploy (déploie dans K8s)
  ↓
  Kubernetes utilise SECRETS
```

**Kubernetes Secrets utilisés**:
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: mysql-credentials
  namespace: backend
type: Opaque
data:
  mysql-password: base64(password)
  mysql-user: base64(root)
  mysql-host: base64(server-fqdn)
```

Les pods lisent depuis:
```
/var/run/secrets/kubernetes.io/serviceaccount/
ou
environment variable injecté depuis secret
```

### 4. Pods → Databases

```
Pod démarrée avec:
  env:
    - name: SPRING_DATASOURCE_PASSWORD
      valueFrom:
        secretKeyRef:
          name: mysql-credentials
          key: mysql-password
      
Pas d'accès à .env
Pas d'accès à Jenkins credentials
Seulement au Secret Kubernetes
```

---

## Résumé: Où viennent les credentials?

| Composant | Source | Format |
|-----------|--------|--------|
| **Local Dev** | `.env` file | Plain text (danger!) |
| **Jenkins** | Jenkins Credentials Store | Encrypted |
| **K8s Pods** | Kubernetes Secrets | Base64 encoded |
| **Azure Auth** | Service Principal / az login | Token temporaire |

---

## Setup Automatique (Ce qu'on vient de créer)

Le script `setup-azure-jenkins.sh`:

```bash
# 1. Se connecte à Azure
az login

# 2. Récupère dynamiquement les ressources
terraform output

# 3. Crée les secrets K8s
kubectl create secret docker-registry acr-secret ...

# 4. Génère jenkins.env
cat > Devops/jenkins/jenkins.env << EOF
AZURE_SUBSCRIPTION_ID=...
AKS_CLUSTER_NAME=...
EOF

# 5. Génère values-production.yaml
cat > Devops/helm/values-production.yaml << EOF
image:
  registry: acrecomdev12191331.azurecr.io
EOF
```

Après ça, le `.env` file n'est plus nécessaire!

---

## Exécution du script

```bash
cd c:\Users\DELL\Desktop\Projet_DevOps\malak\Devops\scripts

# Sur Windows (PowerShell):
bash setup-azure-jenkins.sh

# Ou sur Linux/Mac:
./setup-azure-jenkins.sh
```

Le script va:
1. ✅ Récupérer TOUS les noms de ressources Azure
2. ✅ Créer les secrets Kubernetes
3. ✅ Générer `jenkins.env`
4. ✅ Générer `values-production.yaml`
5. ✅ Afficher les instructions

---

## Après setup script: Étapes Jenkins

1. **Ouvre Jenkins UI**: http://localhost:8080

2. **Crée credentials**:
   ```
   Jenkins → Manage Jenkins → Manage Credentials
   Add credentials → Username with password
   ID: acr-credentials
   Username: (from ACR)
   Password: (from ACR)
   ```

3. **Crée pipeline**:
   ```
   Jenkins → New Item → Pipeline
   Name: E-Commerce-Pipeline
   Repository: https://github.com/assabbar/Ecommerce-App
   Jenkinsfile path: Devops/jenkins/Jenkinsfile
   ```

4. **Ajoute environment variables**:
   ```groovy
   environment {
       AZURE_SUBSCRIPTION_ID = credentials('azure-subscription-id')
       AKS_CLUSTER_NAME = 'ecommerce-aks'
       // Récupère du jenkins.env généré
   }
   ```

5. **Build**:
   ```
   Click "Build Now"
   ```

---

## Point Important sur .env

**Q**: Si on utilise un script pour tout configurer dynamiquement, à quoi sert .env?

**A**: `.env` sert **seulement** pour:
- ✓ Docker Compose local: `docker-compose up`
- ✓ Tests locaux: `test-integration.sh`
- ✗ JAMAIS en production
- ✗ JAMAIS dans Jenkins
- ✗ JAMAIS dans Kubernetes

Le `.env` file peut même être supprimé après deployment, il ne sera jamais utilisé!

---

## Flux Complet Simplifié

```
Developer push code
        ↓
GitHub webhook → Jenkins
        ↓
Jenkins run setup-azure-jenkins.sh
        ↓
Récupère dynamiquement:
  - Resource names (terraform)
  - Credentials (Azure CLI)
  - Kubeconfig (AKS)
        ↓
Build Docker images
        ↓
Push to ACR
        ↓
Deploy with Helm (uses values-production.yaml)
        ↓
Kubernetes uses Secrets (created by setup script)
        ↓
Pods running ✅
```

**Zéro besoin de .env fichier en production!**
