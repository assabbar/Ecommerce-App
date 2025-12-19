#!/usr/bin/env pwsh
# PowerShell deployment script for E-Commerce Microservices

$ErrorActionPreference = "Stop"

Write-Host "================================================" -ForegroundColor Green
Write-Host "  E-Commerce Microservices Deployment Script" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Green
Write-Host ""

# Configuration
$AKS_CLUSTER_NAME = if ($env:AKS_CLUSTER_NAME) { $env:AKS_CLUSTER_NAME } else { "aks-ecom" }
$RESOURCE_GROUP = if ($env:RESOURCE_GROUP) { $env:RESOURCE_GROUP } else { "rg-ecom-dev" }
$ACR_NAME = if ($env:ACR_NAME) { $env:ACR_NAME } else { "acrecomdev12161808" }
$NAMESPACE_BACKEND = "backend"
$NAMESPACE_FRONTEND = "frontend"
$IMAGE_TAG = if ($env:IMAGE_TAG) { $env:IMAGE_TAG } else { "latest" }

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
}

# Check prerequisites
Print-Status "Checking prerequisites..."

if (!(Get-Command az -ErrorAction SilentlyContinue)) {
    Print-Error "Azure CLI not found. Please install it first."
    exit 1
}

if (!(Get-Command kubectl -ErrorAction SilentlyContinue)) {
    Print-Error "kubectl not found. Please install it first."
    exit 1
}

if (!(Get-Command helm -ErrorAction SilentlyContinue)) {
    Print-Error "Helm not found. Please install it first."
    exit 1
}

Print-Success "All prerequisites met"

# Get AKS credentials
Print-Status "Getting AKS cluster credentials..."
az aks get-credentials --resource-group $RESOURCE_GROUP --name $AKS_CLUSTER_NAME --overwrite-existing
Print-Success "AKS credentials configured"

# Verify cluster connectivity
Print-Status "Verifying cluster connectivity..."
try {
    kubectl cluster-info | Out-Null
    Print-Success "Connected to cluster: $(kubectl config current-context)"
} catch {
    Print-Error "Cannot connect to AKS cluster"
    exit 1
}

# Verify namespaces
Print-Status "Verifying namespaces..."
foreach ($ns in @($NAMESPACE_BACKEND, $NAMESPACE_FRONTEND)) {
    try {
        kubectl get namespace $ns | Out-Null
        Print-Success "Namespace '$ns' exists"
    } catch {
        Print-Error "Namespace '$ns' not found. Please run Terraform first."
        exit 1
    }
}

# Get ACR login server
Print-Status "Getting ACR login server..."
$ACR_LOGIN_SERVER = az acr show --name $ACR_NAME --resource-group $RESOURCE_GROUP --query loginServer -o tsv
Print-Success "ACR server: $ACR_LOGIN_SERVER"

# Deploy backend services
Write-Host ""
Print-Status "Deploying backend microservices..."

$BACKEND_SERVICES = @("product-service", "order-service", "inventory-service", "notification-service")

foreach ($service in $BACKEND_SERVICES) {
    Print-Status "Deploying $service..."
    
    helm upgrade --install $service "./Devops/helm/$service" `
        --namespace $NAMESPACE_BACKEND `
        --set image.repository="${ACR_LOGIN_SERVER}/${service}" `
        --set image.tag=$IMAGE_TAG `
        --wait `
        --timeout 5m
    
    if ($LASTEXITCODE -eq 0) {
        Print-Success "$service deployed successfully"
    } else {
        Print-Error "Failed to deploy $service"
        exit 1
    }
}

# Deploy API Gateway
Write-Host ""
Print-Status "Deploying API Gateway..."
helm upgrade --install api-gateway ./Devops/helm/api-gateway `
    --namespace $NAMESPACE_BACKEND `
    --set image.repository="${ACR_LOGIN_SERVER}/api-gateway" `
    --set image.tag=$IMAGE_TAG `
    --wait `
    --timeout 5m
Print-Success "API Gateway deployed successfully"

# Deploy frontend
Write-Host ""
Print-Status "Deploying frontend..."
helm upgrade --install frontend ./Devops/helm/frontend `
    --namespace $NAMESPACE_FRONTEND `
    --set image.repository="${ACR_LOGIN_SERVER}/frontend" `
    --set image.tag=$IMAGE_TAG `
    --wait `
    --timeout 5m
Print-Success "Frontend deployed successfully"

# Display deployment status
Write-Host ""
Write-Host "================================================" -ForegroundColor Green
Write-Host "  Deployment Summary" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Green
Write-Host ""

Print-Status "Backend services status:"
kubectl get pods -n $NAMESPACE_BACKEND -o wide

Write-Host ""
Print-Status "Frontend services status:"
kubectl get pods -n $NAMESPACE_FRONTEND -o wide

Write-Host ""
Print-Status "Services:"
kubectl get services -n $NAMESPACE_BACKEND
kubectl get services -n $NAMESPACE_FRONTEND

Write-Host ""
Write-Host "================================================" -ForegroundColor Green
Write-Host "  Deployment completed successfully!" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Green
Write-Host ""
Print-Status "To check logs: kubectl logs -f <pod-name> -n <namespace>"
Print-Status "To port-forward API Gateway: kubectl port-forward svc/api-gateway 8080:8080 -n backend"
Print-Status "To port-forward Frontend: kubectl port-forward svc/frontend 4200:80 -n frontend"
