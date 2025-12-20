param(
    [string]$Action = "deploy"
)

$ErrorActionPreference = "Continue"

Write-Host "========================================" -ForegroundColor Yellow
Write-Host "E-Commerce Deployment Script" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow

$env_file = "Devops\.env"
if (-not (Test-Path $env_file)) {
    Write-Host "ERROR: .env file not found" -ForegroundColor Red
    exit 1
}

# Load env vars
Get-Content $env_file | Where-Object { $_ -match '=' -and $_ -notmatch '^#' } | ForEach-Object {
    $parts = $_ -split '=', 2
    $key = $parts[0].Trim().Trim('"')
    $value = $parts[1].Trim().Trim('"')
    if (-not [string]::IsNullOrEmpty($key) -and -not [string]::IsNullOrEmpty($value)) {
        Set-Item -Path "env:$key" -Value $value -Force
    }
}

Write-Host "Environment loaded" -ForegroundColor Green

if ([string]::IsNullOrEmpty($env:AKS_CLUSTER_NAME)) {
    Write-Host "ERROR: Missing AKS_CLUSTER_NAME" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Configuring kubectl..." -ForegroundColor Cyan
az aks get-credentials --resource-group $env:AKS_RESOURCE_GROUP --name $env:AKS_CLUSTER_NAME --overwrite-existing 2>&1 | Out-Null

if ($Action -eq "fix" -or $Action -eq "deploy") {
    Write-Host ""
    Write-Host "Creating namespaces..." -ForegroundColor Cyan
    foreach ($ns in @("backend", "frontend", "monitoring")) {
        kubectl create namespace $ns --dry-run=client -o yaml 2>$null | kubectl apply -f - | Out-Null
    }
    Write-Host "Namespaces ready" -ForegroundColor Green
    
    Write-Host ""
    Write-Host "Setting up ACR credentials..." -ForegroundColor Cyan
    
    if ([string]::IsNullOrEmpty($env:ACR_NAME)) {
        Write-Host "ERROR: Missing ACR_NAME" -ForegroundColor Red
        exit 1
    }
    
    $acrPassword = az acr credential show --name $env:ACR_NAME --query "passwords[0].value" -o tsv 2>$null
    
    if ([string]::IsNullOrEmpty($acrPassword)) {
        Write-Host "ERROR: Could not get ACR password" -ForegroundColor Red
        exit 1
    }
    
    foreach ($ns in @("backend", "frontend", "monitoring")) {
        kubectl delete secret acr-credentials -n $ns --ignore-not-found=true 2>$null | Out-Null
        
        kubectl create secret docker-registry acr-credentials `
            --docker-server=$env:ACR_LOGIN_SERVER `
            --docker-username=$env:ACR_NAME `
            --docker-password=$acrPassword `
            --docker-email="devops@ecom.local" `
            -n $ns 2>$null
        
        Write-Host "  ACR credentials configured in $ns" -ForegroundColor Green
    }
    
    Write-Host ""
    Write-Host "Cleaning up old pods..." -ForegroundColor Cyan
    kubectl delete pods --all -n backend --ignore-not-found=true 2>$null | Out-Null
    kubectl delete pods --all -n frontend --ignore-not-found=true 2>$null | Out-Null
    Write-Host "Old pods deleted" -ForegroundColor Green
    
    if ($Action -eq "deploy") {
        Write-Host ""
        Write-Host "Deploying services with Helm..." -ForegroundColor Cyan
        
        $services = @("product-service", "order-service", "inventory-service", "notification-service", "api-gateway")
        
        if (Get-Command helm -ErrorAction SilentlyContinue) {
            foreach ($service in $services) {
                $chartPath = "Devops\helm\$service"
                Write-Host "  Deploying $service..." -ForegroundColor Cyan
                helm upgrade --install $service $chartPath -n backend --values "$chartPath\values.yaml" 2>&1 | Out-Null
            }
            Write-Host "  Deploying frontend..." -ForegroundColor Cyan
            helm upgrade --install frontend Devops\helm\frontend -n frontend --values "Devops\helm\frontend\values.yaml" 2>&1 | Out-Null
            Write-Host "Services deployed" -ForegroundColor Green
        } else {
            Write-Host "WARNING: Helm not found - skipping helm deployment (Jenkins will handle it)" -ForegroundColor Yellow
        }
    }
}

Write-Host ""
Write-Host "Deployment Status:" -ForegroundColor Yellow
Write-Host ""

Write-Host "Backend Services:" -ForegroundColor Cyan
kubectl get deployments -n backend 2>$null
Write-Host ""
kubectl get pods -n backend 2>$null

Write-Host ""
Write-Host "Frontend:" -ForegroundColor Cyan
kubectl get deployments -n frontend 2>$null
Write-Host ""
kubectl get pods -n frontend 2>$null

Write-Host ""
Write-Host "========================================" -ForegroundColor Yellow
Write-Host "Done" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Yellow
