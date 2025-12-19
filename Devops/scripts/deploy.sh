#!/usr/bin/env bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}================================================${NC}"
echo -e "${GREEN}  E-Commerce Microservices Deployment Script${NC}"
echo -e "${GREEN}================================================${NC}"
echo ""

# Configuration
AKS_CLUSTER_NAME="${AKS_CLUSTER_NAME:-aks-ecom}"
RESOURCE_GROUP="${RESOURCE_GROUP:-rg-ecom-dev}"
ACR_NAME="${ACR_NAME:-acrecomdev12161808}"
NAMESPACE_BACKEND="backend"
NAMESPACE_FRONTEND="frontend"
IMAGE_TAG="${IMAGE_TAG:-latest}"

# Function to print status
print_status() {
    echo -e "${YELLOW}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
print_status "Checking prerequisites..."

if ! command -v az &> /dev/null; then
    print_error "Azure CLI not found. Please install it first."
    exit 1
fi

if ! command -v kubectl &> /dev/null; then
    print_error "kubectl not found. Please install it first."
    exit 1
fi

if ! command -v helm &> /dev/null; then
    print_error "Helm not found. Please install it first."
    exit 1
fi

print_success "All prerequisites met"

# Get AKS credentials
print_status "Getting AKS cluster credentials..."
az aks get-credentials --resource-group "$RESOURCE_GROUP" --name "$AKS_CLUSTER_NAME" --overwrite-existing
print_success "AKS credentials configured"

# Verify cluster connectivity
print_status "Verifying cluster connectivity..."
if ! kubectl cluster-info &> /dev/null; then
    print_error "Cannot connect to AKS cluster"
    exit 1
fi
print_success "Connected to cluster: $(kubectl config current-context)"

# Verify namespaces exist
print_status "Verifying namespaces..."
for ns in $NAMESPACE_BACKEND $NAMESPACE_FRONTEND; do
    if kubectl get namespace "$ns" &> /dev/null; then
        print_success "Namespace '$ns' exists"
    else
        print_error "Namespace '$ns' not found. Please run Terraform first."
        exit 1
    fi
done

# Verify service accounts exist
print_status "Verifying service accounts..."
if kubectl get serviceaccount backend-sa -n $NAMESPACE_BACKEND &> /dev/null; then
    print_success "Service account 'backend-sa' exists"
else
    print_error "Service account 'backend-sa' not found"
    exit 1
fi

# Get ACR login server
print_status "Getting ACR login server..."
ACR_LOGIN_SERVER=$(az acr show --name "$ACR_NAME" --resource-group "$RESOURCE_GROUP" --query loginServer -o tsv)
print_success "ACR server: $ACR_LOGIN_SERVER"

# Deploy backend services
echo ""
print_status "Deploying backend microservices..."

BACKEND_SERVICES=("product-service" "order-service" "inventory-service" "notification-service")

for service in "${BACKEND_SERVICES[@]}"; do
    print_status "Deploying $service..."
    
    helm upgrade --install "$service" "./Devops/helm/$service" \
        --namespace "$NAMESPACE_BACKEND" \
        --set image.repository="${ACR_LOGIN_SERVER}/${service}" \
        --set image.tag="${IMAGE_TAG}" \
        --wait \
        --timeout 5m
    
    if [ $? -eq 0 ]; then
        print_success "$service deployed successfully"
    else
        print_error "Failed to deploy $service"
        exit 1
    fi
done

# Deploy API Gateway
echo ""
print_status "Deploying API Gateway..."
helm upgrade --install api-gateway ./Devops/helm/api-gateway \
    --namespace "$NAMESPACE_BACKEND" \
    --set image.repository="${ACR_LOGIN_SERVER}/api-gateway" \
    --set image.tag="${IMAGE_TAG}" \
    --wait \
    --timeout 5m
print_success "API Gateway deployed successfully"

# Deploy frontend
echo ""
print_status "Deploying frontend..."
helm upgrade --install frontend ./Devops/helm/frontend \
    --namespace "$NAMESPACE_FRONTEND" \
    --set image.repository="${ACR_LOGIN_SERVER}/frontend" \
    --set image.tag="${IMAGE_TAG}" \
    --wait \
    --timeout 5m
print_success "Frontend deployed successfully"

# Display deployment status
echo ""
echo -e "${GREEN}================================================${NC}"
echo -e "${GREEN}  Deployment Summary${NC}"
echo -e "${GREEN}================================================${NC}"
echo ""

print_status "Backend services status:"
kubectl get pods -n "$NAMESPACE_BACKEND" -o wide

echo ""
print_status "Frontend services status:"
kubectl get pods -n "$NAMESPACE_FRONTEND" -o wide

echo ""
print_status "Services:"
kubectl get services -n "$NAMESPACE_BACKEND"
kubectl get services -n "$NAMESPACE_FRONTEND"

echo ""
echo -e "${GREEN}================================================${NC}"
echo -e "${GREEN}  Deployment completed successfully!${NC}"
echo -e "${GREEN}================================================${NC}"
echo ""
print_status "To check logs: kubectl logs -f <pod-name> -n <namespace>"
print_status "To port-forward API Gateway: kubectl port-forward svc/api-gateway 8080:8080 -n backend"
print_status "To port-forward Frontend: kubectl port-forward svc/frontend 4200:80 -n frontend"
