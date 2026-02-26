# Quick Start: Scaling Demonstrations

This guide provides quick commands to run the scaling demonstrations.

## Prerequisites

```bash
# Ensure cluster is running
kubectl cluster-info

# Ensure FeastFlow is deployed
kubectl get deployments -n feastflow
```

## 1. Manual Scaling Demo (5 minutes)

### Windows (PowerShell)

```powershell
cd devops/kubernetes
.\scaling-demo.ps1
```

### Linux/Mac (Bash)

```bash
cd devops/kubernetes
chmod +x scaling-demo.sh
./scaling-demo.sh
```

**What it shows**:

- Scale deployment from 2 → 5 → 3 → 2 replicas
- Watch pods come online in real-time
- Demonstrate zero-downtime scaling
- Show service endpoint registration
- Display ReplicaSet management

---

## 2. Horizontal Pod Autoscaler Demo (10 minutes)

### Step 1: Apply HPA Configuration

```bash
kubectl apply -f devops/kubernetes/12-backend-hpa.yaml
```

### Step 2: Verify HPA

```bash
kubectl get hpa -n feastflow
```

### Step 3: Run Load Test

**Windows (PowerShell)**:

```powershell
cd devops/kubernetes
.\hpa-load-test.ps1
```

**Linux/Mac (Bash)**:

```bash
cd devops/kubernetes
chmod +x hpa-load-test.sh
./hpa-load-test.sh
```

**What it does**:

- Installs/configures metrics-server if needed
- Generates CPU load on backend
- Monitors HPA scaling decisions in real-time
- Shows pod metrics and replica changes
- Displays scaling events

### Custom Parameters

**PowerShell**:

```powershell
# 5-minute test with 20 concurrent requests
.\hpa-load-test.ps1 -Duration 300 -Concurrent 20 -Target "backend"
```

**Bash**:

```bash
# 5-minute test with 20 concurrent requests
./hpa-load-test.sh --duration 300 --concurrent 20 --target backend
```

---

## 3. Manual HPA Monitoring

```bash
# Watch HPA status continuously
kubectl get hpa -n feastflow --watch

# View detailed HPA information
kubectl describe hpa feastflow-backend-hpa -n feastflow

# Check pod CPU/memory usage
kubectl top pods -n feastflow -l component=backend

# View scaling events
kubectl get events -n feastflow --field-selector involvedObject.name=feastflow-backend-hpa
```

---

## Quick Reference Commands

### Manual Scaling

```bash
# Scale to specific count
kubectl scale deployment feastflow-backend --replicas=5 -n feastflow

# Check current replicas
kubectl get deployment feastflow-backend -n feastflow

# Watch pods
kubectl get pods -n feastflow -l component=backend --watch
```

### HPA Management

```bash
# Apply HPA
kubectl apply -f devops/kubernetes/12-backend-hpa.yaml

# Get HPA status
kubectl get hpa -n feastflow

# Delete HPA (to switch back to manual scaling)
kubectl delete hpa feastflow-backend-hpa -n feastflow

# Edit HPA dynamically
kubectl edit hpa feastflow-backend-hpa -n feastflow
```

### Troubleshooting

```bash
# Check if metrics-server is running
kubectl get deployment metrics-server -n kube-system

# View metrics-server logs
kubectl logs -n kube-system deployment/metrics-server

# Test metrics availability
kubectl top nodes
kubectl top pods -n feastflow
```

---

## Expected Results

### Manual Scaling Demo

- ✅ Pods scale up/down instantly
- ✅ No service disruption during scaling
- ✅ Service automatically registers new pods
- ✅ Old pods terminate gracefully

### HPA Load Test

- ✅ CPU usage increases to 70%+
- ✅ HPA triggers scale-up (2 → 4 → 6 replicas)
- ✅ New pods distribute the load
- ✅ CPU usage stabilizes below threshold
- ✅ After load stops, gradual scale-down (5-min window)

---

## Full Documentation

📖 **Comprehensive Guide**: [SCALING_GUIDE.md](SCALING_GUIDE.md)

- Detailed explanations
- Architecture diagrams
- Troubleshooting section
- Real-world scenarios
- Best practices

---

## File Reference

| File                  | Purpose                                    |
| --------------------- | ------------------------------------------ |
| `12-backend-hpa.yaml` | HPA configuration for backend and frontend |
| `scaling-demo.ps1`    | Manual scaling demo (Windows)              |
| `scaling-demo.sh`     | Manual scaling demo (Linux/Mac)            |
| `hpa-load-test.ps1`   | HPA load test script (Windows)             |
| `hpa-load-test.sh`    | HPA load test script (Linux/Mac)           |
| `SCALING_GUIDE.md`    | Complete documentation                     |
| `QUICKSTART.md`       | This file                                  |

---

**Ready to scale? Start with the manual demo, then move to HPA! 🚀**
