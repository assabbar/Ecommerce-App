# PowerShell Script to Start Microservices on Windows

$ErrorActionPreference = "Stop"

# Colors for output
function Write-Success { Write-Host $args -ForegroundColor Green }
function Write-Error { Write-Host $args -ForegroundColor Red }
function Write-Warning { Write-Host $args -ForegroundColor Yellow }

# Get the script directory
$PROJECT_DIR = (Get-Location).Path
$BACKEND_DIR = Join-Path $PROJECT_DIR "backend"
$LOGS_DIR = Join-Path $PROJECT_DIR "logs"

Write-Warning "Starting microservices..."
Write-Host ""

# Create logs directory if it doesn't exist
if (-not (Test-Path $LOGS_DIR)) {
    New-Item -ItemType Directory -Path $LOGS_DIR | Out-Null
}

# Function to start a service
function Start-Service {
    param(
        [string]$ServiceName,
        [string]$JarPath,
        [int]$Port
    )

    if (-not (Test-Path $JarPath)) {
        Write-Error "ERROR: JAR not found: $JarPath"
        return $false
    }

    Write-Success "Starting $ServiceName on port $Port..."
    
    $LogFile = Join-Path $LOGS_DIR "$ServiceName.log"
    $PidFile = Join-Path $LOGS_DIR "$ServiceName.pid"
    
    # Start the service in a background process
    $process = Start-Process -FilePath "java" `
        -ArgumentList "-jar", $JarPath `
        -RedirectStandardOutput $LogFile `
        -PassThru `
        -NoNewWindow

    # Save the PID
    $process.Id | Out-File -FilePath $PidFile -Force
    
    Write-Host "  PID: $($process.Id)"
    Start-Sleep -Seconds 3
    
    return $true
}

# Start services
Write-Host ""
Write-Warning "Starting microservices..."

$services = @(
    @{Name = "product-service"; Jar = "product-service\target\product-service-1.0-SNAPSHOT.jar"; Port = 8080}
    @{Name = "order-service"; Jar = "order-service\target\order-service-1.0-SNAPSHOT.jar"; Port = 8081}
    @{Name = "inventory-service"; Jar = "inventory-service\target\inventory-service-1.0-SNAPSHOT.jar"; Port = 8082}
    @{Name = "api-gateway"; Jar = "api-gateway\target\api-gateway-0.0.1-SNAPSHOT.jar"; Port = 9000}
)

foreach ($service in $services) {
    $jarFullPath = Join-Path $BACKEND_DIR $service.Jar
    Start-Service -ServiceName $service.Name -JarPath $jarFullPath -Port $service.Port
}

Start-Sleep -Seconds 5

Write-Host ""
Write-Success "Services started!"
Write-Host ""

Write-Warning "Service URLs:"
Write-Host "  Product Service:    http://localhost:8080/swagger-ui.html"
Write-Host "  Order Service:      http://localhost:8081/swagger-ui.html"
Write-Host "  Inventory Service:  http://localhost:8082/swagger-ui.html"
Write-Host "  API Gateway:        http://localhost:9000/swagger-ui.html"
Write-Host "  Frontend:           http://localhost:4200"
Write-Host ""

Write-Warning "Running processes:"
Get-Process | Where-Object { $_.ProcessName -eq "java" } | ForEach-Object {
    Write-Host "  PID: $($_.Id), Name: $($_.ProcessName), Memory: $([Math]::Round($_.WorkingSet / 1MB, 2)) MB"
}

Write-Host ""
Write-Success "Setup complete! Check logs in: $LOGS_DIR"
