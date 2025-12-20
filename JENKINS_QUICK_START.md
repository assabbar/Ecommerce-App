# ⚡ QUICK START: Lancer Jenkins en 5 Étapes

## 1️⃣ Exécuter le Script de Configuration Auto
```powershell
cd c:\Users\DELL\Desktop\Projet_DevOps\malak
bash Devops/scripts/setup-azure-jenkins.sh
```

**Cela va:**
- ✅ Authentifier Azure (code device)
- ✅ Récupérer ressources from Terraform
- ✅ Créer secrets Kubernetes
- ✅ Générer `jenkins.env` + config files

**Output attendu:**
```
✅ [Azure Login] Successfully authenticated
✅ [Terraform] Output retrieved
✅ [ACR] Credentials obtained
✅ [AKS] kubectl configured
✅ [Kubernetes] Secrets created
✅ [Files Generated] jenkins.env, values-production.yaml
```

---

## 2️⃣ Vérifier que Tout Fonctionne
```bash
# Vérifier jenkins.env existe
cat Devops/jenkins/jenkins.env | head

# Vérifier K8s
kubectl get nodes
kubectl get ns

# Vérifier ACR
az acr login --name acrecomdev12191331
```

---

## 3️⃣ Démarrer Jenkins
```powershell
# Aller au dossier Jenkins
cd Devops/jenkins

# Lancer Docker Compose
docker compose up -d

# Vérifier que Jenkins démarre
docker logs -f $(docker ps | grep jenkins | awk '{print $1}')

# Attendre: "Started LegacySecurityRealm"
# Puis CTRL+C pour quitter les logs
```

---

## 4️⃣ Configurer Jenkins UI (http://localhost:8080)

### A. Ajouter les Credentials

**Jenkins → Manage Jenkins → Credentials → System → Global credentials**

1. **Ajouter Azure Service Principal**
   - Kind: Microsoft Azure Service Principal
   - Subscription ID: (depuis setup output)
   - Client ID: (depuis setup output)
   - Client Secret: (depuis setup output)
   - Tenant ID: (depuis setup output)
   - ID: `azure-sp`

2. **Ajouter ACR Credentials**
   - Kind: Username with password
   - Username: (depuis `jenkins.env` → ACR_USERNAME)
   - Password: (depuis `jenkins.env` → ACR_PASSWORD)
   - ID: `acr-credentials`

3. **Ajouter GitHub Token (optionnel)**
   - Kind: Secret text
   - Secret: (ton GitHub PAT)
   - ID: `github-token`

### B. Configurer Global Properties (optionnel)

**Jenkins → Manage Jenkins → System → Global properties → Environment variables**

Cocher "Environment variables" et ajouter depuis `jenkins.env`:
- AZURE_SUBSCRIPTION_ID
- AZURE_AKS_NAME
- ACR_LOGIN_SERVER
- Etc...

---

## 5️⃣ Créer et Lancer le Pipeline

### A. Créer le Job
```
Jenkins → New Item
Name: ecommerce-app-pipeline
Type: Pipeline
OK
```

### B. Configurer le Job
```
Definition: Pipeline script from SCM
SCM: Git
Repository URL: https://github.com/assabbar/Ecommerce-App.git
Credentials: (sélectionner github-token si ajouté)
Branch: */main
Script Path: Devops/jenkins/Jenkinsfile
```

Click: **Save**

### C. Lancer le Pipeline
```
ecommerce-app-pipeline → Build Now

Monitorer les stages:
1. ✅ Setup Azure Configuration (2 min)
2. ✅ Checkout (1 min)
3. ✅ Backend Tests (5 min)
4. ✅ Frontend Tests (3 min)
5. ✅ Integration Tests (5 min)
6. ✅ Build Images (10 min)
7. ✅ Azure Connectivity (2 min)
8. ✅ Push to ACR (2 min)
9. ✅ Initialize Databases (3 min)
10. ✅ Deploy to AKS (5 min)
11. ✅ Smoke Tests (2 min)
12. ✅ Deployment Summary (1 min)

Total: ~40 minutes
```

---

## 🎯 Vérifier que le Déploiement a Réussi

Pendant/après le build:

```bash
# Vérifier les pods dans Kubernetes
kubectl get pods -n backend -w
kubectl get pods -n frontend
kubectl get pods -n monitoring

# Vérifier les services
kubectl get svc -n backend
kubectl get svc -n frontend

# Vérifier les logs
kubectl logs -f deployment/product-service -n backend
kubectl logs -f deployment/api-gateway -n backend

# Accéder à Grafana
kubectl port-forward svc/grafana 3000:80 -n monitoring
# Browser: http://localhost:3000
# Admin/admin
```

---

## ❌ Si Quelque Chose Échoue

### Setup script échoue
```bash
# Vérifier prereq
az --version
terraform --version
kubectl version

# Réessayer avec verbose
bash -x Devops/scripts/setup-azure-jenkins.sh 2>&1 | tee setup.log
```

### Jenkins ne démarre pas
```bash
# Vérifier logs
docker logs jenkins

# Vérifier port 8080
netstat -an | grep 8080

# Redémarrer
docker compose restart jenkins
```

### Build échoue à Setup Azure Configuration
```bash
# Vérifier jenkins.env existe
ls -la Devops/jenkins/jenkins.env

# Vérifier contenu
cat Devops/jenkins/jenkins.env

# Relancer setup
bash Devops/scripts/setup-azure-jenkins.sh
```

### Images ne pushent pas vers ACR
```bash
# Vérifier credentials
docker login -u $(grep ACR_USERNAME Devops/jenkins/jenkins.env) -p $(grep ACR_PASSWORD Devops/jenkins/jenkins.env) acrecomdev12191331.azurecr.io

# Vérifier Jenkins credentials
# Jenkins → Manage Jenkins → Credentials → Vérifier acr-credentials
```

---

## 📊 Dashboard

Une fois déploiement réussi:

| Composant | URL | Login |
|-----------|-----|-------|
| **Jenkins** | http://localhost:8080 | admin/admin |
| **Grafana** | kubectl port-forward :3000 | admin/admin |
| **Prometheus** | kubectl port-forward :9090 | N/A |
| **Loki** | kubectl port-forward :3100 | N/A |
| **Product API** | kubectl get svc -n backend | LoadBalancer IP:8080 |
| **API Gateway** | kubectl get svc -n backend | LoadBalancer IP:9000 |
| **Frontend** | kubectl get svc -n frontend | LoadBalancer IP:80 |

---

## 📋 Checklist Finale

```
PRE-JENKINS:
☐ setup-azure-jenkins.sh exécuté
☐ jenkins.env existe et est rempli
☐ kubectl get nodes fonctionne
☐ Kubernetes secrets créés (acr-secret)
☐ ACR login fonctionne

POST-JENKINS START:
☐ Jenkins UI accessible :8080
☐ Credentials ajoutées (Azure SP, ACR)
☐ Job créé avec Jenkinsfile correct

DEPLOYMENT:
☐ Build lancé
☐ Setup Azure Configuration stage ✅
☐ Tous les 12 stages complétés
☐ kubectl get pods affiche all pods running
☐ Services accessibles via LoadBalancer IPs
☐ Logs visibles dans Grafana
☐ Métriques dans Prometheus

SUCCESS: 🎉
```
