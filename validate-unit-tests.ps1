# Unit Tests Validation Script for Windows

Write-Host "==========================================" -ForegroundColor Green
Write-Host "✅ Unit Tests Validation Script (Windows)" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green
Write-Host ""

$ErrorCount = 0

# Go to backend directory
Set-Location backend

# Test 1: Product Service
Write-Host "[1/4] Testing Product Service..." -ForegroundColor Yellow
mvn clean test -pl product-service -Dtest=ProductServiceTest -q
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Product Service Tests PASSED" -ForegroundColor Green
} else {
    Write-Host "❌ Product Service Tests FAILED" -ForegroundColor Red
    $ErrorCount++
}

# Test 2: Notification Service
Write-Host ""
Write-Host "[2/4] Testing Notification Service..." -ForegroundColor Yellow
mvn clean test -pl notification-service -Dtest=NotificationServiceTest -q
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Notification Service Tests PASSED" -ForegroundColor Green
} else {
    Write-Host "❌ Notification Service Tests FAILED" -ForegroundColor Red
    $ErrorCount++
}

# Test 3: Inventory Service
Write-Host ""
Write-Host "[3/4] Testing Inventory Service..." -ForegroundColor Yellow
mvn clean test -pl inventory-service -Dtest=InventoryServiceApplicationTests -q
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Inventory Service Tests PASSED" -ForegroundColor Green
} else {
    Write-Host "❌ Inventory Service Tests FAILED" -ForegroundColor Red
    $ErrorCount++
}

# Test 4: API Gateway
Write-Host ""
Write-Host "[4/4] Testing API Gateway..." -ForegroundColor Yellow
mvn clean test -pl api-gateway -Dtest=ApiGatewayApplicationTest -q
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ API Gateway Tests PASSED" -ForegroundColor Green
} else {
    Write-Host "❌ API Gateway Tests FAILED" -ForegroundColor Red
    $ErrorCount++
}

Write-Host ""
if ($ErrorCount -eq 0) {
    Write-Host "==========================================" -ForegroundColor Green
    Write-Host "✅ ALL UNIT TESTS PASSED SUCCESSFULLY!" -ForegroundColor Green
    Write-Host "==========================================" -ForegroundColor Green
    exit 0
} else {
    Write-Host "==========================================" -ForegroundColor Red
    Write-Host "❌ SOME TESTS FAILED" -ForegroundColor Red
    Write-Host "==========================================" -ForegroundColor Red
    exit 1
}
