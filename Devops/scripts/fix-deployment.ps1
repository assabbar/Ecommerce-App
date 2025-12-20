# Fix AKS Deployment Issues - PowerShell Version
# This script fixes ImagePullBackOff errors and redeploys services

param(
    [string]$SubscriptionId = $env:AZURE_SUBSCRIPTION_ID,
    [string]$ResourceGroup = $env:AZURE_RESOURCE_GROUP,
    [string]$AksClusterName = $env:AKS_CLUSTER_NAME,
    [string]$AksResourceGroup = $env:AKS_RESOURCE_GROUP,
    [string]$AcrName = $env:ACR_NAME,
    [string]$AcrServer = $env:ACR_LOGIN_SERVER
)

Write-Host "════════════════════════════════════════════" -ForegroundColor Yellow
Write-Host "Fixing AKS Deployment Issues" -ForegroundColor Yellow
Write-Host "════════════════════════════════════════════" -ForegroundColor Yellow

# Validate parameters
if (-not $AcrName -or -not $AcrServer) {
    Write-Host "❌ Missing required environment variables" -ForegroundColor Red
    Write-Host "   Set: AZURE_SUBSCRIPTION_ID, AKS_CLUSTER_NAME, ACR_NAME, ACR_LOGIN_SERVER" -ForegroundColor Red
    exit 1
}

try {
    # Step 1: Retrieve ACR credentials
    Write-Host ""
    Write-Host "1. Retrieving ACR credentials..." -ForegroundColor Green
    $AcrPassword = az acr credential show --name $AcrName --query "passwords[0].value" -o tsv 2>$null
    
    if (-not $AcrPassword) {
        Write-Host "❌ Failed to retrieve ACR password" -ForegroundColor Red
        exit 1
    }
    Write-Host "✓ ACR credentials retrieved" -ForegroundColor Green

    # Step 2: Configure kubectl
    Write-Host ""
    Write-Host "2. Configuring kubectl for AKS..." -ForegroundColor Green
    az aks get-credentials --resource-group $AksResourceGroup --name $AksClusterName --overwrite-existing
    Write-Host "✓ kubectl configured" -ForegroundColor Green

    # Step 3: Create namespaces
    Write-Host ""
    Write-Host "3. Creating Kubernetes namespaces..." -ForegroundColor Green
    foreach ($namespace in @("backend", "frontend", "monitoring")) {
        kubectl create namespace $namespace --dry-run=client -o yaml | kubectl apply -f -
    }
    Write-Host "✓ Namespaces created/verified" -ForegroundColor Green

    # Step 4: Create ImagePull secrets
    Write-Host ""
    Write-Host "4. Creating ACR ImagePull secrets in namespaces..." -ForegroundColor Green
    
    $AcrUsername = $AcrName
    foreach ($namespace in @("backend", "frontend", "monitoring")) {
        Write-Host "   Creating acr-credentials secret in $namespace..." -ForegroundColor Yellow
        
        # Delete existing secret
        kubectl delete secret acr-credentials -n $namespace --ignore-not-found=true 2>$null
        
        # Create new secret
        kubectl create secret docker-registry acr-credentials `
            --docker-server=$AcrServer `
            --docker-username=$AcrUsername `
            --docker-password=$AcrPassword `
            --docker-email=jenkins@ecom.local `
            -n $namespace
        
        Write-Host "   ✓ acr-credentials created in $namespace" -ForegroundColor Green
    }

    # Step 5: Show ACR configuration
    Write-Host ""
    Write-Host "5. ACR Configuration:" -ForegroundColor Green
    Write-Host "   Server: $AcrServer"
    Write-Host "   Username: $AcrUsername"
    Write-Host "   ✓ Credentials configured" -ForegroundColor Green

    # Step 6: Redeploy services
    Write-Host ""
    Write-Host "6. Redeploying services with new credentials..." -ForegroundColor Green
    
    Push-Location "Devops/helm"
    
    foreach ($service in @("product-service", "order-service", "inventory-service", "notification-service", "api-gateway")) {
        Write-Host "   Redeploying $service..." -ForegroundColor Yellow
        helm upgrade --install $service $service/ -n backend
    }
    
    Write-Host "   Redeploying frontend..." -ForegroundColor Yellow
    helm upgrade --install frontend frontend/ -n frontend
    
    Pop-Location
    Write-Host "✓ Services redeployed" -ForegroundColor Green

    # Step 7: Wait and check status
    Write-Host ""
    Write-Host "7. Waiting for services to start..." -ForegroundColor Green
    Start-Sleep -Seconds 10

    # Step 8: Display status
    Write-Host ""
    Write-Host "8. Deployment Status:" -ForegroundColor Green
    Write-Host ""
    Write-Host "Backend Services:" -ForegroundColor Yellow
    kubectl get deployments -n backend
    Write-Host ""
    kubectl get pods -n backend
    
    Write-Host ""
    Write-Host "Frontend:" -ForegroundColor Yellow
    kubectl get deployments -n frontend
    Write-Host ""
    kubectl get pods -n frontend

    Write-Host ""
    Write-Host "════════════════════════════════════════════" -ForegroundColor Green
    Write-Host "✅ Deployment fix completed!" -ForegroundColor Green
    Write-Host "════════════════════════════════════════════" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "1. Monitor pod status: kubectl get pods -n backend -w"
    Write-Host "2. Check pod logs: kubectl logs -f <pod-name> -n backend"
    Write-Host "3. Verify ACR connectivity: az acr repository list --name $AcrName"
    Write-Host ""

}
catch {
    Write-Host ""
    Write-Host "❌ Error: $_" -ForegroundColor Red
    exit 1
}
