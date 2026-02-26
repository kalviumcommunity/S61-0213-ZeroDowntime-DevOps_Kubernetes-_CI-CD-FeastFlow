# Kubernetes Scaling Guide for FeastFlow

## Overview

This guide demonstrates both **manual** and **automatic** scaling capabilities in Kubernetes. Scaling is critical for:

- **Handling variable load**: Peak dinner hours vs. quiet afternoons
- **Cost optimization**: Scale down during low-traffic periods
- **High availability**: Maintain service during pod failures
- **Performance**: Distribute load across multiple instances

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Manual Scaling](#manual-scaling)
3. [Horizontal Pod Autoscaler (HPA)](#horizontal-pod-autoscaler-hpa)
4. [Load Testing & Verification](#load-testing--verification)
5. [Scaling Best Practices](#scaling-best-practices)
6. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### Required Components

1. **Kubernetes Cluster**: KIND, Minikube, or cloud cluster
2. **Metrics Server**: Required for HPA (CPU/memory metrics)
3. **Resource Limits**: Deployments must have CPU/memory requests and limits

### Verify Prerequisites

```bash
# Check cluster status
kubectl cluster-info

# Check if metrics-server is running
kubectl get deployment metrics-server -n kube-system

# Verify FeastFlow is deployed
kubectl get deployments -n feastflow
```

### Install Metrics Server (if needed)

```bash
# Install metrics-server
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# For KIND clusters, patch to disable TLS verification
kubectl patch deployment metrics-server -n kube-system \
  --type='json' \
  -p='[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"}]'

# Wait for metrics-server to be ready
kubectl wait --for=condition=available --timeout=60s deployment/metrics-server -n kube-system

# Verify metrics are available
kubectl top nodes
kubectl top pods -n feastflow
```

---

## Manual Scaling

Manual scaling gives you direct control over the number of replicas. Use this for:

- **Predictable traffic patterns**: Scale up before lunch rush
- **Maintenance windows**: Scale down for updates
- **Cost control**: Reduce replicas during off-hours

### Quick Start: Automated Demo

**Windows (PowerShell):**

```powershell
cd devops/kubernetes
./scaling-demo.ps1
```

**Linux/Mac (Bash):**

```bash
cd devops/kubernetes
chmod +x scaling-demo.sh
./scaling-demo.sh
```

### Manual Commands

#### Method 1: kubectl scale (Recommended)

```bash
# Scale backend to 5 replicas
kubectl scale deployment feastflow-backend --replicas=5 -n feastflow

# Scale frontend to 6 replicas
kubectl scale deployment feastflow-frontend --replicas=6 -n feastflow

# Verify scaling
kubectl get deployment feastflow-backend -n feastflow
kubectl get pods -n feastflow -l component=backend
```

#### Method 2: kubectl patch

```bash
# Scale using patch command
kubectl patch deployment feastflow-backend -n feastflow \
  -p '{"spec":{"replicas":5}}'
```

#### Method 3: kubectl edit (Interactive)

```bash
# Opens editor to modify deployment
kubectl edit deployment feastflow-backend -n feastflow

# Change spec.replicas to desired value, save and exit
```

#### Method 4: Update YAML and Apply

```bash
# Edit 06-backend-deployment.yaml
# Change spec.replicas: 5

# Apply changes
kubectl apply -f 06-backend-deployment.yaml
```

### Monitoring Manual Scaling

```bash
# Watch deployment status
kubectl get deployment feastflow-backend -n feastflow --watch

# Watch pods as they scale
kubectl get pods -n feastflow -l component=backend --watch

# Check rollout status
kubectl rollout status deployment/feastflow-backend -n feastflow

# View service endpoints
kubectl get endpoints feastflow-backend -n feastflow
```

### Scaling Impact

**Zero Downtime**: Kubernetes scales gradually:

1. Creates new pods before terminating old ones (rolling update)
2. New pods register with service when ready
3. Traffic is distributed across all healthy pods
4. Old pods gracefully shut down

**Load Balancing**: Service automatically includes all replica pods as endpoints

---

## Horizontal Pod Autoscaler (HPA)

HPA automatically adjusts replicas based on observed metrics (CPU, memory, custom metrics).

### Architecture

```
┌─────────────────────────────────────────────────┐
│  Horizontal Pod Autoscaler (HPA)                │
│  - Monitors: CPU/Memory metrics                 │
│  - Target: 70% CPU utilization                  │
│  - Range: 2-10 replicas                         │
└──────────────┬──────────────────────────────────┘
               │ adjusts replicas
               ▼
┌─────────────────────────────────────────────────┐
│  Deployment: feastflow-backend                  │
│  - Current: 2 replicas                          │
│  - Resource requests: 200m CPU, 256Mi memory    │
└──────────────┬──────────────────────────────────┘
               │ creates/deletes
               ▼
┌─────────────────────────────────────────────────┐
│  Pods: backend-xxxxx-yyyyy                      │
│  - Metrics collected by metrics-server          │
│  - Average CPU: 30% → No scaling needed         │
│  - Average CPU: 80% → Scale up triggered        │
└─────────────────────────────────────────────────┘
```

### Apply HPA Configuration

```bash
# Apply HPA for both backend and frontend
kubectl apply -f devops/kubernetes/12-backend-hpa.yaml

# Verify HPA is created
kubectl get hpa -n feastflow

# View detailed HPA status
kubectl describe hpa feastflow-backend-hpa -n feastflow
```

### HPA Configuration Details

**Backend HPA** ([12-backend-hpa.yaml](12-backend-hpa.yaml)):

- **Min replicas**: 2 (high availability)
- **Max replicas**: 10 (prevent resource exhaustion)
- **CPU target**: 70% average utilization
- **Memory target**: 80% average utilization
- **Scale-up**: Fast (0s stabilization, can double pods)
- **Scale-down**: Conservative (5-min stabilization, max 50% reduction)

**Frontend HPA**:

- **Min replicas**: 2
- **Max replicas**: 8
- **CPU target**: 60% (more aggressive for user-facing traffic)

### Scaling Behavior Policies

```yaml
behavior:
  scaleUp:
    stabilizationWindowSeconds: 0 # Scale up immediately
    policies:
      - type: Percent
        value: 100 # Can double pods
        periodSeconds: 30
      - type: Pods
        value: 4 # Or add max 4 pods
        periodSeconds: 30
    selectPolicy: Max # Use most aggressive

  scaleDown:
    stabilizationWindowSeconds: 300 # Wait 5 min
    policies:
      - type: Percent
        value: 50 # Scale down max 50%
        periodSeconds: 60
      - type: Pods
        value: 2 # Or remove max 2 pods
        periodSeconds: 60
    selectPolicy: Min # Use most conservative
```

### Monitoring HPA

```bash
# Watch HPA status
kubectl get hpa -n feastflow --watch

# View HPA metrics in real-time
kubectl get hpa feastflow-backend-hpa -n feastflow \
  -o custom-columns=NAME:.metadata.name,REFERENCE:.spec.scaleTargetRef.name,TARGETS:.status.currentMetrics[*].resource.current.averageUtilization,MINPODS:.spec.minReplicas,MAXPODS:.spec.maxReplicas,REPLICAS:.status.currentReplicas

# View scaling events
kubectl describe hpa feastflow-backend-hpa -n feastflow

# Check pod metrics
kubectl top pods -n feastflow -l component=backend
```

---

## Load Testing & Verification

### Automated Load Test

**Windows (PowerShell):**

```powershell
cd devops/kubernetes

# Run load test with default settings (3 minutes, 10 concurrent)
./hpa-load-test.ps1

# Custom duration and concurrency
./hpa-load-test.ps1 -Duration 300 -Concurrent 20 -Target "backend"
```

**Linux/Mac (Bash):**

```bash
cd devops/kubernetes
chmod +x hpa-load-test.sh

# Run load test with default settings
./hpa-load-test.sh

# Custom parameters
./hpa-load-test.sh --duration 300 --concurrent 20 --target backend
```

### What the Load Test Does

1. **Verifies Prerequisites**: Checks metrics-server is running
2. **Shows Initial State**: Displays current replicas and metrics
3. **Generates CPU Load**: Sends continuous requests to backend
4. **Monitors Scaling**: Shows real-time HPA decisions and pod metrics
5. **Shows Final State**: Reports final replica count and scale-down behavior

### Manual Load Testing

#### Option 1: kubectl run (Simple)

```bash
# Create a load generator pod
kubectl run load-generator -n feastflow --image=busybox -it --rm -- /bin/sh

# Inside the pod, generate continuous requests
while true; do wget -q -O- http://feastflow-backend:5000/api/health; done
```

#### Option 2: Multi-pod Load (Realistic)

```bash
# Create 5 load generator pods
for i in {1..5}; do
  kubectl run load-generator-$i -n feastflow --image=busybox -- /bin/sh -c \
    "while true; do wget -q -O- http://feastflow-backend:5000/api/health; done"
done

# Watch HPA respond to load
kubectl get hpa feastflow-backend-hpa -n feastflow --watch

# Clean up load generators
kubectl delete pod -n feastflow -l run=load-generator
```

#### Option 3: curl from outside cluster

```bash
# Get service endpoint
kubectl port-forward -n feastflow svc/feastflow-backend 5000:5000 &

# Generate load
for i in {1..1000}; do
  curl -s http://localhost:5000/api/health &
done

# Kill port-forward when done
kill %1
```

### Expected Behavior Timeline

| Time | CPU Usage | Replicas | HPA Action                              |
| ---- | --------- | -------- | --------------------------------------- |
| 0s   | 30%       | 2        | No action (below threshold)             |
| 30s  | 85%       | 2        | Scale-up decision made                  |
| 45s  | 90%       | 4        | New pods starting (doubled)             |
| 60s  | 75%       | 4        | Still above threshold                   |
| 90s  | 72%       | 6        | Continue scaling up                     |
| 120s | 68%       | 6        | Below threshold, stabilizing            |
| 180s | 25%       | 6        | Load stops, but in stabilization window |
| 480s | 20%       | 4        | Scale-down after 5-min window           |
| 780s | 15%       | 2        | Return to minimum replicas              |

---

## Scaling Best Practices

### 1. Resource Requests and Limits

**Always define resource requests and limits** for HPA to work:

```yaml
resources:
  requests:
    cpu: "200m" # 0.2 CPU cores
    memory: "256Mi" # 256 MiB
  limits:
    cpu: "500m" # 0.5 CPU cores max
    memory: "512Mi" # 512 MiB max
```

### 2. Choose Appropriate Targets

- **CPU**: Good for compute-intensive workloads
- **Memory**: Good for caching services, data processing
- **Custom metrics**: Use for application-specific signals (queue length, request latency)

### 3. Set Realistic Min/Max

- **Min replicas**: At least 2 for high availability
- **Max replicas**: Consider:
  - Node capacity
  - Database connection limits
  - Cost constraints
  - Network bandwidth

### 4. Tune Scaling Behavior

**Scale-up**: Fast response to prevent user impact

```yaml
scaleUp:
  stabilizationWindowSeconds: 0 # Immediate
```

**Scale-down**: Conservative to prevent flapping

```yaml
scaleDown:
  stabilizationWindowSeconds: 300 # 5 minutes
```

### 5. Monitor and Adjust

```bash
# Review HPA history
kubectl describe hpa -n feastflow

# Check for scaling events
kubectl get events -n feastflow --field-selector involvedObject.name=feastflow-backend-hpa

# Analyze resource usage patterns
kubectl top pods -n feastflow -l component=backend --sort-by=cpu
```

### 6. Combine with Cluster Autoscaler

For production, combine HPA with **Cluster Autoscaler**:

- HPA scales pods
- Cluster Autoscaler scales nodes when pods can't be scheduled

---

## Troubleshooting

### HPA Shows "unknown" for Metrics

**Symptoms**:

```
NAME                     REFERENCE                       TARGETS         MINPODS   MAXPODS   REPLICAS
feastflow-backend-hpa    Deployment/feastflow-backend    <unknown>/70%   2         10        2
```

**Solutions**:

1. **Check metrics-server is running**:

```bash
kubectl get deployment metrics-server -n kube-system
kubectl logs -n kube-system deployment/metrics-server
```

2. **Verify resource requests are defined** in deployment:

```bash
kubectl get deployment feastflow-backend -n feastflow -o yaml | grep -A 5 resources:
```

3. **Wait for metrics to populate** (can take 1-2 minutes):

```bash
kubectl top pods -n feastflow
```

4. **For KIND clusters, patch metrics-server**:

```bash
kubectl patch deployment metrics-server -n kube-system --type='json' \
  -p='[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"}]'
```

### HPA Not Scaling Despite High CPU

**Check**:

1. **Verify current metrics**:

```bash
kubectl get hpa feastflow-backend-hpa -n feastflow -o yaml
kubectl top pods -n feastflow -l component=backend
```

2. **Check if at max replicas**:

```bash
kubectl get hpa -n feastflow
# If REPLICAS = MAXPODS, increase maxReplicas
```

3. **Review scaling policies**:

```bash
kubectl describe hpa feastflow-backend-hpa -n feastflow
# Check "Conditions" and "Events" sections
```

4. **Check for resource constraints**:

```bash
# See if pods are pending due to insufficient resources
kubectl get pods -n feastflow -o wide
kubectl describe nodes | grep -A 5 "Allocated resources"
```

### Pods Not Starting During Scale-Up

1. **Check pod status**:

```bash
kubectl get pods -n feastflow -l component=backend
kubectl describe pod <pending-pod-name> -n feastflow
```

2. **Common issues**:
   - **Insufficient cluster resources**: Need more nodes
   - **Image pull errors**: Check image availability
   - **Liveness probe failures**: Check health endpoint
   - **Resource quota exceeded**: Check namespace quotas

### Scale-Down Too Aggressive or Too Slow

**Adjust scale-down policies** in [12-backend-hpa.yaml](12-backend-hpa.yaml):

```yaml
scaleDown:
  stabilizationWindowSeconds: 180 # Decrease for faster scale-down
  policies:
    - type: Pods
      value: 1 # Scale down 1 pod at a time (conservative)
```

---

## Real-World Scenarios

### Scenario 1: Lunch Rush (11:30 AM - 1:00 PM)

**Approach**: Pre-scale before peak

```bash
# At 11:15 AM, manually scale up
kubectl scale deployment feastflow-backend --replicas=6 -n feastflow

# Let HPA take over during peak
# At 1:30 PM, HPA will gradually scale down as traffic decreases
```

### Scenario 2: Flash Sale Event

**Approach**: Increase HPA max replicas temporarily

```bash
# Before event, increase max replicas
kubectl patch hpa feastflow-backend-hpa -n feastflow \
  -p '{"spec":{"maxReplicas":20}}'

# After event, restore original limits
kubectl patch hpa feastflow-backend-hpa -n feastflow \
  -p '{"spec":{"maxReplicas":10}}'
```

### Scenario 3: Gradual Traffic Growth

**Approach**: Let HPA handle automatically

```bash
# Monitor HPA decisions
kubectl get hpa -n feastflow --watch

# Review metrics trends
kubectl top pods -n feastflow -l component=backend --sort-by=cpu
```

### Scenario 4: Cost Optimization (Overnight)

**Approach**: Reduce min replicas during off-hours

```bash
# At 11:00 PM, scale down minimum
kubectl patch hpa feastflow-backend-hpa -n feastflow \
  -p '{"spec":{"minReplicas":1}}'

# At 7:00 AM, restore minimum
kubectl patch hpa feastflow-backend-hpa -n feastflow \
  -p '{"spec":{"minReplicas":2}}'
```

---

## Advanced Topics

### Custom Metrics

HPA can scale based on custom metrics from Prometheus or other sources:

```yaml
metrics:
  - type: Pods
    pods:
      metric:
        name: http_requests_per_second
      target:
        type: AverageValue
        averageValue: "1000"
```

### Vertical Pod Autoscaler (VPA)

VPA adjusts CPU/memory requests automatically (different from HPA):

```bash
# Install VPA (separate component)
git clone https://github.com/kubernetes/autoscaler.git
cd autoscaler/vertical-pod-autoscaler
./hack/vpa-up.sh
```

### Cluster Autoscaler

Scales the cluster nodes themselves based on pod resource needs.

---

## Summary

### Manual Scaling

✅ **Use for**: Predictable patterns, maintenance, cost control  
✅ **Commands**: `kubectl scale`, `kubectl patch`, `kubectl edit`  
✅ **Demo**: `./scaling-demo.ps1` or `./scaling-demo.sh`

### Horizontal Pod Autoscaler

✅ **Use for**: Automatic response to load, hands-off operation  
✅ **Configuration**: [12-backend-hpa.yaml](12-backend-hpa.yaml)  
✅ **Prerequisites**: Metrics-server, resource requests/limits  
✅ **Load Test**: `./hpa-load-test.ps1` or `./hpa-load-test.sh`

### Key Takeaways

1. **HPA makes scaling decisions** based on observed metrics
2. **Resource requests are required** for HPA to calculate utilization
3. **Scale-up is fast**, scale-down is conservative (prevent flapping)
4. **Min/max replicas** provide boundaries for automatic scaling
5. **Manual scaling overrides HPA** until metrics-based adjustments kick in

---

## Additional Resources

- [Kubernetes HPA Documentation](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/)
- [Metrics Server](https://github.com/kubernetes-sigs/metrics-server)
- [Autoscaling Best Practices](https://kubernetes.io/docs/concepts/workloads/autoscaling/)
- [FeastFlow Project README](../../readme.md)

---

## Next Steps

1. ✅ Run manual scaling demo: `./scaling-demo.ps1`
2. ✅ Apply HPA: `kubectl apply -f 12-backend-hpa.yaml`
3. ✅ Run load test: `./hpa-load-test.ps1`
4. ✅ Monitor behavior: `kubectl get hpa -n feastflow --watch`
5. ✅ Review events: `kubectl describe hpa -n feastflow`

**Happy Scaling! 🚀**
