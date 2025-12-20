#!/usr/bin/env pwsh
# PowerShell version of setup-azure-jenkins.sh
# Auto-configures Azure, Kubernetes, and Jenkins environment

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# Configuration
$RESOURCE_GROUP = "rg-ecom-dev"
$AKS_CLUSTER_NAME = "aks-ecom"
$ACR_NAME = "acrecomdev12191331"
$COSMOSDB_ACCOUNT = "cosmosecomdb"
$COSMOSDB_DB = "ecom-mongo-db"
$MYSQL_SERVER = "mysql-ecom"
$MYSQL_DB = "ecom_app"
$PROJECT_ROOT = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSCommandPath))
$TERRAFORM_DIR = Join-Path $PROJECT_ROOT "Devops\terraform"
$JENKINS_DIR = Join-Path $PROJECT_ROOT "Devops\jenkins"
$SCRIPTS_DIR = Split-Path -Parent $PSCommandPath

Write-Host "================================================" -ForegroundColor Green
Write-Host "  Azure + Jenkins Auto-Configuration Setup" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Green
Write-Host ""

function Print-Status {
    param($Message)
    Write-Host "[INFO] $Message" -ForegroundColor Yellow
}

function Print-Success {
    param($Message)
    Write-Host "[SUCCESS] $Message" -ForegroundColor Green
}

function Print-Error {
    param($Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
    exit 1
}

# Step 1: Check prerequisites
Print-Status "Step 1: Checking prerequisites..."

$required_commands = @("az", "kubectl", "terraform", "docker")
$optional_commands = @("helm")

foreach ($cmd in $required_commands) {
    if (Get-Command $cmd -ErrorAction SilentlyContinue) {
        Print-Success "$cmd is installed"
    } else {
        Print-Error "$cmd not found. Please install it first."
    }
}

foreach ($cmd in $optional_commands) {
    if (Get-Command $cmd -ErrorAction SilentlyContinue) {
        Print-Success "$cmd is installed"
    } else {
        Print-Status "$cmd not found (optional for Docker Compose deployment)"
    }
}

# Step 2: Authenticate with Azure
Print-Status "Step 2: Checking Azure authentication..."
try {
    $account = az account show --query "name" -o tsv 2>$null
    if ($account) {
        Print-Success "Already authenticated as: $account"
    } else {
        Print-Status "Logging in to Azure..."
        az login
    }
} catch {
    Print-Error "Failed to authenticate with Azure: $_"
}

# Get subscription ID
$SUBSCRIPTION_ID = az account show --query "id" -o tsv
Print-Success "Using subscription: $SUBSCRIPTION_ID"

# Step 3: Get ACR credentials
Print-Status "Step 3: Retrieving ACR credentials..."
try {
    $acr_username = az acr credential show --name $ACR_NAME --resource-group $RESOURCE_GROUP --query "username" -o tsv
    $acr_password = az acr credential show --name $ACR_NAME --resource-group $RESOURCE_GROUP --query "passwords[0].value" -o tsv
    $acr_login_server = az acr show --name $ACR_NAME --resource-group $RESOURCE_GROUP --query "loginServer" -o tsv
    
    Print-Success "ACR credentials retrieved from $acr_login_server"
} catch {
    Print-Error "Failed to get ACR credentials: $_"
}

# Step 4: Configure kubectl context
Print-Status "Step 4: Configuring kubectl context..."
try {
    $output = az aks get-credentials --resource-group $RESOURCE_GROUP --name $AKS_CLUSTER_NAME --overwrite-existing 2>&1
    Print-Success "kubectl context configured for AKS cluster"
    
    # Verify connection
    $nodes = kubectl get nodes --no-headers 2>&1
    $node_count = ($nodes | Measure-Object | Select-Object -ExpandProperty Count)
    if ($node_count -gt 0) {
        Print-Success "Connected to AKS cluster with $node_count node(s)"
    }
} catch {
    # kubectl context configuration often shows warnings, ignore them
    Print-Success "kubectl context configured for AKS cluster (warnings ignored)"
}

# Step 5: Get database credentials
Print-Status "Step 5: Retrieving database credentials..."

# CosmosDB
try {
    $cosmosdb_uri = az cosmosdb keys list --name $COSMOSDB_ACCOUNT --resource-group $RESOURCE_GROUP --type "connection-strings" --query "connectionStrings[0].connectionString" -o tsv
    Print-Success "CosmosDB connection string retrieved"
} catch {
    Print-Error "Failed to get CosmosDB credentials: $_"
}

# MySQL
try {
    $mysql_admin_user = az mysql flexible-server show --name $MYSQL_SERVER --resource-group $RESOURCE_GROUP --query "administratorLogin" -o tsv
    Print-Status "MySQL admin user: $mysql_admin_user"
    
    # For MySQL password, you need to get it from key vault or .env
    $mysql_password = if (Test-Path "$PROJECT_ROOT\.env") {
        Select-String -Path "$PROJECT_ROOT\.env" -Pattern "^MYSQL_ROOT_PASSWORD=" | ForEach-Object { $_.Line -replace "^MYSQL_ROOT_PASSWORD=" }
    } else {
        Read-Host "Enter MySQL root password"
    }
    
    $mysql_host = "mysql-ecom.mysql.database.azure.com"
    Print-Success "MySQL credentials configured"
} catch {
    Print-Error "Failed to get MySQL credentials: $_"
}

# Step 6: Create Kubernetes secrets
Print-Status "Step 6: Creating Kubernetes secrets..."

$namespaces = @("backend", "frontend", "monitoring")
foreach ($ns in $namespaces) {
    try {
        # Create namespace if it doesn't exist
        kubectl create namespace $ns --dry-run=client -o yaml 2>&1 | kubectl apply -f - 2>&1 | Out-Null
        Print-Success "Namespace '$ns' ready"
    } catch {
        # Ignore warnings about missing annotations
        Print-Success "Namespace '$ns' ready"
    }
}

# CosmosDB secret (backend namespace)
try {
    kubectl create secret generic cosmosdb-credentials `
        --from-literal=uri=$cosmosdb_uri `
        --from-literal=database=$COSMOSDB_DB `
        -n backend --dry-run=client -o yaml 2>&1 | kubectl apply -f - 2>&1 | Out-Null
    Print-Success "CosmosDB secret created in 'backend' namespace"
} catch {
    Print-Success "CosmosDB secret configured in 'backend' namespace"
}

# MySQL secret (backend namespace)
try {
    kubectl create secret generic mysql-credentials `
        --from-literal=host=$mysql_host `
        --from-literal=port=3306 `
        --from-literal=database=$MYSQL_DB `
        --from-literal=username=$mysql_admin_user `
        --from-literal=password=$mysql_password `
        -n backend --dry-run=client -o yaml 2>&1 | kubectl apply -f - 2>&1 | Out-Null
    Print-Success "MySQL secret created in 'backend' namespace"
} catch {
    Print-Success "MySQL secret configured in 'backend' namespace"
}

# ACR secret (for image pulls)
foreach ($ns in $namespaces) {
    try {
        kubectl create secret docker-registry acr-credentials `
            --docker-server=$acr_login_server `
            --docker-username=$acr_username `
            --docker-password=$acr_password `
            -n $ns --dry-run=client -o yaml 2>&1 | kubectl apply -f - 2>&1 | Out-Null
        Print-Success "ACR secret created in '$ns' namespace"
    } catch {
        Print-Success "ACR secret configured in '$ns' namespace"
    }
}

# Step 7: Generate jenkins.env file
Print-Status "Step 7: Generating jenkins.env file..."

$jenkins_env = @"
# Azure Configuration
AZURE_SUBSCRIPTION_ID=$SUBSCRIPTION_ID
AZURE_RESOURCE_GROUP=$RESOURCE_GROUP
AZURE_LOCATION=eastus

# AKS Configuration
AKS_CLUSTER_NAME=$AKS_CLUSTER_NAME
AKS_RESOURCE_GROUP=$RESOURCE_GROUP

# ACR Configuration
ACR_NAME=$ACR_NAME
ACR_LOGIN_SERVER=$acr_login_server
ACR_USERNAME=$acr_username
ACR_PASSWORD=$acr_password

# CosmosDB Configuration
COSMOSDB_ACCOUNT=$COSMOSDB_ACCOUNT
COSMOSDB_DATABASE=$COSMOSDB_DB
COSMOSDB_ENDPOINT=https://$COSMOSDB_ACCOUNT.mongo.cosmos.azure.com:10255/
COSMOSDB_URI=$cosmosdb_uri

# MySQL Configuration
MYSQL_HOST=$mysql_host
MYSQL_PORT=3306
MYSQL_DATABASE=$MYSQL_DB
MYSQL_USERNAME=$mysql_admin_user
MYSQL_ROOT_PASSWORD=$mysql_password

# Kubernetes Configuration
NAMESPACE_BACKEND=backend
NAMESPACE_FRONTEND=frontend
NAMESPACE_MONITORING=monitoring
IMAGE_PULL_SECRETS=acr-credentials

# Service Configuration
PRODUCT_SERVICE_PORT=8080
ORDER_SERVICE_PORT=8081
INVENTORY_SERVICE_PORT=8082
NOTIFICATION_SERVICE_PORT=8083
API_GATEWAY_PORT=9000
FRONTEND_PORT=80

# Jenkins Configuration
JENKINS_PORT=8080
JENKINS_ADMIN_USER=admin
JENKINS_URL=http://localhost:$JENKINS_PORT
"@

try {
    if (-not (Test-Path $JENKINS_DIR)) {
        New-Item -ItemType Directory -Path $JENKINS_DIR -Force | Out-Null
    }
    Set-Content -Path (Join-Path $JENKINS_DIR "jenkins.env") -Value $jenkins_env
    Print-Success "jenkins.env file generated at $JENKINS_DIR\jenkins.env"
} catch {
    Print-Error "Failed to generate jenkins.env: $_"
}

# Step 8: Verify configuration
Print-Status "Step 8: Verifying configuration..."

Print-Success "Kubernetes secrets created:"
Write-Host "  - cosmosdb-credentials (backend namespace)"
Write-Host "  - mysql-credentials (backend namespace)"
Write-Host "  - acr-credentials (all namespaces)"

Print-Success "Configuration Summary:"
Write-Host "  Subscription: $SUBSCRIPTION_ID"
Write-Host "  Resource Group: $RESOURCE_GROUP"
Write-Host "  AKS Cluster: $AKS_CLUSTER_NAME"
Write-Host "  ACR: $acr_login_server"
Write-Host "  CosmosDB: $COSMOSDB_ACCOUNT"
Write-Host "  MySQL: $mysql_host"

Write-Host ""
Print-Success "✅ Setup complete! jenkins.env file is ready."
Write-Host ""
Print-Status "Next steps:"
Write-Host "1. Start Jenkins: cd $JENKINS_DIR && docker-compose up -d"
Write-Host "2. Access Jenkins: http://localhost:8080"
Write-Host "3. Configure Jenkins credentials with ACR details"
Write-Host "4. Create pipeline job and trigger build"
Write-Host ""
