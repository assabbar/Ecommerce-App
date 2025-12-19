#!/usr/bin/env bash
# Get deployment status and health checks

set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}================================================${NC}"
echo -e "${GREEN}  E-Commerce Deployment Status${NC}"
echo -e "${GREEN}================================================${NC}"
echo ""

# Backend services
echo -e "${YELLOW}Backend Services (namespace: backend)${NC}"
echo ""
kubectl get pods -n backend -o wide
echo ""
kubectl get services -n backend
echo ""

# Frontend
echo -e "${YELLOW}Frontend (namespace: frontend)${NC}"
echo ""
kubectl get pods -n frontend -o wide
echo ""
kubectl get services -n frontend
echo ""

# HPA status
echo -e "${YELLOW}Horizontal Pod Autoscalers${NC}"
echo ""
kubectl get hpa -n backend
kubectl get hpa -n frontend
echo ""

# Service endpoints
echo -e "${YELLOW}External Endpoints${NC}"
echo ""
echo "API Gateway:"
kubectl get svc api-gateway -n backend -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "  Pending..."
echo ""
echo "Frontend:"
kubectl get svc frontend -n frontend -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "  Pending..."
echo ""
