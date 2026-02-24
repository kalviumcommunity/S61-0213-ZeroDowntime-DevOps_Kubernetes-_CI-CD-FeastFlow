# Kubernetes Rollout & Rollback Demonstration Guide

## Purpose

This guide demonstrates **zero-downtime deployments** using Kubernetes Deployments with rolling update strategy. Perfect for Sprint video demos and understanding how production deployments work.

---

## Prerequisites

### 1. Cluster Setup

```bash
# Verify cluster is running
kubectl cluster-info
kubectl get nodes

# Verify you're in the correct context
kubectl config current-context
```

### 2. Namespace Check

```bash
# Check if feastflow namespace exists
kubectl get namespace feastflow

# If not, create it
kubectl apply -f devops/kubernetes/00-namespace.yaml
```

### 3. Initial Deployment

```bash
# Apply all manifests (if not already deployed)
kubectl apply -f devops/kubernetes/

# Wait for deployments to be ready
kubectl rollout status deployment/feastflow-backend -n feastflow
kubectl rollout status deployment/feastflow-frontend -n feastflow
```

---

## Part 1: Understanding Current State

### Check Deployment Status

```bash
# View all deployments
kubectl get deployments -n feastflow

# Expected output:
# NAME                 READY   UP-TO-DATE   AVAILABLE   AGE
# feastflow-backend    2/2     2            2           5m
# feastflow-frontend   3/3     3            3           5m
```

### View Pods

```bash
# List all pods with labels
kubectl get pods -n feastflow -o wide --show-labels

# Expected output shows pods with unique names:
# feastflow-backend-789abc123-xyz12
# feastflow-backend-789abc123-def45
# feastflow-frontend-456def789-abc78
# ...etc
```

### View ReplicaSets (The Magic Behind Deployments)

```bash
# List ReplicaSets
kubectl get replicasets -n feastflow

# Expected output:
# NAME                            DESIRED   CURRENT   READY   AGE
# feastflow-backend-789abc123     2         2         2       5m
# feastflow-frontend-456def789    3         3         3       5m
```

**Key Observation**: Each Deployment creates ONE ReplicaSet (currently). The ReplicaSet name = `{deployment-name}-{pod-template-hash}`

### Check Deployment History

```bash
# View rollout history
kubectl rollout history deployment/feastflow-backend -n feastflow

# Expected output:
# REVISION  CHANGE-CAUSE
# 1         <none>
```

**Note**: Revision 1 = initial deployment

---

## Part 2: Trigger a Rolling Update

### Method 1: Update Container Image (Most Common)

#### Step 1: Update the Image Tag

```bash
# Update backend image from 'latest' to 'v1.0.1'
kubectl set image deployment/feastflow-backend \
  backend=feastflow-backend:v1.0.1 \
  -n feastflow

# Alternative: Add annotation to record change
kubectl set image deployment/feastflow-backend \
  backend=feastflow-backend:v1.0.1 \
  -n feastflow \
  --record
```

**What happens immediately**:

- Kubernetes creates a NEW ReplicaSet for v1.0.1
- Old ReplicaSet (latest) still has 2 pods
- New ReplicaSet starts with 0 pods

#### Step 2: Watch the Rollout (CRITICAL FOR VIDEO!)

```bash
# Watch rollout status (blocks until complete)
kubectl rollout status deployment/feastflow-backend -n feastflow --watch

# Expected output:
# Waiting for deployment "feastflow-backend" rollout to finish: 0 of 2 updated replicas are available...
# Waiting for deployment "feastflow-backend" rollout to finish: 1 of 2 updated replicas are available...
# deployment "feastflow-backend" successfully rolled out
```

#### Step 3: Watch Pods in Real-Time (Open in Second Terminal)

```bash
# Terminal 2: Watch pods change
kubectl get pods -n feastflow -l component=backend --watch

# You'll see:
# feastflow-backend-789abc123-xyz12   1/1   Running      0   10m   <- OLD
# feastflow-backend-789abc123-def45   1/1   Running      0   10m   <- OLD
# feastflow-backend-abc321xyz-new11   0/1   Pending      0   1s    <- NEW
# feastflow-backend-abc321xyz-new11   0/1   ContainerCreating   0   2s
# feastflow-backend-abc321xyz-new11   1/1   Running      0   30s   <- READY!
# feastflow-backend-789abc123-xyz12   1/1   Terminating  0   10m   <- TERMINATED
# feastflow-backend-abc321xyz-new22   0/1   Pending      0   1s
# ...continues until all old pods replaced
```

#### Step 4: Observe ReplicaSet Changes

```bash
# Terminal 3: Watch ReplicaSets
kubectl get replicasets -n feastflow -l component=backend --watch

# You'll see:
# NAME                           DESIRED   CURRENT   READY   AGE
# feastflow-backend-789abc123    2         2         2       10m   <- OLD
# feastflow-backend-abc321xyz    0         0         0       1s    <- NEW
# feastflow-backend-abc321xyz    1         0         0       1s    <- Scaling up
# feastflow-backend-abc321xyz    1         1         0       2s
# feastflow-backend-abc321xyz    1         1         1       30s   <- Ready!
# feastflow-backend-789abc123    1         2         2       10m   <- Scaling down
# feastflow-backend-789abc123    1         1         1       10m
# ...continues until NEW=2, OLD=0
```

**Key Insight**: Notice how old ReplicaSet never goes below capacity because `maxUnavailable: 0`!

---

### Method 2: Update Environment Variable

```bash
# Update environment variable
kubectl set env deployment/feastflow-backend \
  JWT_EXPIRE="14d" \
  -n feastflow

# Watch the rollout
kubectl rollout status deployment/feastflow-backend -n feastflow
```

**Why this triggers update**: Changing pod template (env vars) creates new ReplicaSet

---

### Method 3: Edit Deployment Directly (Advanced)

```bash
# Open deployment in editor
kubectl edit deployment feastflow-backend -n feastflow

# Change anything in spec.template (pod template):
# - Image tag
# - Environment variables
# - Resource requests/limits
# - Command/args
# Save and exit → Rollout begins automatically
```

---

## Part 3: Verify Zero-Downtime

### Test Service Availability During Rollout

#### Terminal 1: Start Update

```bash
kubectl set image deployment/feastflow-backend \
  backend=feastflow-backend:v1.0.2 \
  -n feastflow
```

#### Terminal 2: Continuous Health Check

```bash
# Continuously hit the service
while true; do
  kubectl exec -n feastflow deployment/feastflow-frontend -- \
    curl -s http://feastflow-backend:5000/api/health
  sleep 1
done

# Should see 200 OK responses CONTINUOUSLY
# NO errors during rollout = ZERO DOWNTIME! 🎯
```

#### Terminal 3: Watch Pod Count

```bash
kubectl get pods -n feastflow -l component=backend --watch

# Notice: NEVER drops below 2 pods running
# Proof of maxUnavailable: 0 working!
```

---

## Part 4: Rollback Demonstration

### Check History

```bash
# View all revisions
kubectl rollout history deployment/feastflow-backend -n feastflow

# Expected output (after previous updates):
# REVISION  CHANGE-CAUSE
# 1         <none>
# 2         kubectl set image deployment...
# 3         kubectl set image deployment...
```

### Rollback to Previous Revision

```bash
# Rollback to revision 2
kubectl rollout undo deployment/feastflow-backend -n feastflow

# Watch the rollback
kubectl rollout status deployment/feastflow-backend -n feastflow
```

**What happens**:

- Kubernetes scales up OLD ReplicaSet (revision 2)
- Scales down CURRENT ReplicaSet (revision 3)
- Same rolling update process, just in reverse!

### Rollback to Specific Revision

```bash
# Rollback to revision 1 (original)
kubectl rollout undo deployment/feastflow-backend \
  --to-revision=1 \
  -n feastflow
```

### Verify Rollback

```bash
# Check image version returned
kubectl get deployment feastflow-backend -n feastflow -o jsonpath='{.spec.template.spec.containers[0].image}'

# Expected: feastflow-backend:latest (original)
```

---

## Part 5: Pause and Resume (Advanced)

### Pause Rollout

```bash
# Make multiple changes without triggering updates
kubectl rollout pause deployment/feastflow-backend -n feastflow

# Now make multiple changes
kubectl set image deployment/feastflow-backend \
  backend=feastflow-backend:v2.0.0 \
  -n feastflow

kubectl set env deployment/feastflow-backend \
  NEW_FEATURE_FLAG="enabled" \
  -n feastflow

# No rollout happens yet!
```

### Resume Rollout

```bash
# Resume and apply ALL changes at once
kubectl rollout resume deployment/feastflow-backend -n feastflow

# Watch the single rollout with all changes
kubectl rollout status deployment/feastflow-backend -n feastflow
```

**Use Case**: Batch multiple changes into single rollout

---

## Part 6: Understanding the Rolling Update Process

### Visual Representation

**Initial State (2 replicas)**:

```
ReplicaSet-v1: [Pod1] [Pod2]
ReplicaSet-v2: []
Running: 2 pods
```

**Step 1: Create new pod (maxSurge: 1)**:

```
ReplicaSet-v1: [Pod1] [Pod2]
ReplicaSet-v2: [Pod3-Creating]
Running: 2 pods, Creating: 1 pod
```

**Step 2: Wait for readiness probe**:

```
ReplicaSet-v1: [Pod1] [Pod2]
ReplicaSet-v2: [Pod3-Ready]
Running: 3 pods (maxSurge allows this!)
```

**Step 3: Terminate one old pod**:

```
ReplicaSet-v1: [Pod1] [Pod2-Terminating]
ReplicaSet-v2: [Pod3-Ready]
Running: 2 pods (maintained capacity!)
```

**Step 4: Create second new pod**:

```
ReplicaSet-v1: [Pod1]
ReplicaSet-v2: [Pod3-Ready] [Pod4-Creating]
Running: 2-3 pods
```

**Step 5: Wait for readiness**:

```
ReplicaSet-v1: [Pod1]
ReplicaSet-v2: [Pod3-Ready] [Pod4-Ready]
Running: 3 pods
```

**Step 6: Terminate last old pod**:

```
ReplicaSet-v1: [Pod1-Terminating]
ReplicaSet-v2: [Pod3-Ready] [Pod4-Ready]
Running: 2 pods
```

**Final State**:

```
ReplicaSet-v1: [] (kept at 0 for rollback)
ReplicaSet-v2: [Pod3] [Pod4]
Running: 2 pods ✅
```

**KEY POINT**: With `maxUnavailable: 0`, we NEVER drop below 2 running pods = **TRUE ZERO DOWNTIME**! 🎯

---

## Part 7: Debugging Rollouts

### Check Rollout Status

```bash
# Detailed status
kubectl rollout status deployment/feastflow-backend -n feastflow

# Check why a rollout is stuck
kubectl describe deployment feastflow-backend -n feastflow
```

### Check Pod Events

```bash
# Get pod name
kubectl get pods -n feastflow -l component=backend

# Describe pod to see events
kubectl describe pod <pod-name> -n feastflow

# Check logs
kubectl logs <pod-name> -n feastflow
```

### Check ReplicaSet Events

```bash
# Get ReplicaSet name
kubectl get rs -n feastflow -l component=backend

# Describe ReplicaSet
kubectl describe rs <rs-name> -n feastflow
```

### Common Issues

**Issue**: Rollout stuck at "Waiting for deployment to finish"

```bash
# Check if new pods are healthy
kubectl get pods -n feastflow -l component=backend

# Likely causes:
# - Readiness probe failing
# - Image pull error
# - Insufficient resources
```

**Issue**: Image pull error

```bash
# Fix: Use correct image tag or build image
docker build -t feastflow-backend:v1.0.1 backend/
kind load docker-image feastflow-backend:v1.0.1 --name feastflow-local
```

---

## Part 8: Comparison - Pods vs ReplicaSets vs Deployments

### With Raw Pods (DON'T DO THIS)

```bash
# Update requires DOWNTIME
kubectl delete pod feastflow-backend-pod -n feastflow    # ❌ DOWNTIME!
kubectl apply -f new-pod.yaml                            # Create new pod
# Result: Minutes of downtime while new pod starts
```

### With ReplicaSets (MANUAL PROCESS)

```bash
# Create new ReplicaSet
kubectl apply -f backend-rs-v2.yaml                      # 3 new pods

# Manually scale
kubectl scale rs backend-rs-v1 --replicas=2 -n feastflow
kubectl scale rs backend-rs-v2 --replicas=1 -n feastflow
# ...repeat many times...
kubectl scale rs backend-rs-v1 --replicas=0 -n feastflow
kubectl scale rs backend-rs-v2 --replicas=3 -n feastflow

# Delete old
kubectl delete rs backend-rs-v1 -n feastflow

# Result: Manual, error-prone, no rollback ability
```

### With Deployments (AUTOMATED)

```bash
# Update image
kubectl set image deployment/feastflow-backend \
  backend=feastflow-backend:v2 \
  -n feastflow

# That's it! Result: Automated, zero-downtime, rollback ready ✅
```

**Conclusion**: Deployments = Production-Grade Automation

---

## Part 9: Video Demo Script Commands

### Complete Demo Flow (Copy-Paste Ready)

#### Setup (Pre-Demo)

```bash
# Ensure cluster running
kubectl get nodes

# Deploy application
kubectl apply -f devops/kubernetes/
kubectl rollout status deployment/feastflow-backend -n feastflow
kubectl rollout status deployment/feastflow-frontend -n feastflow
```

#### Demo Start

**Terminal 1: Show initial state**

```bash
# Show deployments
kubectl get deployments -n feastflow

# Show pods
kubectl get pods -n feastflow -o wide

# Show ReplicaSets
kubectl get rs -n feastflow -l component=backend

# Show history
kubectl rollout history deployment/feastflow-backend -n feastflow
```

**Terminal 2: Trigger rollout**

```bash
# Update to v2
kubectl set image deployment/feastflow-backend \
  backend=feastflow-backend:v2 \
  -n feastflow --record

# Watch rollout
kubectl rollout status deployment/feastflow-backend -n feastflow --watch
```

**Terminal 3: Watch pods**

```bash
kubectl get pods -n feastflow -l component=backend --watch
```

**Terminal 4: Continuous health check**

```bash
while true; do
  kubectl exec -n feastflow deployment/feastflow-frontend -- \
    curl -s -o /dev/null -w "Status: %{http_code}\n" http://feastflow-backend:5000/api/health
  sleep 0.5
done
```

**After rollout completes**:

**Terminal 1: Verify new state**

```bash
# Show new ReplicaSet
kubectl get rs -n feastflow -l component=backend

# Notice old RS at 0 replicas, new RS at 2 replicas

# Show updated history
kubectl rollout history deployment/feastflow-backend -n feastflow
```

**Terminal 2: Demonstrate rollback**

```bash
# Rollback
kubectl rollout undo deployment/feastflow-backend -n feastflow

# Watch rollback
kubectl rollout status deployment/feastflow-backend -n feastflow
```

**Terminal 3: Verify rollback**

```bash
# Pods rolling back
kubectl get pods -n feastflow -l component=backend --watch
```

**Terminal 1: Final verification**

```bash
# Check current image
kubectl get deployment feastflow-backend -n feastflow \
  -o jsonpath='{.spec.template.spec.containers[0].image}'

# Check history (rollback creates new revision!)
kubectl rollout history deployment/feastflow-backend -n feastflow
```

---

## Part 10: Key Talking Points for Video

### Why Deployments Matter

**Say This**:

> "Deployments solve the core problem of updating applications without downtime. With raw Pods, you have to delete and recreate them, causing downtime. With ReplicaSets, you have to manually orchestrate updates across replicas. With Deployments, Kubernetes automates the entire process - creating new pods, waiting for health checks, terminating old pods, and keeping history for rollbacks."

### Zero-Downtime Strategy

**Say This**:

> "Our backend deployment uses `maxUnavailable: 0`, which means Kubernetes will NEVER reduce the number of running pods below our desired replica count. Combined with `maxSurge: 1`, Kubernetes can temporarily create extra pods during updates. So with 2 replicas, we might briefly have 3 pods running, ensuring we always have at least 2 ready to serve traffic."

### Health Checks Are Critical

**Say This**:

> "Readiness probes are what make rolling updates safe. Kubernetes doesn't add a new pod to the service load balancer until the readiness probe passes. This means we're checking that the backend can connect to the database, that Express is listening on port 5000, and that the application is truly ready before sending production traffic to it."

### ReplicaSets Under the Hood

**Say This**:

> "When I run `kubectl get replicasets`, you'll see TWO ReplicaSets for the backend. The old one at 0 replicas, and the new one at 2 replicas. Deployments keep the old ReplicaSet around for instant rollbacks. If we run `kubectl rollout undo`, Kubernetes just scales the old ReplicaSet back up - no need to redeploy images or recreate anything."

### Why Not Use Pods Directly

**Say This**:

> "In the pods-and-replicasets folder, we have examples of Pod and ReplicaSet configurations. These are for learning purposes only. Pods don't self-heal, and ReplicaSets don't handle updates automatically. In production, you should ALWAYS use Deployments for stateless applications and StatefulSets for stateful applications like databases."

---

## Summary Checklist for Video Demo

- [ ] Show initial deployment state (pods, rs, history)
- [ ] Trigger rolling update with `kubectl set image`
- [ ] Watch rollout in real-time (multiple terminals)
- [ ] Demonstrate zero-downtime with continuous health checks
- [ ] Show ReplicaSet creation and scaling
- [ ] Verify new pods running
- [ ] Check rollout history
- [ ] Demonstrate rollback
- [ ] Explain why Deployments > ReplicaSets > Pods
- [ ] Highlight `maxUnavailable: 0` strategy

---

**You now have everything needed for a comprehensive Kubernetes deployment demonstration!** 🚀

**Key Takeaway**: Deployments = Automated, Safe, Zero-Downtime, Rollback-Ready Production Deployments ✅
