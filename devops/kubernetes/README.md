# Kubernetes Integration for FeastFlow

## Overview

This directory contains Kubernetes manifests and documentation for deploying FeastFlow in a cloud-native, container-orchestrated environment.

## Why Kubernetes for FeastFlow?

### Problems Kubernetes Solves

1. **High Availability**: Automatic container restart on failure
2. **Scalability**: Horizontal scaling of frontend/backend based on load
3. **Service Discovery**: Automatic DNS-based service communication
4. **Load Balancing**: Built-in load distribution across pods
5. **Rolling Updates**: Zero-downtime deployments
6. **Resource Management**: CPU/Memory limits and requests
7. **Configuration Management**: Centralized configs via ConfigMaps/Secrets
8. **Self-Healing**: Automatic pod replacement and rescheduling

### Kubernetes Responsibilities vs Developer/Ops

| Responsibility             | Before K8s (Manual)                | With Kubernetes                 |
| -------------------------- | ---------------------------------- | ------------------------------- |
| Container restart on crash | Manual monitoring, restart scripts | Automatic via ReplicaSets       |
| Load balancing             | External LB setup (nginx, HAProxy) | Built-in Service load balancing |
| Service discovery          | Manual IP management, DNS config   | Automatic K8s DNS               |
| Scaling                    | Manual server provisioning         | `kubectl scale` or HPA          |
| Health monitoring          | Custom scripts, cron jobs          | Liveness/Readiness probes       |
| Configuration              | Environment files on servers       | ConfigMaps and Secrets          |
| Storage                    | Manual volume management           | PersistentVolumeClaims          |
| Networking                 | Complex iptables, routing          | Network Policies, Ingress       |

## Architecture

```
┌─────────────────────────────────────────────────┐
│              Ingress Controller                  │
│         (nginx-ingress/LoadBalancer)            │
└──────────────┬──────────────────────────────────┘
               │
       ┌───────┴────────┐
       │                │
   ┌───▼────┐      ┌───▼────┐
   │Frontend│      │Backend │
   │Service │      │Service │
   │(ClusterIP)    │(ClusterIP)
   └───┬────┘      └───┬────┘
       │                │
   ┌───▼────┐      ┌───▼────┐
   │Frontend│◄─────►Backend │
   │  Pods  │      │  Pods  │
   │(1-5)   │      │(1-3)   │
   └────────┘      └───┬────┘
                       │
                  ┌────▼─────┐
                  │PostgreSQL│
                  │ Service  │
                  │(StatefulSet)
                  └──────────┘
```

## Directory Structure

```
kubernetes/
├── README.md                          # This file
├── 00-namespace.yaml                  # Namespace isolation
├── 01-configmap.yaml                  # Application configurations
├── 02-secrets.yaml                    # Sensitive data (DB passwords, JWT keys)
├── 03-postgres-pvc.yaml               # Persistent volume claim for database
├── 04-postgres-deployment.yaml        # PostgreSQL StatefulSet
├── 05-postgres-service.yaml           # Database internal service
├── 06-backend-deployment.yaml         # Backend API deployment
├── 07-backend-service.yaml            # Backend service (ClusterIP)
├── 08-frontend-deployment.yaml        # Next.js frontend deployment
├── 09-frontend-service.yaml           # Frontend service
├── 10-ingress.yaml                    # External access configuration
├── 12-backend-hpa.yaml                # Horizontal Pod Autoscaler configurations
├── 13-persistence-demo.yaml            # PVC + pod-mounted persistence demo workload
├── 14-rbac-basics.yaml                 # Least-privilege RBAC (Role + RoleBinding)
├── rollout-demo.ps1                   # Rolling update + rollback demo (Windows)
├── rollout-demo.sh                    # Rolling update + rollback demo (Linux/Mac)
├── HEALTH_CHECKS_DEMO.md              # Liveness/readiness behavior demo guide
├── SCALING_GUIDE.md                   # Comprehensive scaling guide (manual + HPA)
├── PERSISTENCE_DEMO.md                # Persistent storage verification guide
├── scaling-demo.ps1                   # Manual scaling demo (Windows)
├── scaling-demo.sh                    # Manual scaling demo (Linux/Mac)
├── hpa-load-test.ps1                  # HPA load test & verification (Windows)
├── hpa-load-test.sh                   # HPA load test & verification (Linux/Mac)
├── verify-persistence.ps1             # PVC persistence proof script (Windows)
├── verify-persistence.sh              # PVC persistence proof script (Linux/Mac)
├── verify-rbac.ps1                    # RBAC allow/deny proof script (Windows)
├── verify-rbac.sh                     # RBAC allow/deny proof script (Linux/Mac)
├── verify-ingress.ps1                 # Ingress controller + HTTP routing verification (Windows)
├── verify-ingress.sh                  # Ingress controller + HTTP routing verification (Linux/Mac)
├── cloud-native-architecture.md       # Detailed architecture document
└── deployment-strategy.md             # Deployment and rollback strategies
```

## Quick Start

### Prerequisites

- Kubernetes cluster (minikube, kind, or cloud provider)
- kubectl configured
- Docker images built and pushed to registry

## Local Cluster Setup (kind)

This project includes a local `kind` workflow for Sprint #3 experimentation.

### Prerequisites

- Docker
- kind
- kubectl

### Create and Verify Local Cluster

```bash
bash devops/kubernetes/setup-kind.sh
```

The script will:

1. Create a local cluster named `feastflow-local`
2. Install **NGINX Ingress Controller** (`ingress-nginx`) for real ingress traffic routing
3. Build local images used by manifests (`feastflow-backend:latest`, `feastflow-frontend:latest`)
4. Load images into the kind cluster
5. Apply FeastFlow Kubernetes manifests (including Ingress resource)
6. Verify connectivity and rollout status

### kubectl Verification Commands

```bash
kubectl config current-context
kubectl cluster-info
kubectl get nodes
kubectl get pods -n feastflow
kubectl get services -n feastflow
```

### Why This Local Cluster Matters

Using a local cluster validates Kubernetes workflows before cloud deployment:

- confirms manifests are deployable
- confirms `kubectl` connectivity and troubleshooting flow
- supports safe testing of rollout/rollback behavior in development

### Deploy FeastFlow

```bash
# Apply all manifests in order
kubectl apply -f devops/kubernetes/

# Check deployment status
kubectl get pods -n feastflow
kubectl get services -n feastflow

# Watch rollout
kubectl rollout status deployment/feastflow-backend -n feastflow
kubectl rollout status deployment/feastflow-frontend -n feastflow
```

### Access Application

```bash
# Confirm ingress object and controller
kubectl get ingress -n feastflow
kubectl get pods -n ingress-nginx

# Option A: hosts file mapping
# 127.0.0.1 feastflow.local
curl http://feastflow.local/
curl http://feastflow.local/api/health

# Option B: no hosts update needed (Host header)
curl -H "Host: feastflow.local" http://localhost/
curl -H "Host: feastflow.local" http://localhost/api/health

# Automated verification script
# Windows: .\devops\kubernetes\verify-ingress.ps1
# Linux/Mac: bash devops/kubernetes/verify-ingress.sh
```

## Key Concepts Demonstrated

### 1. Declarative Configuration

All infrastructure defined as code in YAML manifests

### 2. Service Discovery

Services communicate via K8s DNS:

- `postgres.feastflow.svc.cluster.local:5432`
- `feastflow-backend.feastflow.svc.cluster.local:5000`

### 3. Health Checks

- **Liveness Probes**: Restart unhealthy containers
- **Readiness Probes**: Remove from load balancer when not ready

### 4. Resource Management

```yaml
resources:
  requests:
    memory: "256Mi"
    cpu: "100m"
  limits:
    memory: "512Mi"
    cpu: "500m"
```

### 5. Configuration Separation

- Application code in containers
- Configuration in ConfigMaps
- Secrets in Secrets (base64 encoded, can use sealed-secrets)

### 6. Scaling Strategy

#### Manual Scaling

```bash
# Scale to specific replica count
kubectl scale deployment feastflow-backend --replicas=5 -n feastflow

# Run interactive manual scaling demo
# Windows:
./scaling-demo.ps1

# Linux/Mac:
./scaling-demo.sh
```

#### Horizontal Pod Autoscaler (HPA)

```bash
# Apply HPA configurations (CPU and memory-based)
kubectl apply -f 12-backend-hpa.yaml

# View HPA status
kubectl get hpa -n feastflow

# Run automated load test to trigger HPA
# Windows:
./hpa-load-test.ps1 -Duration 180 -Concurrent 10

# Linux/Mac:
./hpa-load-test.sh --duration 180 --concurrent 10
```

**HPA Configuration**:

- **Backend**: 2-10 replicas, scales at 70% CPU / 80% memory
- **Frontend**: 2-8 replicas, scales at 60% CPU
- **Scale-up**: Fast (0s stabilization window)
- **Scale-down**: Conservative (5-min stabilization window)

📖 **Complete Guide**: See [SCALING_GUIDE.md](SCALING_GUIDE.md) for:

- Prerequisites and setup
- Manual scaling methods and demos
- HPA configuration details
- Load testing and verification
- Troubleshooting common issues
- Real-world scenarios and best practices

### 7. Resource Requests and Limits Verification

Use the dedicated script to prove that workloads schedule correctly with defined requests and stay constrained by limits.

```bash
bash devops/kubernetes/verify-resource-management.sh
```

```powershell
.\devops\kubernetes\verify-resource-management.ps1
```

See `devops/kubernetes/RESOURCE_MANAGEMENT_DEMO.md` for the full Sprint #3 demonstration checklist.

### 8. Rolling Updates and Rollbacks Verification

Use the rollout demo scripts to produce a full Sprint #3 proof flow:

1. successful rolling update (new Deployment revision)
2. failed rollout simulation
3. rollback to last stable revision

```powershell
.\devops\kubernetes\rollout-demo.ps1
```

```bash
bash devops/kubernetes/rollout-demo.sh
```

Optional mode to run only the successful update path:

```powershell
.\devops\kubernetes\rollout-demo.ps1 -SkipFailedUpdate
```

### 9. Persistent Storage Verification (PVC)

Use the persistence verification scripts to prove that data written inside a pod-mounted volume survives pod replacement.

```powershell
.\devops\kubernetes\verify-persistence.ps1
```

```bash
bash devops/kubernetes/verify-persistence.sh
```

📖 Full walkthrough: `devops/kubernetes/PERSISTENCE_DEMO.md`

### 10. External Traffic Routing with Ingress

This project uses **Ingress + Services** for external traffic entry instead of exposing each application Pod directly.

#### Why Services Alone Are Not Enough for Real-World External Access

- `ClusterIP` Services are internal-only (reachable inside the cluster)
- `NodePort` can expose apps, but it is coarse-grained and not ideal for production URL routing
- Services do not provide Layer-7 routing rules like host/path-based traffic splitting
- Ingress provides a single HTTP/HTTPS entry point and routes traffic to the correct Service

#### Request Flow (Internet → Pod)

1. **Client request** reaches the **Ingress Controller** (for example nginx ingress)
2. Controller reads routing rules from the **Ingress resource** (`10-ingress.yaml`)
3. Matching rule forwards traffic to the target **Service** (`feastflow-frontend` or `feastflow-backend`)
4. Service load-balances to a healthy **Pod endpoint** selected by labels

Flow summary:

`Internet client → Ingress Controller → Ingress rules → Service → Pod`

#### Host and Path Rules in This Project

Defined in `10-ingress.yaml`:

- Host: `feastflow.local`
- Path `/` routes to frontend service on port `3000`
- Path `/api` routes to backend service on port `5000`

#### Controller Dependency (Critical)

Ingress resources do not route traffic by themselves.

- The **NGINX Ingress Controller** watches `Ingress` objects from the Kubernetes API
- It converts host/path rules into active NGINX runtime configuration
- Without the controller, `kubectl get ingress` can show rules, but external HTTP requests will not be routed

For kind, this repository installs the controller automatically in:

- `setup-kind.ps1`
- `setup-kind.sh`

This gives a clean single-domain experience while keeping internal service networking private and Kubernetes-native.

### 11. Securing Cluster Access with RBAC Basics

This repository demonstrates least-privilege access by binding a namespace-scoped read-only `Role` to a dedicated `ServiceAccount`.

Resources:

- `14-rbac-basics.yaml`
  - `ServiceAccount`: `feastflow-readonly-sa`
  - `Role`: `feastflow-readonly-role`
  - `RoleBinding`: `feastflow-readonly-binding`

Allowed actions in `feastflow` namespace:

- `get`, `list`, `watch` on `pods`, `services`, `deployments`

Denied actions (intentionally excluded):

- mutating verbs like `create`, `update`, `patch`, `delete`
- sensitive resources like `secrets`

Verification scripts:

```powershell
.\devops\kubernetes\verify-rbac.ps1
```

```bash
bash devops/kubernetes/verify-rbac.sh
```

Expected proof outcomes:

1. Allowed read actions return `yes` (`kubectl auth can-i ...`)
2. Disallowed mutating/sensitive actions return `no`
3. Real command against restricted resource fails with `Forbidden`

Why this access level is appropriate:

- It supports day-to-day operational visibility (read-only monitoring)
- It prevents accidental or unauthorized cluster changes
- It limits blast radius in shared-team environments

## Cloud-Native Principles Applied

1. **Containerized**: All services run in containers
2. **Dynamically Orchestrated**: Kubernetes manages scheduling
3. **Microservices-Oriented**: Loosely coupled services
4. **Declarative APIs**: YAML manifests define desired state
5. **Observable**: Health checks, logging, metrics
6. **Resilient**: Self-healing, auto-restart
7. **Scalable**: Horizontal scaling capability

## Monitoring and Observability

```bash
# View logs
kubectl logs -f deployment/feastflow-backend -n feastflow

# Describe resources
kubectl describe pod <pod-name> -n feastflow

# Check events
kubectl get events -n feastflow --sort-by='.lastTimestamp'

# Resource usage
kubectl top pods -n feastflow
kubectl top nodes
```

## Next Steps

1. ✅ ~~Implement Horizontal Pod Autoscaler (HPA)~~ - **Completed! See [SCALING_GUIDE.md](SCALING_GUIDE.md)**
2. ✅ ~~Implement persistent storage verification (PVC + restart proof)~~ - **Completed! See [PERSISTENCE_DEMO.md](PERSISTENCE_DEMO.md)**
3. Add Prometheus/Grafana for metrics
4. Configure centralized logging (EFK stack)
5. Implement Network Policies for security
6. Add helm charts for easier deployment
7. CI/CD pipeline integration with kubectl/helm
8. Implement Cluster Autoscaler for node-level scaling
9. Add custom metrics for HPA (request rate, queue length)

## References

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [12-Factor App Methodology](https://12factor.net/)
- [Cloud Native Computing Foundation](https://www.cncf.io/)
