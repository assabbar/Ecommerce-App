@echo off
REM Script to run all tests (Backend + Frontend) on Windows

setlocal enabledelayedexpansion

for /F %%A in ('copy /Z "%~f0" nul') do set "BS=%%A"

set "GREEN=[92m"
set "YELLOW=[93m"
set "RED=[91m"
set "NC=[0m"

echo !YELLOW!===============================================!NC!
echo !YELLOW!Running All Tests (Backend + Frontend)!NC!
echo !YELLOW!===============================================!NC!
echo.

REM Test Backend
echo !YELLOW![1/2] Running Backend Tests...!NC!
echo.

cd backend

echo !YELLOW!Running Product Service Tests...!NC!
call mvn test -pl product-service -DskipITs
if %errorlevel% neq 0 (
    echo !RED!Product Service tests failed!NC!
    exit /b 1
)

echo !YELLOW!Running Order Service Tests...!NC!
call mvn test -pl order-service -DskipITs
if %errorlevel% neq 0 (
    echo !RED!Order Service tests failed!NC!
    exit /b 1
)

echo !YELLOW!Running Inventory Service Tests...!NC!
call mvn test -pl inventory-service -DskipITs
if %errorlevel% neq 0 (
    echo !RED!Inventory Service tests failed!NC!
    exit /b 1
)

echo !YELLOW!Running Notification Service Tests...!NC!
call mvn test -pl notification-service -DskipITs
if %errorlevel% neq 0 (
    echo !RED!Notification Service tests failed!NC!
    exit /b 1
)

echo !GREEN!✓ All Backend Tests Passed!!NC!
echo.

REM Test Frontend
echo !YELLOW![2/2] Running Frontend Tests...!NC!
echo.

cd ..\frontend

call npm test -- --watch=false --browsers=ChromeHeadless
if %errorlevel% neq 0 (
    echo !RED!Frontend tests failed!NC!
    exit /b 1
)

echo !GREEN!✓ Frontend Tests Passed!!NC!
echo.

REM Summary
echo !YELLOW!===============================================!NC!
echo !GREEN!✓ All Tests Completed Successfully!!NC!
echo !YELLOW!===============================================!NC!
echo.

echo !YELLOW!Test Coverage Reports:!NC!
echo Backend: cd backend ^&^& mvn jacoco:report
echo Frontend: cd frontend ^&^& npm test -- --code-coverage

endlocal
