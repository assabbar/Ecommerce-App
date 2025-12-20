#!/usr/bin/env pwsh

<#
    Jenkins Build Trigger Script
    
    Usage: .\trigger-jenkins-build.ps1 -JenkinsUrl "http://localhost:8080" -JobName "ecom-pipeline" -Username "admin" -Token "YOUR_API_TOKEN"
#>

param(
    [string]$JenkinsUrl = "http://localhost:8080",
    [string]$JobName = "ecom-pipeline",
    [string]$Username = "admin",
    [string]$Token = ""
)

Write-Host "========================================" -ForegroundColor Yellow
Write-Host "Jenkins Build Trigger" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "Jenkins URL: $JenkinsUrl" -ForegroundColor Cyan
Write-Host "Job Name: $JobName" -ForegroundColor Cyan
Write-Host ""

if ([string]::IsNullOrEmpty($Token)) {
    Write-Host "WARNING: No API token provided. You may need to authenticate." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "To create an API token in Jenkins:" -ForegroundColor Gray
    Write-Host "1. Click your username (top-right corner)" -ForegroundColor Gray
    Write-Host "2. Click 'Configure'" -ForegroundColor Gray
    Write-Host "3. Click 'Add new Token' under API Tokens" -ForegroundColor Gray
    Write-Host "4. Copy the token and pass it with -Token parameter" -ForegroundColor Gray
    Write-Host ""
}

$triggerUrl = "$JenkinsUrl/job/$JobName/buildWithParameters"

Write-Host "Attempting to trigger build at: $triggerUrl" -ForegroundColor Cyan
Write-Host ""

try {
    # Build authentication header if token provided
    $headers = @{}
    if (-not [string]::IsNullOrEmpty($Token)) {
        $base64Auth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$Username`:$Token"))
        $headers["Authorization"] = "Basic $base64Auth"
    }
    
    # Trigger the build
    $response = Invoke-WebRequest -Uri $triggerUrl `
        -Method POST `
        -Headers $headers `
        -ErrorAction Stop
    
    Write-Host "[SUCCESS] Build triggered!" -ForegroundColor Green
    Write-Host "Status Code: $($response.StatusCode)" -ForegroundColor Green
    Write-Host ""
    Write-Host "Check Jenkins at: $JenkinsUrl" -ForegroundColor Cyan
    Write-Host ""
    
} catch {
    Write-Host "[ERROR] Failed to trigger build" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "Possible solutions:" -ForegroundColor Yellow
    Write-Host "1. Check if Jenkins is running" -ForegroundColor Gray
    Write-Host "2. Verify the job name is correct" -ForegroundColor Gray
    Write-Host "3. Check if you need authentication (provide -Token parameter)" -ForegroundColor Gray
    Write-Host "4. Ensure you have permission to trigger builds" -ForegroundColor Gray
    Write-Host ""
    exit 1
}
