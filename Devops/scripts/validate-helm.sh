#!/usr/bin/env bash
# Validate all Helm charts before deployment

set -euo pipefail

echo "🔍 Validating Helm Charts..."
echo ""

HELM_DIR="Devops/helm"
SERVICES=("product-service" "order-service" "inventory-service" "notification-service" "api-gateway" "frontend")

errors=0

for service in "${SERVICES[@]}"; do
    echo "Validating $service..."
    
    if [ ! -d "$HELM_DIR/$service" ]; then
        echo "  ❌ Directory not found"
        errors=$((errors + 1))
        continue
    fi
    
    # Lint the chart
    if helm lint "$HELM_DIR/$service" > /dev/null 2>&1; then
        echo "  ✓ Lint passed"
    else
        echo "  ❌ Lint failed"
        helm lint "$HELM_DIR/$service"
        errors=$((errors + 1))
    fi
    
    # Template the chart (dry-run)
    if helm template "$service" "$HELM_DIR/$service" > /dev/null 2>&1; then
        echo "  ✓ Template generation passed"
    else
        echo "  ❌ Template generation failed"
        helm template "$service" "$HELM_DIR/$service"
        errors=$((errors + 1))
    fi
    
    echo ""
done

if [ $errors -eq 0 ]; then
    echo "✅ All Helm charts are valid!"
    exit 0
else
    echo "❌ Found $errors error(s)"
    exit 1
fi
