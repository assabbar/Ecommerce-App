# E-Commerce Monitoring Stack

## Overview

The monitoring stack provides comprehensive observability for the E-Commerce application running on Kubernetes.

### Components

1. **Prometheus** - Metrics collection and storage
2. **Grafana** - Visualization and dashboards
3. **Loki** - Log aggregation
4. **Promtail** - Log shipper
5. **Alert Manager** - Alert routing and notification

## Architecture

```
Applications
  ↓
Prometheus (scrapes metrics) + Loki (receives logs from Promtail)
  ↓
Grafana (visualizes Prometheus + Loki)
  ↓
User Dashboard
```

## Deployment

### Prerequisites

- AKS cluster running
- Helm 3+ installed
- kubectl configured

### Deploy Monitoring Stack

```bash
cd Devops/helm/monitoring
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# Deploy Prometheus
helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --values prometheus-values.yaml \
  --wait

# Deploy Grafana
helm upgrade --install grafana grafana/grafana \
  --namespace monitoring \
  --values grafana-values.yaml \
  --wait

# Deploy Loki Stack
helm upgrade --install loki grafana/loki-stack \
  --namespace monitoring \
  --values loki-values.yaml \
  --wait
```

## Access

### Grafana

```bash
# Get Grafana service info
kubectl get svc -n monitoring grafana

# Port-forward (if using ClusterIP)
kubectl port-forward -n monitoring svc/grafana 3000:3000

# Access
URL: http://localhost:3000
Username: admin
Password: (check grafana-values.yaml)
```

### Prometheus

```bash
# Port-forward to Prometheus
kubectl port-forward -n monitoring svc/prometheus-operated 9090:9090

# Access
URL: http://localhost:9090
```

### Loki

```bash
# Port-forward to Loki
kubectl port-forward -n monitoring svc/loki 3100:3100

# Access
URL: http://localhost:3100
```

## Metrics Collection

### Kubernetes Metrics

Prometheus automatically scrapes:
- API Server metrics
- Kubelet metrics
- kube-scheduler metrics
- kube-controller-manager metrics
- Node metrics (via Node Exporter)

### Application Metrics

Services expose Prometheus metrics at `/actuator/prometheus`:

```bash
curl http://product-service:8080/actuator/prometheus
```

### Custom Metrics

Services can emit custom metrics using Micrometer:

```java
@Observed(name = "custom.operation")
public void performOperation() {
    // Custom metric tracked automatically
}
```

## Log Collection

### How Logs Flow

1. **Promtail** collects logs from pod stdout/stderr
2. **Labels** are added (namespace, pod, container, app)
3. **Loki** stores logs with these labels
4. **Grafana** queries Loki for log visualization

### Query Logs in Grafana

```
{namespace="backend", app="product-service"}
```

### Log Retention

Default: 7 days (configured in loki-values.yaml)

To change:
```yaml
table_manager:
  retention_period: 168h  # 7 days
```

## Alerts

### Pre-configured Alerts

Alerts are defined in `prometheus-values.yaml`:

- `PodMemoryUsageHigh` - Pod memory > 90% limit
- `PodCPUUsageHigh` - Pod CPU > 90% limit
- `NodeMemoryPressure` - Node has memory pressure
- `NodeDiskPressure` - Node has disk pressure
- `PodNotHealthy` - Pod is Pending/Unknown/Failed

### View Alerts

1. Grafana → Alerting → Alert Rules
2. Prometheus → Alerts
3. AlertManager → http://localhost:9093

### Custom Alerts

Add to `prometheusRules.groups` in `prometheus-values.yaml`:

```yaml
- alert: HighErrorRate
  expr: rate(http_requests_total{status=~"5.."}[5m]) > 0.05
  for: 5m
  labels:
    severity: critical
```

## Dashboards

### Pre-installed Dashboards

1. **Kubernetes Cluster** (GrafanaID: 7249)
   - Cluster overview
   - Node metrics
   - Pod metrics

2. **Kubernetes Nodes** (GrafanaID: 8588)
   - CPU, memory, disk usage
   - Network metrics

3. **Spring Boot** (GrafanaID: 4701)
   - Request rates
   - Error rates
   - Latency

4. **JVM Metrics** (GrafanaID: 11074)
   - Heap memory
   - GC events
   - Thread metrics

### Create Custom Dashboard

1. Grafana → Create → Dashboard
2. Add Panel → Choose Datasource (Prometheus/Loki)
3. Write Prometheus query or Loki query
4. Save

### Example Queries

**Prometheus:**
```promql
# Request rate
rate(http_server_requests_seconds_count[5m])

# Error rate
rate(http_server_requests_seconds_count{status=~"5.."}[5m])

# Latency (95th percentile)
histogram_quantile(0.95, http_server_requests_seconds_bucket)
```

**Loki:**
```logql
# All logs from product-service
{app="product-service"}

# Error logs
{app="product-service"} | "ERROR"

# Logs with metrics
{app="product-service"} | json | status != "200"
```

## Troubleshooting

### No Metrics Appearing

1. Check Prometheus targets: http://prometheus:9090/targets
2. Verify services are exposing /actuator/prometheus
3. Check ServiceMonitor labels match Prometheus scrape selectors

### No Logs Appearing

1. Check Promtail pods: `kubectl get pods -n monitoring`
2. Verify pods have stdout/stderr logs: `kubectl logs <pod> -n backend`
3. Check Loki is running: `kubectl get svc -n monitoring loki`

### High Memory Usage

1. Reduce Prometheus retention: `prometheus.prometheusSpec.retention`
2. Reduce Loki retention: `table_manager.retention_period`
3. Increase Grafana cache size

### Alerts Not Firing

1. Check AlertManager configuration
2. Verify alert rules in Prometheus
3. Check SMTP configuration if using email alerts

## Best Practices

1. **Resource Limits** - Set requests/limits in values files
2. **Storage** - Use persistent volumes for Prometheus and Loki
3. **Retention** - Balance storage vs. history needs
4. **RBAC** - Enable RBAC for security
5. **High Availability** - Deploy multiple replicas in production
6. **Backup** - Regularly backup Grafana dashboards

## Related Files

- `prometheus-values.yaml` - Prometheus configuration
- `grafana-values.yaml` - Grafana configuration
- `loki-values.yaml` - Loki configuration
- `../../scripts/deploy-aks.sh` - Deployment script
- `../Helm services/` - Service-specific Helm charts
