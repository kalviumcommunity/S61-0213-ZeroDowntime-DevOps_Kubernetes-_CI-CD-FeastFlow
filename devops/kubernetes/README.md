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

| Responsibility | Before K8s (Manual) | With Kubernetes |
|----------------|---------------------|-----------------|
| Container restart on crash | Manual monitoring, restart scripts | Automatic via ReplicaSets |
| Load balancing | External LB setup (nginx, HAProxy) | Built-in Service load balancing |
| Service discovery | Manual IP management, DNS config | Automatic K8s DNS |
| Scaling | Manual server provisioning | `kubectl scale` or HPA |
| Health monitoring | Custom scripts, cron jobs | Liveness/Readiness probes |
| Configuration | Environment files on servers | ConfigMaps and Secrets |
| Storage | Manual volume management | PersistentVolumeClaims |
| Networking | Complex iptables, routing | Network Policies, Ingress |

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
2. Build local images used by manifests (`feastflow-backend:latest`, `feastflow-frontend:latest`)
3. Load images into the kind cluster
4. Apply FeastFlow Kubernetes manifests
5. Verify connectivity and rollout status

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
# Get ingress address
kubectl get ingress -n feastflow

# Port-forward for local testing
kubectl port-forward -n feastflow service/feastflow-frontend 3000:3000
kubectl port-forward -n feastflow service/feastflow-backend 5000:5000
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
```bash
# Manual scaling
kubectl scale deployment feastflow-backend --replicas=5 -n feastflow

# Horizontal Pod Autoscaler (HPA)
kubectl autoscale deployment feastflow-backend \
  --cpu-percent=70 \
  --min=2 \
  --max=10 \
  -n feastflow
```

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

1. Implement Horizontal Pod Autoscaler (HPA)
2. Add Prometheus/Grafana for metrics
3. Configure centralized logging (EFK stack)
4. Implement Network Policies for security
5. Add helm charts for easier deployment
6. CI/CD pipeline integration with kubectl/helm

## References

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [12-Factor App Methodology](https://12factor.net/)
- [Cloud Native Computing Foundation](https://www.cncf.io/)

