#!/usr/bin/env pwsh
# Get deployment status and health checks

Write-Host "================================================" -ForegroundColor Green
Write-Host "  E-Commerce Deployment Status" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Green
Write-Host ""

# Backend services
Write-Host "Backend Services (namespace: backend)" -ForegroundColor Yellow
Write-Host ""
kubectl get pods -n backend -o wide
Write-Host ""
kubectl get services -n backend
Write-Host ""

# Frontend
Write-Host "Frontend (namespace: frontend)" -ForegroundColor Yellow
Write-Host ""
kubectl get pods -n frontend -o wide
Write-Host ""
kubectl get services -n frontend
Write-Host ""

# HPA status
Write-Host "Horizontal Pod Autoscalers" -ForegroundColor Yellow
Write-Host ""
kubectl get hpa -n backend
kubectl get hpa -n frontend
Write-Host ""

# Service endpoints
Write-Host "External Endpoints" -ForegroundColor Yellow
Write-Host ""
Write-Host "API Gateway:"
try {
    $ip = kubectl get svc api-gateway -n backend -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>$null
    if ($ip) { Write-Host "  $ip" } else { Write-Host "  Pending..." }
} catch {
    Write-Host "  Pending..."
}
Write-Host ""
Write-Host "Frontend:"
try {
    $ip = kubectl get svc frontend -n frontend -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>$null
    if ($ip) { Write-Host "  $ip" } else { Write-Host "  Pending..." }
} catch {
    Write-Host "  Pending..."
}
Write-Host ""
