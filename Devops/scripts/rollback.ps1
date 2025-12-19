#!/usr/bin/env pwsh
# Rollback deployment to previous version

param(
    [Parameter(Mandatory=$true)]
    [string]$Service,
    
    [Parameter(Mandatory=$false)]
    [string]$Namespace = "backend"
)

Write-Host "🔄 Rolling back $Service in namespace $Namespace..." -ForegroundColor Cyan

helm rollback $Service 0 --namespace $Namespace --wait

Write-Host "✅ Rollback completed successfully!" -ForegroundColor Green

Write-Host ""
Write-Host "📊 Deployment status:" -ForegroundColor Yellow
kubectl get pods -n $Namespace -l "app.kubernetes.io/name=$Service"
