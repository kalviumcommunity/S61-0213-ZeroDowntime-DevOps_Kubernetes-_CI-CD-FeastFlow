# Deployment Strategy for FeastFlow on Kubernetes

## Overview

This document outlines deployment strategies, rollback procedures, and best practices for deploying FeastFlow to a Kubernetes cluster with zero downtime.

---

## 1. Deployment Strategies

### 1.1 Rolling Update (Default - Implemented)

**What it is:**
Gradually replaces old pods with new ones, ensuring service availability.

**Configuration:**
```yaml
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxSurge: 1        # Max extra pods during update (25% of replicas)
    maxUnavailable: 0  # Keep all current capacity running
```

**Process:**
1. Start new pod with updated image
2. Wait for readiness probe to pass
3. Add new pod to service load balancer
4. Terminate one old pod
5. Repeat until all pods updated

**Pros:**
- ✅ Zero downtime
- ✅ Gradual rollout (easy to spot issues)
- ✅ Built-in to Kubernetes

**Cons:**
- ❌ Both versions running simultaneously
- ❌ Requires backward-compatible changes
- ❌ Slower than recreate strategy

**Use Case:** Production deployments (implemented for FeastFlow)

---

### 1.2 Blue-Green Deployment

**What it is:**
Run two identical environments, switch traffic after validation.

**Implementation:**
```yaml
# Blue (current - v1)
selector:
  app: feastflow-backend
  version: v1

# Green (new - v2)
selector:
  app: feastflow-backend
  version: v2

# Switch traffic by updating service selector
service:
  selector:
    version: v2  # Instant switch
```

**Process:**
1. Deploy "green" environment (v2) alongside "blue" (v1)
2. Test green environment (smoke tests, validation)
3. Switch service selector from v1 → v2
4. Monitor for issues
5. Keep blue for quick rollback

**Pros:**
- ✅ Instant rollback (just switch selector)
- ✅ Full testing before cutover
- ✅ Zero downtime

**Cons:**
- ❌ Requires 2x resources during deployment
- ❌ More complex setup

**Use Case:** Critical production updates requiring instant rollback capability

---

### 1.3 Canary Deployment

**What it is:**
Route small percentage of traffic to new version, gradually increase.

**Implementation:**
```yaml
# Stable version (90% traffic)
deployment: feastflow-backend-stable
replicas: 9

# Canary version (10% traffic)
deployment: feastflow-backend-canary
replicas: 1

# Service routes to both
service:
  selector:
    app: feastflow-backend  # Matches both
```

**Process:**
1. Deploy canary with 1 pod (10% traffic if stable has 9)
2. Monitor metrics (errors, latency, etc.)
3. If healthy: scale canary up, stable down
4. If errors: delete canary deployment
5. Repeat until canary is 100%

**Pros:**
- ✅ Minimal blast radius (only 10% affected by bugs)
- ✅ Real production testing
- ✅ Gradual risk mitigation

**Cons:**
- ❌ Complex traffic management (better with Istio)
- ❌ Requires good monitoring
- ❌ Longer deployment time

**Use Case:** High-risk deployments (major refactors, breaking changes)

---

### 1.4 Recreate Strategy

**What it is:**
Stop all old pods before starting new ones.

**Configuration:**
```yaml
strategy:
  type: Recreate
```

**Pros:**
- ✅ Simple
- ✅ No version compatibility concerns
- ✅ Lower resource usage

**Cons:**
- ❌ **Downtime** during deployment

**Use Case:** Non-production environments, maintenance windows

---

## 2. Deployment Process (Step-by-Step)

### Prerequisites Check

```bash
# 1. Verify kubectl context
kubectl config current-context

# 2. Verify cluster connectivity
kubectl cluster-info

# 3. Check current deployment status
kubectl get deployments -n feastflow

# 4. Verify image is built and pushed
docker images | grep feastflow
```

### Deployment Execution

#### Option A: Apply All Manifests (Fresh Deployment)

```bash
# Navigate to project root
cd devops/kubernetes

# Apply manifests in order (numbers ensure correct sequence)
kubectl apply -f 00-namespace.yaml
kubectl apply -f 01-configmap.yaml
kubectl apply -f 02-secrets.yaml
kubectl apply -f 03-postgres-pvc.yaml
kubectl apply -f 04-postgres-deployment.yaml
kubectl apply -f 05-postgres-service.yaml
kubectl apply -f 06-backend-deployment.yaml
kubectl apply -f 07-backend-service.yaml
kubectl apply -f 08-frontend-deployment.yaml
kubectl apply -f 09-frontend-service.yaml
kubectl apply -f 10-ingress.yaml

# Or apply all at once (only for initial deployment)
kubectl apply -f .
```

#### Option B: Update Existing Deployment (Rolling Update)

```bash
# Update image version in deployment manifest
# Then apply the changed file:
kubectl apply -f 06-backend-deployment.yaml

# Or update image directly (not recommended for prod)
kubectl set image deployment/feastflow-backend \
  backend=feastflow-backend:v1.2.0 \
  -n feastflow
```

#### Monitor Rollout

```bash
# Watch rollout status
kubectl rollout status deployment/feastflow-backend -n feastflow
kubectl rollout status deployment/feastflow-frontend -n feastflow

# Watch pods update in real-time
kubectl get pods -n feastflow -w

# Check deployment history
kubectl rollout history deployment/feastflow-backend -n feastflow
```

#### Verify Deployment

```bash
# Check all pods are running
kubectl get pods -n feastflow

# Check pod logs
kubectl logs -f deployment/feastflow-backend -n feastflow
kubectl logs -f deployment/feastflow-frontend -n feastflow

# Check service endpoints
kubectl get endpoints -n feastflow

# Test health endpoints
kubectl port-forward -n feastflow service/feastflow-backend 5000:5000
curl http://localhost:5000/api/health

# Check ingress
kubectl get ingress -n feastflow
```

---

## 3. Rollback Procedures

### Scenario 1: Deployment Has Not Stabilized

**If you catch issues during rollout:**

```bash
# Pause the rollout immediately
kubectl rollout pause deployment/feastflow-backend -n feastflow

# Investigate
kubectl describe deployment feastflow-backend -n feastflow
kubectl logs deployment/feastflow-backend -n feastflow

# Rollback to previous version
kubectl rollout undo deployment/feastflow-backend -n feastflow

# Or rollback to specific revision
kubectl rollout history deployment/feastflow-backend -n feastflow
kubectl rollout undo deployment/feastflow-backend --to-revision=2 -n feastflow
```

### Scenario 2: Deployment Completed But Has Issues

**If issues discovered after deployment:**

```bash
# Quick rollback to previous version
kubectl rollout undo deployment/feastflow-backend -n feastflow

# Verify rollback
kubectl rollout status deployment/feastflow-backend -n feastflow
kubectl get pods -n feastflow
```

### Scenario 3: Database Migration Issue

**If database migration in init container fails:**

```bash
# Check init container logs
kubectl logs <pod-name> -c db-migrations -n feastflow

# Option 1: Fix migration, update deployment
# Option 2: Run migration manually
kubectl exec -it deployment/feastflow-backend -n feastflow -- npm run migrate

# Delete failed pods to retry
kubectl delete pod <pod-name> -n feastflow
```

---

## 4. Health Checks and Readiness

### Liveness Probe (Restart Unhealthy Pods)

```yaml
livenessProbe:
  httpGet:
    path: /api/health
    port: 5000
  initialDelaySeconds: 60  # Wait 60s after start
  periodSeconds: 10        # Check every 10s
  timeoutSeconds: 5        # Timeout after 5s
  failureThreshold: 3      # Restart after 3 failures
```

**Backend Implementation (Required):**

```typescript
// backend/src/routes/healthRoutes.ts
router.get('/health', async (req, res) => {
  try {
    // Check database connection
    await db.query('SELECT 1');
    
    res.status(200).json({
      status: 'healthy',
      timestamp: new Date().toISOString(),
      service: 'backend',
      version: process.env.APP_VERSION || '1.0.0'
    });
  } catch (error) {
    res.status(500).json({
      status: 'unhealthy',
      error: error.message
    });
  }
});
```

### Readiness Probe (Remove from Load Balancer)

```yaml
readinessProbe:
  httpGet:
    path: /api/health
    port: 5000
  initialDelaySeconds: 10  # Start checking after 10s
  periodSeconds: 5         # Check every 5s
  failureThreshold: 2      # Remove after 2 failures
```

**Difference:**
- **Liveness**: Is the container alive? (If no → restart)
- **Readiness**: Is the container ready to serve traffic? (If no → remove from service)

---

## 5. Configuration Management

### Update ConfigMap (Without Restart)

```bash
# Edit configmap
kubectl edit configmap feastflow-config -n feastflow

# Or apply updated file
kubectl apply -f 01-configmap.yaml
```

⚠️ **Important:** Pods don't automatically reload ConfigMap changes. You must:

```bash
# Option 1: Rollout restart (recommended)
kubectl rollout restart deployment/feastflow-backend -n feastflow

# Option 2: Delete pods (they recreate with new config)
kubectl delete pods -l component=backend -n feastflow
```

### Update Secrets

```bash
# Update secret
kubectl create secret generic feastflow-secrets \
  --from-literal=JWT_SECRET='new-secret-key' \
  --namespace=feastflow \
  --dry-run=client -o yaml | kubectl apply -f -

# Restart pods to use new secret
kubectl rollout restart deployment/feastflow-backend -n feastflow
```

---

## 6. Scaling Operations

### Manual Scaling

```bash
# Scale backend horizontally
kubectl scale deployment feastflow-backend --replicas=5 -n feastflow

# Scale down
kubectl scale deployment feastflow-backend --replicas=2 -n feastflow

# Verify
kubectl get deployment feastflow-backend -n feastflow
```

### Horizontal Pod Autoscaler (HPA)

```bash
# Create HPA
kubectl autoscale deployment feastflow-backend \
  --cpu-percent=70 \
  --min=2 \
  --max=10 \
  -n feastflow

# Check HPA status
kubectl get hpa -n feastflow

# Describe HPA
kubectl describe hpa feastflow-backend -n feastflow

# Delete HPA
kubectl delete hpa feastflow-backend -n feastflow
```

**HPA Manifest (Alternative):**

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: feastflow-backend-hpa
  namespace: feastflow
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: feastflow-backend
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
```

---

## 7. Troubleshooting Common Issues

### Issue 1: Pods Stuck in Pending

```bash
# Check why pod is pending
kubectl describe pod <pod-name> -n feastflow

# Common causes:
# - Insufficient resources (CPU/memory)
# - PVC not bound
# - Node selector mismatch
```

**Solution:**
```bash
# Check node resources
kubectl top nodes

# Check PVC status
kubectl get pvc -n feastflow

# Adjust resource requests or add nodes
```

### Issue 2: Pods CrashLoopBackOff

```bash
# View logs
kubectl logs <pod-name> -n feastflow
kubectl logs <pod-name> -n feastflow --previous  # Previous crash

# Common causes:
# - Application error
# - Missing environment variables
# - Failed liveness probe
```

**Solution:**
```bash
# Check events
kubectl describe pod <pod-name> -n feastflow

# Verify ConfigMap/Secrets
kubectl get configmap feastflow-config -o yaml -n feastflow
```

### Issue 3: Service Not Accessible

```bash
# Check service
kubectl get svc -n feastflow
kubectl describe svc feastflow-backend -n feastflow

# Check endpoints (should list pod IPs)
kubectl get endpoints feastflow-backend -n feastflow

# Test connectivity from another pod
kubectl run test-pod --rm -it --image=busybox -n feastflow -- /bin/sh
wget -O- http://feastflow-backend:5000/api/health
```

### Issue 4: ImagePullBackOff

```bash
# Check image pull errors
kubectl describe pod <pod-name> -n feastflow

# Common causes:
# - Image doesn't exist
# - Private registry without imagePullSecrets
# - Typo in image name
```

**Solution:**
```bash
# Verify image exists
docker pull feastflow-backend:latest

# Create imagePullSecret for private registry
kubectl create secret docker-registry regcred \
  --docker-server=<registry> \
  --docker-username=<username> \
  --docker-password=<password> \
  -n feastflow
```

---

## 8. Best Practices

### Pre-Deployment Checklist

- [ ] Image built and tagged correctly
- [ ] Image pushed to registry
- [ ] Database migrations tested
- [ ] ConfigMap/Secrets updated
- [ ] Resource limits appropriate
- [ ] Health endpoints functional
- [ ] Rollback plan documented
- [ ] Monitoring/alerting configured

### During Deployment

- [ ] Watch pod status in real-time
- [ ] Monitor application logs
- [ ] Check metrics (CPU, memory, request rate)
- [ ] Test critical user flows
- [ ] Keep dev team online

### Post-Deployment

- [ ] Verify all pods healthy
- [ ] Check error logs
- [ ] Monitor for 24 hours
- [ ] Document any issues
- [ ] Update runbook

### Deployment Windows

**Recommended Times:**
- **Low traffic hours**: 2-4 AM local time
- **Mid-week**: Tuesday-Thursday (avoid Fridays)
- **Avoid**: Holiday periods, major events

**Emergency Deployments:**
- Always have second engineer available
- Faster rollback procedures
- Direct communication channels open

---

## 9. Maintenance Operations

### Drain Node for Maintenance

```bash
# Cordon node (prevent new pods)
kubectl cordon <node-name>

# Drain node (evict pods gracefully)
kubectl drain <node-name> --ignore-daemonsets --delete-emptydir-data

# Uncordon after maintenance
kubectl uncordon <node-name>
```

### Delete Namespace (Cleanup)

```bash
# Delete entire feastflow namespace
kubectl delete namespace feastflow

# Warning: This deletes EVERYTHING in the namespace
```

---

## 10. CI/CD Integration (Future)

### GitOps Workflow with ArgoCD

```yaml
# argocd application
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: feastflow
spec:
  source:
    repoURL: https://github.com/org/feastflow
    targetRevision: main
    path: devops/kubernetes
  destination:
    server: https://kubernetes.default.svc
    namespace: feastflow
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

**Benefits:**
- Git as single source of truth
- Automatic deployment on Git push
- Easy rollback (revert Git commit)
- Audit trail in Git history

---

## Summary

| Strategy | Downtime | Complexity | Rollback Speed | Use Case |
|----------|----------|------------|----------------|----------|
| Rolling Update | ✅ None | Low | Medium | Default production |
| Blue-Green | ✅ None | Medium | Instant | Critical releases |
| Canary | ✅ None | High | Fast | High-risk changes |
| Recreate | ❌ Yes | Very Low | Fast | Dev/staging |

**FeastFlow uses Rolling Update** for balance of simplicity and zero-downtime deployments.
