#!/usr/bin/env bash
# Rollback deployment to previous version

set -euo pipefail

SERVICE=$1
NAMESPACE=${2:-backend}

if [ -z "$SERVICE" ]; then
    echo "Usage: $0 <service-name> [namespace]"
    echo "Example: $0 product-service backend"
    exit 1
fi

echo "🔄 Rolling back $SERVICE in namespace $NAMESPACE..."

helm rollback "$SERVICE" 0 --namespace "$NAMESPACE" --wait

echo "✅ Rollback completed successfully!"

echo ""
echo "📊 Deployment status:"
kubectl get pods -n "$NAMESPACE" -l "app.kubernetes.io/name=$SERVICE"
