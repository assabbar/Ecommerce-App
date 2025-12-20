#!/bin/bash
# Fix AKS deployment issues

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}════════════════════════════════════════════${NC}"
echo -e "${YELLOW}Fixing AKS Deployment Issues${NC}"
echo -e "${YELLOW}════════════════════════════════════════════${NC}"

# Get environment variables
export AZURE_SUBSCRIPTION_ID="${AZURE_SUBSCRIPTION_ID}"
export AZURE_RESOURCE_GROUP="${AZURE_RESOURCE_GROUP}"
export AKS_CLUSTER_NAME="${AKS_CLUSTER_NAME}"
export AKS_RESOURCE_GROUP="${AKS_RESOURCE_GROUP}"
export ACR_NAME="${ACR_NAME}"
export ACR_LOGIN_SERVER="${ACR_LOGIN_SERVER}"

if [ -z "$ACR_LOGIN_SERVER" ] || [ -z "$ACR_NAME" ]; then
    echo -e "${RED}❌ Missing required environment variables${NC}"
    exit 1
fi

# Get ACR credentials
echo -e "${GREEN}1. Retrieving ACR credentials...${NC}"
ACR_USERNAME=$ACR_NAME
ACR_PASSWORD=$(az acr credential show --name $ACR_NAME --query "passwords[0].value" -o tsv)

if [ -z "$ACR_PASSWORD" ]; then
    echo -e "${RED}❌ Failed to retrieve ACR password${NC}"
    exit 1
fi

echo -e "${GREEN}✓ ACR credentials retrieved${NC}"

# Get AKS credentials
echo ""
echo -e "${GREEN}2. Configuring kubectl for AKS...${NC}"
az aks get-credentials --resource-group $AKS_RESOURCE_GROUP --name $AKS_CLUSTER_NAME --overwrite-existing
echo -e "${GREEN}✓ kubectl configured${NC}"

# Create namespaces if they don't exist
echo ""
echo -e "${GREEN}3. Creating Kubernetes namespaces...${NC}"
kubectl create namespace backend --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace frontend --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -
echo -e "${GREEN}✓ Namespaces created/verified${NC}"

# Create ImagePull secrets in each namespace
echo ""
echo -e "${GREEN}4. Creating ACR ImagePull secrets in namespaces...${NC}"

for NAMESPACE in backend frontend monitoring; do
    echo -e "${YELLOW}   Creating acr-credentials secret in $NAMESPACE...${NC}"
    
    # Delete existing secret if it exists
    kubectl delete secret acr-credentials -n $NAMESPACE --ignore-not-found=true
    
    # Create new secret
    kubectl create secret docker-registry acr-credentials \
        --docker-server=$ACR_LOGIN_SERVER \
        --docker-username=$ACR_USERNAME \
        --docker-password=$ACR_PASSWORD \
        --docker-email=jenkins@ecom.local \
        -n $NAMESPACE
    
    echo -e "${GREEN}   ✓ acr-credentials created in $NAMESPACE${NC}"
done

# Get ACR login details
echo ""
echo -e "${GREEN}5. ACR Configuration:${NC}"
echo -e "   Server: $ACR_LOGIN_SERVER"
echo -e "   Username: $ACR_USERNAME"
echo -e "   ${GREEN}✓ Credentials configured${NC}"

# Delete existing deployments to force pull with new credentials
echo ""
echo -e "${GREEN}6. Redeploying services with new credentials...${NC}"

cd Devops/helm

for service in product-service order-service inventory-service notification-service api-gateway; do
    echo -e "${YELLOW}   Redeploying $service...${NC}"
    helm upgrade --install $service $service/ -n backend
done

echo -e "${YELLOW}   Redeploying frontend...${NC}"
helm upgrade --install frontend frontend/ -n frontend

cd ../..

echo -e "${GREEN}✓ Services redeployed${NC}"

# Wait for deployments
echo ""
echo -e "${GREEN}7. Waiting for services to start...${NC}"
sleep 10

# Check deployment status
echo ""
echo -e "${GREEN}8. Deployment Status:${NC}"
echo ""
echo -e "${YELLOW}Backend Services:${NC}"
kubectl get deployments -n backend
kubectl get pods -n backend

echo ""
echo -e "${YELLOW}Frontend:${NC}"
kubectl get deployments -n frontend
kubectl get pods -n frontend

echo ""
echo -e "${GREEN}════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ Deployment fix completed!${NC}"
echo -e "${GREEN}════════════════════════════════════════════${NC}"
echo ""
echo "Next steps:"
echo "1. Monitor pod status: kubectl get pods -n backend -w"
echo "2. Check pod logs: kubectl logs -f <pod-name> -n backend"
echo "3. Verify ACR connectivity: az acr repository list --name $ACR_NAME"
echo ""
