# E-Commerce Microservices - Helm Deployment

Configuration Helm pour déployer l'application E-Commerce sur Azure Kubernetes Service (AKS).

## 📋 Prérequis

- AKS cluster provisionné via Terraform
- kubectl configuré avec les credentials AKS
- Helm 3.x installé
- Images Docker dans Azure Container Registry (ACR)
- Namespaces Kubernetes créés (backend, frontend, monitoring)

## 🏗️ Architecture

### Namespaces
- **backend**: Tous les microservices backend
- **frontend**: Application Angular
- **monitoring**: Stack de monitoring (Prometheus, Grafana)

### Services Backend (namespace: backend)
1. **product-service** (Port 8080)
   - Base de données: CosmosDB MongoDB
   - Replicas: 2-5 (HPA activé)
   
2. **order-service** (Port 8081)
   - Base de données: Azure MySQL
   - Dépendances: inventory-service, Kafka/Event Hubs
   - Replicas: 2-5 (HPA activé)
   
3. **inventory-service** (Port 8082)
   - Base de données: Azure MySQL
   - Replicas: 2-5 (HPA activé)
   
4. **notification-service** (Port 8083)
   - Messaging: Kafka/Event Hubs
   - Email: SMTP
   - Replicas: 2-4 (HPA activé)
   
5. **api-gateway** (Port 8080)
   - Type: LoadBalancer (IP publique)
   - Routes vers tous les microservices
   - Replicas: 3-10 (HPA activé)

### Frontend (namespace: frontend)
- **frontend** (Port 80)
  - Type: LoadBalancer (IP publique)
  - Application Angular avec nginx
  - Replicas: 3-10 (HPA activé)

## 🚀 Déploiement

### 1. Validation des Charts

Avant de déployer, validez tous les Helm charts:

```bash
# Linux/Mac
./Devops/scripts/validate-helm.sh

# Windows PowerShell
.\Devops\scripts\validate-helm.ps1
```

### 2. Déploiement Complet

Déployez tous les services en une commande:

```bash
# Linux/Mac
./Devops/scripts/deploy.sh

# Windows PowerShell
.\Devops\scripts\deploy.ps1
```

Le script va:
1. ✅ Vérifier les prérequis (az, kubectl, helm)
2. ✅ Récupérer les credentials AKS
3. ✅ Vérifier la connectivité au cluster
4. ✅ Vérifier les namespaces et service accounts
5. ✅ Déployer tous les microservices backend
6. ✅ Déployer l'API Gateway
7. ✅ Déployer le frontend
8. ✅ Afficher le statut du déploiement

### 3. Déploiement Individuel

Pour déployer un service spécifique:

```bash
# Example: product-service
helm upgrade --install product-service ./Devops/helm/product-service \
  --namespace backend \
  --set image.repository=acrecomdev12262215.azurecr.io/product-service \
  --set image.tag=latest \
  --wait

# Example: frontend
helm upgrade --install frontend ./Devops/helm/frontend \
  --namespace frontend \
  --set image.repository=acrecomdev12262215.azurecr.io/frontend \
  --set image.tag=latest \
  --wait
```

### 4. Variables d'Environnement

Vous pouvez personnaliser le déploiement avec des variables:

```bash
# Bash
export AKS_CLUSTER_NAME="aks-ecom"
export RESOURCE_GROUP="rg-ecom-dev"
export ACR_NAME="acrecomdev12262215"
export IMAGE_TAG="v1.0.0"

./Devops/scripts/deploy.sh

# PowerShell
$env:AKS_CLUSTER_NAME="aks-ecom"
$env:RESOURCE_GROUP="rg-ecom-dev"
$env:ACR_NAME="acrecomdev12262215"
$env:IMAGE_TAG="v1.0.0"

.\Devops\scripts\deploy.ps1
```

## 📊 Monitoring & Status

### Vérifier le Statut

```bash
# Linux/Mac
./Devops/scripts/status.sh

# Windows PowerShell
.\Devops\scripts\status.ps1
```

Affiche:
- État des pods (backend + frontend)
- Services et leurs types
- HPA (Horizontal Pod Autoscaler) status
- IP publiques des LoadBalancers

### Commandes Kubectl Utiles

```bash
# Pods backend
kubectl get pods -n backend -o wide

# Pods frontend
kubectl get pods -n frontend -o wide

# Services et leurs IPs
kubectl get svc -n backend
kubectl get svc -n frontend

# Logs d'un service
kubectl logs -f <pod-name> -n backend

# Décrire un pod (debug)
kubectl describe pod <pod-name> -n backend

# HPA status
kubectl get hpa -n backend
kubectl get hpa -n frontend

# Events (debug)
kubectl get events -n backend --sort-by='.lastTimestamp'
```

### Port-Forward pour Tests Locaux

```bash
# API Gateway
kubectl port-forward svc/api-gateway 8080:8080 -n backend

# Frontend
kubectl port-forward svc/frontend 4200:80 -n frontend

# Service spécifique
kubectl port-forward svc/product-service 8080:8080 -n backend
```

## 🔄 Mise à Jour

### Update d'un Service avec Nouvelle Image

```bash
# Méthode 1: Via Helm
helm upgrade product-service ./Devops/helm/product-service \
  --namespace backend \
  --set image.tag=v1.2.0 \
  --wait

# Méthode 2: Via kubectl
kubectl set image deployment/product-service \
  product-service=acrecomdev12262215.azurecr.io/product-service:v1.2.0 \
  -n backend

# Vérifier le rollout
kubectl rollout status deployment/product-service -n backend
```

### Rollback vers Version Précédente

```bash
# Linux/Mac
./Devops/scripts/rollback.sh product-service backend

# Windows PowerShell
.\Devops\scripts\rollback.ps1 -Service product-service -Namespace backend

# Ou directement avec Helm
helm rollback product-service 0 --namespace backend
```

### Historique des Déploiements

```bash
# Voir l'historique Helm
helm history product-service -n backend

# Voir l'historique kubectl
kubectl rollout history deployment/product-service -n backend
```

## 🔧 Configuration

### Modifier les Variables d'Environnement

Éditez `values.yaml` du service concerné:

```yaml
# Devops/helm/product-service/values.yaml
env:
  - name: MONGODB_URI
    value: "mongodb://cosmosecomdb:27017/ecom-mongo-db"
  - name: SPRING_PROFILES_ACTIVE
    value: "prod"
```

Puis redéployez:

```bash
helm upgrade product-service ./Devops/helm/product-service -n backend
```

### Ajuster les Ressources

Modifiez les limites CPU/Memory dans `values.yaml`:

```yaml
resources:
  limits:
    cpu: 1000m
    memory: 1Gi
  requests:
    cpu: 500m
    memory: 512Mi
```

### Configurer l'Autoscaling

Modifiez les paramètres HPA dans `values.yaml`:

```yaml
autoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 10
  targetCPUUtilizationPercentage: 75
```

## 🗑️ Nettoyage

### Supprimer un Service

```bash
helm uninstall product-service -n backend
```

### Supprimer Tous les Services

```bash
# Backend
helm uninstall product-service order-service inventory-service notification-service api-gateway -n backend

# Frontend
helm uninstall frontend -n frontend
```

### Supprimer les Namespaces (via Terraform)

```bash
cd Devops/terraform
terraform destroy -target=kubernetes_namespace.backend
terraform destroy -target=kubernetes_namespace.frontend
```

## 📝 Structure des Charts Helm

```
Devops/helm/
├── product-service/
│   ├── Chart.yaml              # Metadata du chart
│   ├── values.yaml             # Configuration par défaut
│   └── templates/
│       ├── deployment.yaml     # Déploiement Kubernetes
│       ├── service.yaml        # Service Kubernetes
│       ├── hpa.yaml            # Horizontal Pod Autoscaler
│       └── _helpers.tpl        # Templates helpers
├── order-service/
├── inventory-service/
├── notification-service/
├── api-gateway/
└── frontend/
```

## 🔐 Secrets

Les secrets (MySQL credentials) sont gérés via Terraform:

```hcl
# Devops/terraform/secrets.tf
resource "kubernetes_secret" "mysql_credentials" {
  metadata {
    name      = "mysql-credentials"
    namespace = "backend"
  }
  data = {
    "mysql-password" = var.mysql_password
    "mysql-user"     = "root"
    "mysql-host"     = azurerm_mysql_flexible_server.mysql.fqdn
  }
}
```

Usage dans le pod:

```yaml
env:
  - name: SPRING_DATASOURCE_PASSWORD
    valueFrom:
      secretKeyRef:
        name: mysql-credentials
        key: mysql-password
```

## 🌐 Accès aux Services

Après déploiement, récupérez les IPs publiques:

```bash
# API Gateway
kubectl get svc api-gateway -n backend

# Frontend
kubectl get svc frontend -n frontend
```

Exemple de sortie:
```
NAME          TYPE           EXTERNAL-IP      PORT(S)
api-gateway   LoadBalancer   20.123.45.67     8080:30123/TCP
frontend      LoadBalancer   20.123.45.68     80:30456/TCP
```

Accédez à:
- **Frontend**: http://20.123.45.68
- **API Gateway**: http://20.123.45.67:8080
- **Swagger UI**: http://20.123.45.67:8080/swagger-ui.html

## 🐛 Troubleshooting

### Pod ne démarre pas

```bash
# Voir les logs
kubectl logs <pod-name> -n backend

# Voir les events
kubectl describe pod <pod-name> -n backend

# Vérifier la configuration
kubectl get pod <pod-name> -n backend -o yaml
```

### Image Pull Error

```bash
# Vérifier le role assignment ACR → AKS
az role assignment list --scope /subscriptions/.../acrecomdev12262215

# Vérifier si l'image existe
az acr repository show-tags --name acrecomdev12262215 --repository product-service
```

### Service non accessible

```bash
# Vérifier le service
kubectl get svc -n backend

# Vérifier les endpoints
kubectl get endpoints -n backend

# Tester depuis un pod
kubectl run -it --rm debug --image=busybox --restart=Never -n backend -- wget -O- http://product-service:8080/actuator/health
```

## 📚 Ressources

- [Helm Documentation](https://helm.sh/docs/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Azure AKS Documentation](https://docs.microsoft.com/azure/aks/)
- [Azure Container Registry](https://docs.microsoft.com/azure/container-registry/)
