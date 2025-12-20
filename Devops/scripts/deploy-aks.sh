#!/bin/bash

################################################################################
# Deploy E-Commerce Application to AKS using Helm
# Deploys backend, frontend, and monitoring stack to Azure Kubernetes Service
################################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}E-Commerce Application Deployment to AKS${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════${NC}"
echo ""

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
HELM_DIR="$SCRIPT_DIR/../helm"

# Load environment variables
if [ ! -f "$SCRIPT_DIR/.env" ]; then
    echo -e "${RED}❌ .env file not found in Devops/${NC}"
    echo "   Copy .env.example to .env and configure it"
    exit 1
fi

source "$SCRIPT_DIR/.env"

# Verify required commands
for cmd in kubectl helm az; do
    if ! command -v $cmd &> /dev/null; then
        echo -e "${RED}❌ $cmd is not installed${NC}"
        exit 1
    fi
done

echo -e "${GREEN}✓ Required commands available${NC}"
echo ""

################################################################################
# 1. Authenticate with AKS
################################################################################
echo -e "${YELLOW}1️⃣  Authenticating with AKS...${NC}"

az aks get-credentials \
    --resource-group "$RESOURCE_GROUP" \
    --name "$AKS_CLUSTER_NAME"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Connected to AKS cluster${NC}"
else
    echo -e "${RED}❌ Failed to authenticate with AKS${NC}"
    exit 1
fi

echo ""

################################################################################
# 2. Verify Namespaces
################################################################################
echo -e "${YELLOW}2️⃣  Verifying Kubernetes Namespaces...${NC}"

for ns in "$BACKEND_NAMESPACE" "$FRONTEND_NAMESPACE" "$MONITORING_NAMESPACE"; do
    if kubectl get namespace "$ns" > /dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} Namespace '$ns' exists"
    else
        echo -e "${YELLOW}Creating namespace '$ns'...${NC}"
        kubectl create namespace "$ns"
        echo -e "${GREEN}✅ Namespace '$ns' created${NC}"
    fi
done

echo ""

################################################################################
# 3. Create Docker Registry Secret
################################################################################
echo -e "${YELLOW}3️⃣  Creating Docker Registry Secret...${NC}"

# Get ACR credentials
ACR_CREDENTIALS=$(az acr credential show --resource-group "$RESOURCE_GROUP" --name "$ACR_NAME")
ACR_USERNAME=$(echo "$ACR_CREDENTIALS" | jq -r '.username')
ACR_PASSWORD=$(echo "$ACR_CREDENTIALS" | jq -r '.passwords[0].value')

# Create secret in backend namespace
kubectl create secret docker-registry acr-secret \
    --docker-server="$ACR_LOGIN_SERVER" \
    --docker-username="$ACR_USERNAME" \
    --docker-password="$ACR_PASSWORD" \
    --docker-email="user@example.com" \
    --namespace="$BACKEND_NAMESPACE" \
    --dry-run=client -o yaml | kubectl apply -f -

# Create secret in frontend namespace
kubectl create secret docker-registry acr-secret \
    --docker-server="$ACR_LOGIN_SERVER" \
    --docker-username="$ACR_USERNAME" \
    --docker-password="$ACR_PASSWORD" \
    --docker-email="user@example.com" \
    --namespace="$FRONTEND_NAMESPACE" \
    --dry-run=client -o yaml | kubectl apply -f -

echo -e "${GREEN}✅ Docker registry secrets created${NC}"
echo ""

################################################################################
# 3.5 Create Database Credentials Secrets
################################################################################
echo -e "${YELLOW}3️⃣.5️⃣  Creating Database Credentials Secrets...${NC}"

# Get CosmosDB credentials
echo -e "${BLUE}Retrieving CosmosDB credentials...${NC}"
COSMOSDB_HOST=$(az cosmosdb show --resource-group "$RESOURCE_GROUP" --name "$COSMOSDB_ACCOUNT_NAME" --query "documentEndpoint" -o tsv | sed 's|https://||' | sed 's|/||')
COSMOSDB_USERNAME=$(az cosmosdb keys list --resource-group "$RESOURCE_GROUP" --name "$COSMOSDB_ACCOUNT_NAME" --type connection-strings --query "connectionStrings[0].connectionString" -o tsv | grep -oP '(?<=username=)[^&]*' || echo "cosmosecomdb")
COSMOSDB_KEY=$(az cosmosdb keys list --resource-group "$RESOURCE_GROUP" --name "$COSMOSDB_ACCOUNT_NAME" --type keys --query "primaryMasterKey" -o tsv)

# Build CosmosDB connection URI
COSMOSDB_URI="mongodb+srv://${COSMOSDB_USERNAME}:${COSMOSDB_KEY}@${COSMOSDB_HOST}:10255/ecom-mongo-db?ssl=true&replicaSet=globaldb&maxIdleTimeMS=120000"

# Create CosmosDB secret in backend namespace
kubectl create secret generic cosmosdb-credentials \
    --from-literal=host="$COSMOSDB_HOST" \
    --from-literal=username="$COSMOSDB_USERNAME" \
    --from-literal=password="$COSMOSDB_KEY" \
    --from-literal=uri="$COSMOSDB_URI" \
    --from-literal=database="ecom-mongo-db" \
    --namespace="$BACKEND_NAMESPACE" \
    --dry-run=client -o yaml | kubectl apply -f -

echo -e "${GREEN}✅ CosmosDB secret created${NC}"

# Get MySQL credentials
echo -e "${BLUE}Retrieving MySQL credentials...${NC}"
MYSQL_HOST=$(az mysql flexible-server show --resource-group "$RESOURCE_GROUP" --name "$MYSQL_SERVER_NAME" --query "fullyQualifiedDomainName" -o tsv)
MYSQL_USERNAME="${MYSQL_USERNAME:-adminuser}"
MYSQL_PASSWORD=$(az mysql flexible-server parameter show --resource-group "$RESOURCE_GROUP" --server-name "$MYSQL_SERVER_NAME" --name "require_secure_transport" 2>/dev/null | jq -r '.value' || echo "ChangeMe@123")

# Build MySQL JDBC URL
MYSQL_JDBC_URL="jdbc:mysql://${MYSQL_HOST}:3306/ecom_order_db?allowPublicKeyRetrieval=true&useSSL=false"

# Create MySQL secret in backend namespace
kubectl create secret generic mysql-credentials \
    --from-literal=host="$MYSQL_HOST" \
    --from-literal=username="$MYSQL_USERNAME" \
    --from-literal=password="$MYSQL_PASSWORD" \
    --from-literal=jdbc-url="$MYSQL_JDBC_URL" \
    --namespace="$BACKEND_NAMESPACE" \
    --dry-run=client -o yaml | kubectl apply -f -

echo -e "${GREEN}✅ MySQL secret created${NC}"

# Create secrets in monitoring namespace (for log shipping)
kubectl create secret generic cosmosdb-credentials \
    --from-literal=host="$COSMOSDB_HOST" \
    --from-literal=username="$COSMOSDB_USERNAME" \
    --from-literal=password="$COSMOSDB_KEY" \
    --namespace="$MONITORING_NAMESPACE" \
    --dry-run=client -o yaml | kubectl apply -f - 2>/dev/null || true

echo ""

################################################################################
# 4. Deploy Monitoring Stack (Prometheus, Grafana, Loki)
################################################################################
echo -e "${YELLOW}4️⃣  Deploying Monitoring Stack...${NC}"

# Add Helm repositories
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo add jetstack https://charts.jetstack.io
helm repo update

# Deploy Prometheus
echo -e "${BLUE}Deploying Prometheus...${NC}"
helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
    --namespace "$MONITORING_NAMESPACE" \
    --values "$HELM_DIR/../monitoring/prometheus-values.yaml" \
    --wait

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Prometheus deployed${NC}"
else
    echo -e "${YELLOW}⚠️  Prometheus deployment completed with warnings${NC}"
fi

# Deploy Grafana
echo -e "${BLUE}Deploying Grafana...${NC}"
helm upgrade --install grafana grafana/grafana \
    --namespace "$MONITORING_NAMESPACE" \
    --set adminPassword="$GRAFANA_ADMIN_PASSWORD" \
    --values "$HELM_DIR/../monitoring/grafana-values.yaml" \
    --wait

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Grafana deployed${NC}"
else
    echo -e "${YELLOW}⚠️  Grafana deployment completed with warnings${NC}"
fi

# Deploy Loki
echo -e "${BLUE}Deploying Loki...${NC}"
helm upgrade --install loki grafana/loki-stack \
    --namespace "$MONITORING_NAMESPACE" \
    --values "$HELM_DIR/../monitoring/loki-values.yaml" \
    --wait

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Loki deployed${NC}"
else
    echo -e "${YELLOW}⚠️  Loki deployment completed with warnings${NC}"
fi

echo ""

################################################################################
# 5. Deploy Backend Services
################################################################################
echo -e "${YELLOW}5️⃣  Deploying Backend Services...${NC}"

SERVICES=(
    "product-service"
    "order-service"
    "inventory-service"
    "notification-service"
    "api-gateway"
)

for service in "${SERVICES[@]}"; do
    echo -e "${BLUE}Deploying $service...${NC}"
    
    helm upgrade --install "$service" "$HELM_DIR/$service" \
        --namespace "$BACKEND_NAMESPACE" \
        --set image.repository="$ACR_LOGIN_SERVER/malak-$service" \
        --set image.tag="$IMAGE_TAG" \
        --set image.pullPolicy="$IMAGE_PULL_POLICY" \
        --set resources.requests.memory="256Mi" \
        --set resources.limits.memory="512Mi" \
        --set autoscaling.minReplicas="$HPA_MIN_REPLICAS" \
        --set autoscaling.maxReplicas="$HPA_MAX_REPLICAS" \
        --set autoscaling.targetCPUUtilizationPercentage="$HPA_TARGET_CPU_PERCENT" \
        --wait
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ $service deployed${NC}"
    else
        echo -e "${RED}❌ $service deployment failed${NC}"
        exit 1
    fi
done

echo ""

################################################################################
# 6. Deploy Frontend
################################################################################
echo -e "${YELLOW}6️⃣  Deploying Frontend...${NC}"

helm upgrade --install frontend "$HELM_DIR/frontend" \
    --namespace "$FRONTEND_NAMESPACE" \
    --set image.repository="$ACR_LOGIN_SERVER/malak-frontend" \
    --set image.tag="$IMAGE_TAG" \
    --set image.pullPolicy="$IMAGE_PULL_POLICY" \
    --set replicaCount="$HPA_MIN_REPLICAS" \
    --set ingress.enabled="true" \
    --set ingress.className="nginx" \
    --wait

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Frontend deployed${NC}"
else
    echo -e "${RED}❌ Frontend deployment failed${NC}"
    exit 1
fi

echo ""

################################################################################
# 7. Verify Deployments
################################################################################
echo -e "${YELLOW}7️⃣  Verifying Deployments...${NC}"

echo -e "${BLUE}Backend Services:${NC}"
kubectl get deployments -n "$BACKEND_NAMESPACE"

echo ""
echo -e "${BLUE}Frontend:${NC}"
kubectl get deployments -n "$FRONTEND_NAMESPACE"

echo ""
echo -e "${BLUE}Monitoring Stack:${NC}"
kubectl get deployments -n "$MONITORING_NAMESPACE"

echo ""

################################################################################
# 8. Get Access Information
################################################################################
echo -e "${YELLOW}8️⃣  Deployment Complete!${NC}"
echo ""
echo -e "${GREEN}════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ Application Deployed Successfully${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════${NC}"
echo ""

echo "Access Information:"
echo ""

# Get API Gateway LoadBalancer IP
echo -e "${BLUE}API Gateway (LoadBalancer):${NC}"
GATEWAY_IP=$(kubectl get svc -n "$BACKEND_NAMESPACE" api-gateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "pending...")
echo "  URL: http://${GATEWAY_IP}:9000"
echo ""

# Get Grafana Port
echo -e "${BLUE}Grafana:${NC}"
GRAFANA_PORT=$(kubectl get svc -n "$MONITORING_NAMESPACE" grafana -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null || echo "pending...")
echo "  Port: $GRAFANA_PORT"
echo "  Username: admin"
echo "  Password: (check .env file)"
echo ""

# Loki
echo -e "${BLUE}Loki (Logs):${NC}"
echo "  Endpoint: http://loki.$MONITORING_NAMESPACE.svc.cluster.local:3100"
echo ""

echo "Next Steps:"
echo "  1. Wait for all pods to be in Running state:"
echo "     kubectl get pods -n $BACKEND_NAMESPACE -w"
echo ""
echo "  2. Check service logs:"
echo "     kubectl logs -f deployment/product-service -n $BACKEND_NAMESPACE"
echo ""
echo "  3. Port-forward to services (if needed):"
echo "     kubectl port-forward svc/api-gateway 9000:9000 -n $BACKEND_NAMESPACE"
echo ""
echo "  4. Monitor in Grafana:"
echo "     Access at port $GRAFANA_PORT and import dashboards"
echo ""
