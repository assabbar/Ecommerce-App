#!/usr/bin/env pwsh

# Jenkins Deployment Validation Script

Write-Host "========================================" -ForegroundColor Yellow
Write-Host "Jenkins Deployment Validation" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow
Write-Host ""

$ChecksPassed = 0
$ChecksFailed = 0

# Test files
Write-Host "Checking critical files..." -ForegroundColor Cyan
$files = @(
    "Devops\jenkins\Jenkinsfile",
    "Devops\jenkins\jenkins.env.template",
    "Devops\terraform\secrets.tf",
    "docker-compose.yml"
)

foreach ($file in $files) {
    if (Test-Path $file) {
        Write-Host "[OK] $file" -ForegroundColor Green
        $ChecksPassed++
    } else {
        Write-Host "[FAIL] $file missing" -ForegroundColor Red
        $ChecksFailed++
    }
}
Write-Host ""

# Test Helm charts
Write-Host "Checking Helm charts..." -ForegroundColor Cyan
$services = @("product-service", "order-service", "inventory-service", "notification-service", "api-gateway", "frontend")
foreach ($service in $services) {
    $chartFile = "Devops\helm\$service\Chart.yaml"
    $valuesFile = "Devops\helm\$service\values.yaml"
    
    if ((Test-Path $chartFile) -and (Test-Path $valuesFile)) {
        Write-Host "[OK] $service" -ForegroundColor Green
        $ChecksPassed += 2
    } else {
        Write-Host "[FAIL] $service" -ForegroundColor Red
        $ChecksFailed += 2
    }
}
Write-Host ""

# Check terraform secrets
Write-Host "Checking Terraform secrets..." -ForegroundColor Cyan
$secretsFile = "Devops\terraform\secrets.tf"
if (Test-Path $secretsFile) {
    $content = Get-Content $secretsFile -Raw
    
    if ($content -like "*mysql-credentials*") {
        Write-Host "[OK] MySQL secret configured" -ForegroundColor Green
        $ChecksPassed++
    } else {
        Write-Host "[FAIL] MySQL secret not configured" -ForegroundColor Red
        $ChecksFailed++
    }
    
    if ($content -like "*cosmosdb-credentials*") {
        Write-Host "[OK] CosmosDB secret configured" -ForegroundColor Green
        $ChecksPassed++
    } else {
        Write-Host "[FAIL] CosmosDB secret not configured" -ForegroundColor Red
        $ChecksFailed++
    }
}
Write-Host ""

# Check Jenkins config
Write-Host "Checking Jenkins configuration..." -ForegroundColor Cyan
$jenkinsFile = "Devops\jenkins\Jenkinsfile"
if (Test-Path $jenkinsFile) {
    $content = Get-Content $jenkinsFile -Raw
    
    if ($content -like "*configFileProvider*") {
        Write-Host "[OK] ConfigFileProvider configured" -ForegroundColor Green
        $ChecksPassed++
    } else {
        Write-Host "[FAIL] ConfigFileProvider not found" -ForegroundColor Red
        $ChecksFailed++
    }
    
    if ($content -like "*helm upgrade*") {
        Write-Host "[OK] Helm deployment configured" -ForegroundColor Green
        $ChecksPassed++
    } else {
        Write-Host "[FAIL] Helm deployment not configured" -ForegroundColor Red
        $ChecksFailed++
    }
}
Write-Host ""

# Summary
Write-Host "========================================" -ForegroundColor Yellow
Write-Host "Validation Results" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow
Write-Host "Passed: $ChecksPassed" -ForegroundColor Green
Write-Host "Failed: $ChecksFailed" -ForegroundColor Red
Write-Host ""

if ($ChecksFailed -eq 0) {
    Write-Host "READY: All checks passed!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "ISSUES: Please fix the failures above" -ForegroundColor Red
    exit 1
}
