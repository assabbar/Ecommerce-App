#!/bin/bash

# Validation Checklist for Jenkins Deployment
# This script verifies all components are ready for the Jenkins pipeline

set -e

echo "========================================"
echo "📋 Jenkins Deployment Validation"
echo "========================================"
echo ""

CHECKS_PASSED=0
CHECKS_FAILED=0

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

check_file() {
    if [ -f "$1" ]; then
        echo -e "${GREEN}✓${NC} File exists: $1"
        ((CHECKS_PASSED++))
    else
        echo -e "${RED}✗${NC} File missing: $1"
        ((CHECKS_FAILED++))
    fi
}

check_git_status() {
    if [ -z "$(git status --porcelain)" ]; then
        echo -e "${GREEN}✓${NC} Git working directory clean"
        ((CHECKS_PASSED++))
    else
        echo -e "${YELLOW}!${NC} Git has uncommitted changes"
        git status --short
    fi
}

check_helm_chart() {
    if [ -d "Devops/helm/$1" ] && [ -f "Devops/helm/$1/Chart.yaml" ]; then
        echo -e "${GREEN}✓${NC} Helm chart exists: $1"
        ((CHECKS_PASSED++))
    else
        echo -e "${RED}✗${NC} Helm chart missing: $1"
        ((CHECKS_FAILED++))
    fi
}

check_values_file() {
    if [ -f "Devops/helm/$1/values.yaml" ]; then
        echo -e "${GREEN}✓${NC} Values file exists: $1"
        ((CHECKS_PASSED++))
    else
        echo -e "${RED}✗${NC} Values file missing: $1"
        ((CHECKS_FAILED++))
    fi
}

# Check critical files
echo "📁 Checking critical files..."
check_file "Devops/jenkins/Jenkinsfile"
check_file "Devops/jenkins/jenkins.env.template"
check_file "Devops/terraform/secrets.tf"
check_file "docker-compose.yml"
echo ""

# Check Helm charts and values
echo "📦 Checking Helm charts..."
for service in product-service order-service inventory-service notification-service api-gateway frontend; do
    check_helm_chart "$service"
    check_values_file "$service"
done
echo ""

# Check deployment templates have valueFrom support
echo "🔐 Checking template configurations..."
for service in product-service order-service inventory-service notification-service api-gateway frontend; do
    template="Devops/helm/$service/templates/deployment.yaml"
    if grep -q "valueFrom:" "$template"; then
        echo -e "${GREEN}✓${NC} $service template supports valueFrom"
        ((CHECKS_PASSED++))
    else
        echo -e "${YELLOW}!${NC} $service template may not support valueFrom"
    fi
done
echo ""

# Check secrets configuration
echo "🔑 Checking secrets configuration..."
if grep -q "cosmosdb-credentials" "Devops/terraform/secrets.tf"; then
    echo -e "${GREEN}✓${NC} CosmosDB secret defined in Terraform"
    ((CHECKS_PASSED++))
else
    echo -e "${RED}✗${NC} CosmosDB secret not defined"
    ((CHECKS_FAILED++))
fi

if grep -q "mysql-credentials" "Devops/terraform/secrets.tf"; then
    echo -e "${GREEN}✓${NC} MySQL secret defined in Terraform"
    ((CHECKS_PASSED++))
else
    echo -e "${RED}✗${NC} MySQL secret not defined"
    ((CHECKS_FAILED++))
fi
echo ""

# Check Git status
echo "📚 Checking Git status..."
check_git_status
echo ""

# Check Jenkins configuration reference
echo "⚙️ Checking Jenkins configuration..."
if grep -q "configFileProvider" "Devops/jenkins/Jenkinsfile"; then
    echo -e "${GREEN}✓${NC} Jenkins uses configFileProvider for jenkins.env"
    ((CHECKS_PASSED++))
else
    echo -e "${RED}✗${NC} Jenkins not configured for external config files"
    ((CHECKS_FAILED++))
fi
echo ""

# Summary
echo "========================================"
echo "📊 Validation Summary"
echo "========================================"
echo -e "Passed: ${GREEN}$CHECKS_PASSED${NC}"
echo -e "Failed: ${RED}$CHECKS_FAILED${NC}"
echo ""

if [ $CHECKS_FAILED -eq 0 ]; then
    echo -e "${GREEN}✅ All checks passed! Ready for Jenkins deployment.${NC}"
    exit 0
else
    echo -e "${RED}❌ Some checks failed. Please fix the issues above.${NC}"
    exit 1
fi
