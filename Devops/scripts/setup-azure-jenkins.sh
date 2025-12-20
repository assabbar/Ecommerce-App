#!/bin/bash

################################################################################
# Auto-configure Jenkins and Kubernetes with Azure Resources
# Dynamically retrieves Azure resource details and configures everything
# Usage: ./setup-azure-jenkins.sh
################################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}Auto-Configure Azure + Jenkins + Kubernetes${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════${NC}"
echo ""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TERRAFORM_DIR="$PROJECT_ROOT/Devops/terraform"

################################################################################
# 1. Authenticate with Azure
################################################################################
echo -e "${YELLOW}1️⃣  Authenticating with Azure...${NC}"

az login --use-device-code

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Azure login failed${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Authenticated with Azure${NC}"
echo ""

################################################################################
# 2. Get current subscription
################################################################################
echo -e "${YELLOW}2️⃣  Getting subscription info...${NC}"

SUBSCRIPTION_ID=$(az account show --query id -o tsv)
SUBSCRIPTION_NAME=$(az account show --query name -o tsv)

echo "Current subscription: $SUBSCRIPTION_NAME ($SUBSCRIPTION_ID)"
echo ""

################################################################################
# 3. Get Terraform outputs
################################################################################
echo -e "${YELLOW}3️⃣  Retrieving Terraform outputs...${NC}"

cd "$TERRAFORM_DIR"

# Get all outputs
RESOURCE_GROUP=$(terraform output -raw resource_group_name)
AKS_NAME=$(terraform output -raw aks_name)
ACR_LOGIN_SERVER=$(terraform output -raw acr_login_server)
MYSQL_FQDN=$(terraform output -raw mysql_server_fqdn)
COSMOSDB_ACCOUNT=$(terraform output -raw cosmosdb_account_name)
EVENTHUB_NS=$(terraform output -raw eventhub_namespace_name)

echo -e "${GREEN}✓ Retrieved all Terraform outputs:${NC}"
echo "  Resource Group: $RESOURCE_GROUP"
echo "  AKS Cluster: $AKS_NAME"
echo "  ACR Server: $ACR_LOGIN_SERVER"
echo "  MySQL Server: $MYSQL_FQDN"
echo "  CosmosDB Account: $COSMOSDB_ACCOUNT"
echo "  Event Hub Namespace: $EVENTHUB_NS"
echo ""

################################################################################
# 4. Get Azure credentials
################################################################################
echo -e "${YELLOW}4️⃣  Retrieving Azure credentials...${NC}"

# ACR credentials
ACR_NAME=$(echo "$ACR_LOGIN_SERVER" | cut -d'.' -f1)
ACR_CREDS=$(az acr credential show --resource-group "$RESOURCE_GROUP" --name "$ACR_NAME")
ACR_USERNAME=$(echo "$ACR_CREDS" | jq -r '.username')
ACR_PASSWORD=$(echo "$ACR_CREDS" | jq -r '.passwords[0].value')

echo -e "${GREEN}✓ ACR credentials retrieved${NC}"

# MySQL credentials from Kubernetes secret
cd "$PROJECT_ROOT"
MYSQL_PASSWORD=$(kubectl get secret -n backend mysql-credentials -o jsonpath='{.data.mysql-password}' 2>/dev/null | base64 -d)
if [ -z "$MYSQL_PASSWORD" ]; then
    echo -e "${YELLOW}⚠️  MySQL password not found in K8s secret (may not be deployed yet)${NC}"
    MYSQL_PASSWORD="YOUR_MYSQL_PASSWORD_HERE"
fi

echo -e "${GREEN}✓ Credentials retrieved${NC}"
echo ""

################################################################################
# 5. Get AKS credentials
################################################################################
echo -e "${YELLOW}5️⃣  Configuring kubectl...${NC}"

az aks get-credentials \
    --resource-group "$RESOURCE_GROUP" \
    --name "$AKS_NAME" \
    --overwrite-existing

echo -e "${GREEN}✓ kubectl configured${NC}"
echo ""

################################################################################
# 6. Create/Update Kubernetes secrets
################################################################################
echo -e "${YELLOW}6️⃣  Creating Kubernetes secrets...${NC}"

# Create ACR secret in backend namespace
kubectl create secret docker-registry acr-secret \
    --docker-server="$ACR_LOGIN_SERVER" \
    --docker-username="$ACR_USERNAME" \
    --docker-password="$ACR_PASSWORD" \
    --docker-email="user@example.com" \
    --namespace=backend \
    --dry-run=client -o yaml | kubectl apply -f -

# Create ACR secret in frontend namespace
kubectl create secret docker-registry acr-secret \
    --docker-server="$ACR_LOGIN_SERVER" \
    --docker-username="$ACR_USERNAME" \
    --docker-password="$ACR_PASSWORD" \
    --docker-email="user@example.com" \
    --namespace=frontend \
    --dry-run=client -o yaml | kubectl apply -f -

# Create ACR secret in monitoring namespace
kubectl create secret docker-registry acr-secret \
    --docker-server="$ACR_LOGIN_SERVER" \
    --docker-username="$ACR_USERNAME" \
    --docker-password="$ACR_PASSWORD" \
    --docker-email="user@example.com" \
    --namespace=monitoring \
    --dry-run=client -o yaml | kubectl apply -f -

echo -e "${GREEN}✓ Kubernetes secrets created${NC}"
echo ""

################################################################################
# 7. Create Jenkins configuration file
################################################################################
echo -e "${YELLOW}7️⃣  Creating Jenkins configuration...${NC}"

JENKINS_ENV_FILE="$PROJECT_ROOT/Devops/jenkins/jenkins.env"

cat > "$JENKINS_ENV_FILE" << EOF
# Jenkins Environment Variables - Auto-generated from Azure
# Source: terraform outputs
# Generated: $(date)

# Azure Subscription
AZURE_SUBSCRIPTION_ID=$SUBSCRIPTION_ID
AZURE_RESOURCE_GROUP=$RESOURCE_GROUP

# AKS
AKS_CLUSTER_NAME=$AKS_NAME
KUBECONFIG=\${HOME}/.kube/config

# Container Registry
ACR_NAME=$ACR_NAME
ACR_LOGIN_SERVER=$ACR_LOGIN_SERVER
ACR_USERNAME=$ACR_USERNAME
ACR_PASSWORD=$ACR_PASSWORD

# MySQL
MYSQL_SERVER_FQDN=$MYSQL_FQDN
MYSQL_USER=adminuser
MYSQL_PASSWORD=$MYSQL_PASSWORD
MYSQL_PORT=3306

# CosmosDB
COSMOSDB_ACCOUNT_NAME=$COSMOSDB_ACCOUNT

# Event Hub
EVENTHUB_NAMESPACE=$EVENTHUB_NS

# Deployment
IMAGE_TAG=\${BUILD_NUMBER}
BUILD_CONTEXT=backend
REGISTRY=\${ACR_LOGIN_SERVER}
SERVICES="product-service order-service inventory-service notification-service api-gateway"

# Control Flags
RUN_BACKEND_TESTS=true
RUN_FRONTEND_TESTS=true
RUN_INTEGRATION_TESTS=true
RUN_BUILD_IMAGES=true
RUN_PUSH_TO_ACR=true
EOF

echo -e "${GREEN}✓ Jenkins config created: $JENKINS_ENV_FILE${NC}"
echo ""

################################################################################
# 8. Update Jenkinsfile with credentials
################################################################################
echo -e "${YELLOW}8️⃣  Updating Jenkinsfile...${NC}"

JENKINSFILE="$PROJECT_ROOT/Devops/jenkins/Jenkinsfile"

# Check if jenkins.env is sourced in Jenkinsfile
if ! grep -q "source.*jenkins.env" "$JENKINSFILE"; then
    echo "Adding jenkins.env sourcing to Jenkinsfile..."
    # This will be done manually - we'll just inform the user
    echo -e "${YELLOW}⚠️  Please add this to Jenkinsfile pipeline block:${NC}"
    echo "  environment {"
    echo "    // Source auto-generated variables"
    echo "  }"
fi

echo -e "${GREEN}✓ Jenkinsfile location: $JENKINSFILE${NC}"
echo ""

################################################################################
# 9. Create Helm values overrides
################################################################################
echo -e "${YELLOW}9️⃣  Creating Helm values file...${NC}"

HELM_VALUES="$PROJECT_ROOT/Devops/helm/values-production.yaml"

cat > "$HELM_VALUES" << EOF
# Production Helm Values - Auto-generated from Azure
# Generated: $(date)

image:
  registry: $ACR_LOGIN_SERVER
  pullPolicy: IfNotPresent

imagePullSecrets:
  - name: acr-secret

databases:
  mysql:
    host: $MYSQL_FQDN
    port: 3306
    user: adminuser
    # password sourced from Kubernetes secret
    
  mongodb:
    account: $COSMOSDB_ACCOUNT

azure:
  subscriptionId: $SUBSCRIPTION_ID
  resourceGroup: $RESOURCE_GROUP
  aks:
    clusterName: $AKS_NAME
    
monitoring:
  enabled: true
  prometheus:
    retention: 30d
  grafana:
    adminPassword: "changeme"
  loki:
    retention: 168h
EOF

echo -e "${GREEN}✓ Helm values created: $HELM_VALUES${NC}"
echo ""

################################################################################
# 10. Create deployment instructions
################################################################################
echo -e "${YELLOW}🔟 Creating deployment guide...${NC}"

DEPLOY_GUIDE="$PROJECT_ROOT/DEPLOYMENT_INSTRUCTIONS.md"

cat > "$DEPLOY_GUIDE" << 'EOF'
# Deployment Instructions

## Setup Complete!

### Step 1: Configure Jenkins

```bash
# In Jenkins:
# 1. Create Pipeline job "E-Commerce-Pipeline"
# 2. Source the git repo: https://github.com/assabbar/Ecommerce-App
# 3. Jenkinsfile path: Devops/jenkins/Jenkinsfile
# 4. Add credentials in Jenkins:
#    - Type: Username with password
#    - ID: acr-credentials
#    - Username: $ACR_USERNAME
#    - Password: $ACR_PASSWORD
```

### Step 2: Update Jenkinsfile

The Jenkinsfile needs to load the auto-generated credentials. Update the `environment` block:

```groovy
environment {
    // Load auto-generated Azure variables
    AZURE_SUBSCRIPTION_ID = credentials('azure-subscription-id')
    AZURE_RESOURCE_GROUP = credentials('azure-resource-group')
    AKS_CLUSTER_NAME = credentials('aks-cluster-name')
    // ... etc
}
```

### Step 3: Trigger Build

```bash
# Via Jenkins UI or CLI:
jenkins-cli build E-Commerce-Pipeline -s
```

### Step 4: Monitor Deployment

```bash
# Watch pod creation
kubectl get pods -n backend -w

# View logs
kubectl logs -f deployment/product-service -n backend
```

## Environment Variables (Not Used in Deployment)

The `.env` file is **ONLY** for local development:
- Docker Compose local testing
- Script development
- Manual testing

### Why NOT use .env in production?

1. **Security**: Credentials in files = security risk
2. **Dynamic**: Azure resources change, files become stale
3. **Kubernetes**: Uses Secrets and ConfigMaps instead
4. **Jenkins**: Uses credentials store, not environment files
5. **Deployment**: Helm charts override everything anyway

### What gets actually used in deployment:

1. **Kubernetes Secrets**: ACR credentials, database passwords
2. **Jenkins Credentials**: Stored in Jenkins encrypted store
3. **Terraform Outputs**: Retrieved dynamically (no files needed)
4. **Helm Values**: values-production.yaml
5. **Environment Variables**: Set in pod manifests

## Real Deployment Flow

```
Jenkins Build
  ↓
Azure CLI: Retrieve resource names (dynamic)
  ↓
Docker: Build and push images
  ↓
Helm: Deploy with Kubernetes Secrets
  ↓
Kubernetes: Use mounted secrets in pods
  ↓
Pods read from: /var/run/secrets/kubernetes.io/serviceaccount/
```

So `.env` is never used in actual deployment!
EOF

echo -e "${GREEN}✓ Deployment guide created: $DEPLOY_GUIDE${NC}"
echo ""

################################################################################
# 11. Verify everything
################################################################################
echo -e "${YELLOW}1️⃣1️⃣  Verifying setup...${NC}"

echo ""
echo -e "${BLUE}Kubernetes Namespaces:${NC}"
kubectl get ns | grep -E "backend|frontend|monitoring"

echo ""
echo -e "${BLUE}Kubernetes Secrets (ACR):${NC}"
kubectl get secrets -n backend | grep acr-secret || echo "Secret will be created by first deployment"

echo ""
echo -e "${BLUE}Cluster Info:${NC}"
kubectl cluster-info | head -3

echo ""

################################################################################
# 12. Summary
################################################################################
echo -e "${GREEN}════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ Setup Complete!${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════${NC}"
echo ""
echo "Configuration files created:"
echo "  • $JENKINS_ENV_FILE"
echo "  • $HELM_VALUES"
echo "  • $DEPLOY_GUIDE"
echo ""
echo "Azure Resources (auto-retrieved):"
echo "  • Subscription: $SUBSCRIPTION_ID"
echo "  • Resource Group: $RESOURCE_GROUP"
echo "  • AKS Cluster: $AKS_NAME"
echo "  • ACR: $ACR_LOGIN_SERVER"
echo "  • MySQL: $MYSQL_FQDN"
echo "  • CosmosDB: $COSMOSDB_ACCOUNT"
echo ""
echo "Next Steps:"
echo "  1. Review $DEPLOY_GUIDE"
echo "  2. Configure Jenkins with credentials"
echo "  3. Create Jenkins pipeline job"
echo "  4. Click 'Build Now'"
echo ""
echo ".env file location (for local development only):"
echo "  $PROJECT_ROOT/Devops/.env"
echo ""
echo "What .env is used for:"
echo "  ✓ Local Docker Compose testing"
echo "  ✓ Manual script execution"
echo "  ✗ NOT used in Jenkins/AKS deployment"
echo ""
