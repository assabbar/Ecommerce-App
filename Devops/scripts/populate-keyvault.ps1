# Populate Azure Key Vault with credentials from jenkins.env
# This script reads the jenkins.env file and stores each variable as a secret in Azure Key Vault

param(
    [string]$KeyVaultName = "ecommerce-kv",
    [string]$JenkinsEnvFile = "$PSScriptRoot/../jenkins/jenkins.env"
)

Write-Host "Populating Azure Key Vault with secrets" -ForegroundColor Green
Write-Host ""

if (-not (Test-Path $JenkinsEnvFile)) {
    Write-Host "Error: jenkins.env file not found at $JenkinsEnvFile" -ForegroundColor Red
    exit 1
}

Write-Host "Checking Azure Key Vault: $KeyVaultName"
$kv = az keyvault list --query "[?name=='$KeyVaultName']" -o json | ConvertFrom-Json
if (-not $kv -or $kv.Count -eq 0) {
    Write-Host "Error: Key Vault not found" -ForegroundColor Red
    exit 1
}
Write-Host "Key Vault found" -ForegroundColor Green
Write-Host ""

$secretCount = 0
$skippedCount = 0

$content = Get-Content $JenkinsEnvFile
foreach ($line in $content) {
    $line = $line.Trim()
    
    if ($line.StartsWith("#") -or $line -eq "") {
        continue
    }
    
    if ($line -match "^([^=]+)=(.*)$") {
        $key = $Matches[1]
        $value = $Matches[2]
        
        $secretName = $key.ToLower() -replace "_", "-"
        
        if ([string]::IsNullOrWhiteSpace($value)) {
            Write-Host "Skipping: $key (empty value)" -ForegroundColor Yellow
            $skippedCount++
            continue
        }
        
        Write-Host "Setting secret: $secretName" -ForegroundColor Cyan
        az keyvault secret set --vault-name $KeyVaultName --name $secretName --value $value --output none 2>&1 | Out-Null
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "   Success" -ForegroundColor Green
            $secretCount++
        } else {
            Write-Host "   Failed" -ForegroundColor Red
        }
    }
}

Write-Host ""
Write-Host "Summary:"
Write-Host "Created/Updated secrets: $secretCount" -ForegroundColor Green
Write-Host "Skipped: $skippedCount" -ForegroundColor Yellow
Write-Host ""
Write-Host "Key Vault populated successfully!" -ForegroundColor Green

