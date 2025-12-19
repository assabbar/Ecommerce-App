#!/usr/bin/env pwsh
# Validate all Helm charts before deployment

$ErrorActionPreference = "Stop"

Write-Host "🔍 Validating Helm Charts..." -ForegroundColor Cyan
Write-Host ""

$HELM_DIR = "Devops/helm"
$SERVICES = @("product-service", "order-service", "inventory-service", "notification-service", "api-gateway", "frontend")

$errors = 0

foreach ($service in $SERVICES) {
    Write-Host "Validating $service..." -ForegroundColor Yellow
    
    if (!(Test-Path "$HELM_DIR/$service")) {
        Write-Host "  ❌ Directory not found" -ForegroundColor Red
        $errors++
        continue
    }
    
    # Lint the chart
    try {
        helm lint "$HELM_DIR/$service" 2>&1 | Out-Null
        Write-Host "  ✓ Lint passed" -ForegroundColor Green
    } catch {
        Write-Host "  ❌ Lint failed" -ForegroundColor Red
        helm lint "$HELM_DIR/$service"
        $errors++
    }
    
    # Template the chart (dry-run)
    try {
        helm template $service "$HELM_DIR/$service" 2>&1 | Out-Null
        Write-Host "  ✓ Template generation passed" -ForegroundColor Green
    } catch {
        Write-Host "  ❌ Template generation failed" -ForegroundColor Red
        helm template $service "$HELM_DIR/$service"
        $errors++
    }
    
    Write-Host ""
}

if ($errors -eq 0) {
    Write-Host "✅ All Helm charts are valid!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "❌ Found $errors error(s)" -ForegroundColor Red
    exit 1
}
