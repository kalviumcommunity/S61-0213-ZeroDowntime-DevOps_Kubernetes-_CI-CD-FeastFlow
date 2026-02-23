# Kubernetes Cluster Architecture for FeastFlow

## Executive Summary

This document outlines the complete architecture of a Kubernetes cluster running FeastFlow. It explains not just what components exist, but **why** they're needed and **how** they interact to create a resilient, self-healing platform for production applications.

---

## 1. Kubernetes Cluster Overview

A Kubernetes cluster is a **distributed system** that manages containerized applications across multiple machines. Unlike Docker Compose (single-host), Kubernetes spans multiple nodes (physical or virtual servers) and automatically handles application deployment, scaling, and networking.

### Cluster Definition

```
┌─────────────────────────────────────────────────────────────┐
│                  KUBERNETES CLUSTER                         │
│                                                             │
│  ┌───────────────────────────────────────────────────────┐ │
│  │           CONTROL PLANE (Master Node)                 │ │
│  │  - API Server: Cluster's brain (REST API endpoint)   │ │
│  │  - etcd: Distributed state store (cluster database)  │ │
│  │  - Scheduler: Assigns pods to worker nodes           │ │
│  │  - Controller Manager: Manages cluster state         │ │
│  └───────────────────────────────────────────────────────┘ │
│                        │                                    │
│          ┌─────────────┼─────────────┐                     │
│          │             │             │                     │
│  ┌───────▼──────┐ ┌───▼──────┐ ┌───▼──────┐              │
│  │ WORKER NODE 1│ │WORKER NODE│ │WORKER NODE│             │
│  │              │ │    2      │ │    N      │             │
│  │ - kubelet    │ │           │ │           │             │
│  │ - kube-proxy │ │ - kubelet │ │           │             │
│  │ - container  │ │ - kube-proxy│- kubelet │             │
│  │   runtime    │ │ - runtime │ │- runtime │             │
│  │              │ │           │ │           │             │
│  │ [Pod] [Pod]  │ │[Pod][Pod] │ │[Pod][Pod] │             │
│  └──────────────┘ └───────────┘ └───────────┘             │
│                                                             │
│  ┌────────────────────────────────────────────────────────┐│
│  │         CLUSTER-LEVEL SERVICES                         ││
│  │ - DNS (CoreDNS): Service discovery                     ││
│  │ - Ingress Controller: External traffic routing         ││
│  │ - Storage Classes: Persistent volume management        ││
│  └────────────────────────────────────────────────────────┘│
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 2. Control Plane (Master Node) Components

The Control Plane is the **brain** of the Kubernetes cluster. It makes all decisions about what runs where and how to handle failures.

### 2.1 API Server (`kube-apiserver`)

**What it does:**
- Accepts all requests to the Kubernetes cluster (via `kubectl` or REST)
- Validates requests and manages cluster state
- The only component that talks to etcd

**Why it matters for FeastFlow:**
```bash
# Every deployment operation goes through the API Server:
kubectl apply -f deployment.yaml  # → API Server validates → stores in etcd
kubectl get pods                   # → API Server queries etcd
```

**Example flow:**
1. User runs: `kubectl apply -f 06-backend-deployment.yaml`
2. API Server validates the YAML
3. API Server stores the desired state in etcd
4. Other control plane components react to this change

### 2.2 etcd (Distributed Database)

**What it does:**
- Stores ALL cluster state in key-value format
- Distributed consensus database (like a cluster-wide database)
- Single source of truth for cluster state

**Why it matters:**
```yaml
# When you define this deployment:
kind: Deployment
metadata:
  name: feastflow-backend
spec:
  replicas: 3

# etcd stores:
/kubernetes.io/deployments/default/feastflow-backend:
  {
    "replicas": 3,
    "selector": {...},
    "template": {...}
  }
```

**Critical characteristic:**
- **Highly available**: Multiple copies across control plane nodes
- **Strongly consistent**: All nodes see the same state
- If etcd is lost → entire cluster knowledge is lost

### 2.3 Scheduler (`kube-scheduler`)

**What it does:**
- Watches for new Pods that need to be placed
- Decides which worker node each Pod should run on
- Makes decisions based on:
  - Resource requests/limits
  - Node affinity rules
  - Taints and tolerations

**Real example for FeastFlow:**
```yaml
# In 06-backend-deployment.yaml
spec:
  template:
    spec:
      containers:
      - name: backend
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 500m
            memory: 512Mi
```

When a Pod with these requirements is created:
1. Scheduler sees: "Need 100m CPU, 128Mi RAM"
2. Checks all worker nodes for available resources
3. Places Pod on node with enough resources
4. Kubelet on that node pulls image and starts container

### 2.4 Controller Manager (`kube-controller-manager`)

**What it does:**
Runs multiple controllers that continuously reconcile current state with desired state.

**Key controllers:**

| Controller | Does What | FeastFlow Example |
|-----------|-----------|------------------|
| Deployment Controller | Manages Deployments, creates ReplicaSets | Ensures 3 backend pods always running |
| ReplicaSet Controller | Ensures correct # of pod replicas | If 1 backend pod crashes, creates new one |
| Service Controller | Creates endpoints for services | Maintains list of Pod IPs for backend service |
| Node Controller | Monitors and manages nodes | Marks unavailable nodes as NotReady |
| StatefulSet Controller | Manages StatefulSets (ordered pods) | Ensures PostgreSQL pod identity persists |

**Reconciliation example:**
```
Desired State (in etcd):
  feastflow-backend: replicas=3

Current State (observed):
  feastflow-backend: replicas=2 (1 pod crashed)

Controller Action:
  "Current ≠ Desired → Create 1 new pod"
```

---

## 3. Worker Nodes

Worker nodes are where **actual application containers run**. Unlike the control plane (which makes decisions), worker nodes execute decisions.

### 3.1 kubelet (Node Agent)

**What it does:**
- Runs on every worker node
- Receives Pod deployment specs from API Server
- Manages the container lifecycle on that node

**FeastFlow example:**
```
Scheduler assigns backend pod to worker-node-1
    ↓
API Server sends pod spec to kubelet on worker-node-1
    ↓
kubelet pulls Docker image: feastflow-backend:latest
    ↓
kubelet creates container via container runtime
    ↓
kubelet monitors container health (liveness probes)
    ↓
Container crashes → kubelet reports to API Server
    ↓
Controller Manager sees failed pod → Creates replacement
```

### 3.2 kube-proxy (Network Agent)

**What it does:**
- Manages network rules for service-to-pod routing
- Implements service load balancing (distributes traffic)
- Makes service DNS resolution work

**Network flow in FeastFlow:**
```
Frontend Pod wants to connect to Backend Service
    ↓
DNS lookup: "feastflow-backend.default.svc.cluster.local"
    ↓
kube-proxy has rule: 
  "Traffic to feastflow-backend:5000 → distribute to pod IPs"
    ↓
kube-proxy uses iptables/IPVS to load balance across:
  - 10.244.0.5:5000 (backend pod 1)
  - 10.244.0.6:5000 (backend pod 2)
  - 10.244.0.7:5000 (backend pod 3)
    ↓
Request hits one backend instance
```

### 3.3 Container Runtime

**What it does:**
- Pulls and runs container images
- Typically Docker, containerd, or CRI-O
- Implements container lifecycle

---

## 4. FeastFlow on Kubernetes - Complete Flow

### 4.1 Deployment Flow

```
User Context: Deploying 3 backend replicas
┌────────────────────────────────────────────────────────────────┐

1. DECLARATION PHASE (Developer → API Server)
   └─► kubectl apply -f 06-backend-deployment.yaml
       │
       └─► API Server validates and stores in etcd:
           {
             "kind": "Deployment",
             "name": "feastflow-backend",
             "replicas": 3,
             "image": "feastflow-backend:latest"
           }

2. SCHEDULING PHASE (Scheduler → Worker Nodes)
   └─► Scheduler observes: "3 new pods needed"
       │
       ├─► Pod 1: Assign to worker-node-1 (has 200m free CPU)
       ├─► Pod 2: Assign to worker-node-2 (has 200m free CPU)
       └─► Pod 3: Assign to worker-node-3 (has 200m free CPU)

3. EXECUTION PHASE (kubelet → Container Runtime)
   └─► kubelet on worker-node-1:
       ├─► Pull image: feastflow-backend:latest
       ├─► Create container with environment variables
       ├─► Start container
       └─► Begin monitoring health

4. NETWORKING PHASE (kube-proxy → iptables)
   └─► kube-proxy on all nodes updates:
       Service: feastflow-backend
       Endpoints: [10.244.0.5, 10.244.0.6, 10.244.0.7]

5. SERVICE DISCOVERY PHASE (CoreDNS)
   └─► Frontend can now resolve:
       feastflow-backend → Service IP → kube-proxy → backends

RESULT: 3 backend containers running, accessible via DNS, load-balanced
└────────────────────────────────────────────────────────────────┘
```

### 4.2 Self-Healing Example

```
Scenario: One backend pod crashes

Current State:
  Pod-1: Running ✓
  Pod-2: Running ✓
  Pod-3: Crashed ✗

Timeline:

T+0s: Container stops
  └─► kubelet detects: "Container exited code 1"
      └─► Reports to API Server: "pod-3 failed"

T+5s: Controller Manager detects mismatch
  └─► Current: 2 running pods
      Desired: 3 replicas
      Action: Create new pod-4

T+10s: Scheduler assigns pod-4
  └─► Place on worker-node-1 (least loaded)
      └─► Return assignment to API Server

T+15s: kubelet executes
  └─► Pull image → Create container → Start
      └─► Update kube-proxy with new endpoint

T+20s: Service updated
  └─► Old endpoint (failed pod): Removed
      New endpoint (replacement pod): Added
      No traffic disruption to existing requests

Result: Service healed automatically without admin intervention
```

---

## 5. FeastFlow Architecture Components

### 5.1 Application Services

#### Frontend Service
```yaml
kind: Service
metadata:
  name: feastflow-frontend
spec:
  type: ClusterIP
  ports:
  - port: 3000
    targetPort: 3000
```

**What it provides:**
- Internal DNS name: `feastflow-frontend.default.svc.cluster.local`
- Load balances traffic across all frontend pods
- kube-proxy maintains backend list (pod IPs)

**Why ClusterIP?**
- Not exposed externally (no need - Ingress handles that)
- Only accessible from within cluster (pod-to-pod communication)
- Stable endpoint (unlike pod IPs which change)

#### Backend Service
```yaml
kind: Service
metadata:
  name: feastflow-backend
spec:
  type: ClusterIP
  ports:
  - port: 5000
    targetPort: 5000
```

**What it provides:**
- Internal DNS: `feastflow-backend.default.svc.cluster.local`
- Fronted: Load balances across 3 backend pods
- Stable while pods are created/destroyed

#### Database Service
```yaml
kind: Service
metadata:
  name: postgres
spec:
  type: ClusterIP
  ports:
  - port: 5432
    targetPort: 5432
```

**Critical:** Database service points to StatefulSet pod with persistent volume
- Ensures backend always connects to same database instance
- Persistent volume survives pod restarts

### 5.2 Ingress Controller

```
┌─────────────────────────────────────┐
│        EXTERNAL TRAFFIC             │
│   (Browser, API Clients)            │
└────────────────┬────────────────────┘
                 │ HTTP/HTTPS
                 ▼
      ┌──────────────────────┐
      │ Ingress Controller   │
      │ (nginx-ingress)      │
      │                      │
      │ Rules:               │
      │ / → frontend-service │
      │ /api → backend-service
      └──────────────────────┘
                 │
         ┌───────┴───────┐
         ▼               ▼
    Frontend          Backend
    Service           Service
        │                 │
        ▼                 ▼
    Frontend          Backend
    Pods              Pods
```

**FeastFlow configuration:**
```yaml
kind: Ingress
metadata:
  name: feastflow-ingress
spec:
  rules:
  - http:
      paths:
      - path: /api
        backend: feastflow-backend:5000
      - path: /
        backend: feastflow-frontend:3000
```

---

## 6. Kubernetes vs Docker Compose: Architecture Comparison

### Docker Compose (Single Host)
```
┌───────────────────────────┐
│   Single Docker Host      │
│                           │
│  ┌─────────────────────┐  │
│  │  Frontend Container │  │
│  └─────────────────────┘  │
│  ┌─────────────────────┐  │
│  │  Backend Container  │  │
│  └─────────────────────┘  │
│  ┌─────────────────────┐  │
│  │  Database Container │  │
│  └─────────────────────┘  │
│                           │
│  Networking: docker0 bridge
│  Volume: /var/lib/docker
│                           │
└───────────────────────────┘

Limitations:
❌ No auto-scaling
❌ No self-healing
❌ Host failure = app down
❌ Manual load balancing
❌ No service discovery
❌ Limited resource management
```

### Kubernetes (Multi-Host)
```
Control Plane (etcd, API Server, Scheduler, Controllers)
              ↓
├─ Worker-1 ──┼─ Worker-2 ──┼─ Worker-3 ──┤
│             │              │             │
│ Frontend    │ Frontend     │ Backend     │
│ Backend     │ Backend      │ Database    │
│             │ Database     │ Backend     │
│             │              │             │
└─────────────┴──────────────┴─────────────┘

Advantages:
✅ Auto-scaling (HPA)
✅ Self-healing (restart failed pods)
✅ Node failure resilience (reschedule to other nodes)
✅ Built-in load balancing (Services)
✅ Service discovery (DNS)
✅ Fine-grained resource management (requests/limits)
✅ Rolling updates (zero downtime)
```

---

## 7. Interaction Between Components in FeastFlow

### 7.1 Frontend Pod Connecting to Backend

```
1. Frontend Pod Startup
   ├─ Container started with env: NEXT_PUBLIC_API_URL=feastflow-backend:5000
   └─ Application initialization

2. Frontend tries to reach backend API
   ├─ Application code: fetch('feastflow-backend:5000/api/restaurants')
   └─ Pod's DNS resolver (/etc/resolv.conf)

3. DNS Lookup
   ├─ Query: feastflow-backend.default.svc.cluster.local
   ├─ CoreDNS responds: 10.96.0.100 (Service IP, stable)
   └─ Not a pod IP (which changes), but a virtual IP

4. Route Decision
   ├─ kube-proxy has iptables rule: "10.96.0.100:5000 → ..."
   ├─ Rule load-balances to one of:
   │  - 10.244.0.5:5000 (backend pod 1)
   │  - 10.244.0.6:5000 (backend pod 2)
   │  - 10.244.0.7:5000 (backend pod 3)
   └─ Connection forwarded via iptables DNAT

5. Backend Request Processed
   ├─ Backend pod receives request
   ├─ Processes query (auth, data fetch, etc.)
   └─ Responds to frontend

6. Pod Crash Scenario
   ├─ Backend pod-2 crashes
   ├─ kubelet reports failure to API Server
   ├─ Deployment Controller creates pod-4
   ├─ kube-proxy updates rule:
   │  "10.96.0.100:5000 → [10.244.0.5, 10.244.0.6, 10.244.0.7, 10.244.0.8]"
   └─ Frontend retries failing requests to other pods (automatic)

RESULT: Frontend communication always works despite pod failures
```

### 7.2 Data Persistence (Database Pod)

```
1. Initial Deployment
   ├─ PersistentVolumeClaim created: postgres-pvc
   ├─ Kubernetes provisions PersistentVolume (PV)
   ├─ Pod mounts PV at /var/lib/postgresql/data
   └─ Database container writes schema.sql

2. Normal Operation
   ├─ Backend queries database
   ├─ Data persisted to PV (outside container filesystem)
   └─ Queries return consistent results

3. Pod Restart
   ├─ Database pod crashes or is rescheduled
   ├─ New pod created on same or different node
   ├─ PersistentVolume follows the pod (not tied to node)
   ├─ Pod mounts same PV with all data intact
   └─ Application resumes without data loss

4. Node Failure
   ├─ Node hosting database pod becomes unavailable
   ├─ kubelet reports node as NotReady
   ├─ Deployment Controller evicts database pod
   ├─ New pod scheduled on healthy node
   ├─ PersistentVolume (in shared storage) accessible from new node
   └─ Database comes online with zero data loss

RESULT: Data survives pod and node failures
```

---

## 8. Configuration and Secret Management

### ConfigMap vs Secrets

```yaml
# ConfigMap: Non-sensitive (like docker-compose .env defaults)
kind: ConfigMap
data:
  NODE_ENV: "production"
  DB_HOST: "postgres"
  FRONTEND_URL: "http://feastflow-frontend:3000"
  
# Pod environment
env:
- name: NODE_ENV
  valueFrom:
    configMapKeyRef:
      name: feastflow-config
      key: NODE_ENV
```

```yaml
# Secrets: Sensitive (like docker-compose secrets)
kind: Secret
type: Opaque
data:
  DB_PASSWORD: base64(postgres123)  # Encoded, not encrypted by default
  JWT_SECRET: base64(secret_key)
  
# Pod environment
env:
- name: DB_PASSWORD
  valueFrom:
    secretKeyRef:
      name: feastflow-secrets
      key: DB_PASSWORD
```

**Why this matters for FeastFlow:**
- Don't hardcode passwords in images (breaks security)
- ReplicaSets create multiple pod instances with same config
- Update ConfigMaps → reroll Deployments for new environment

---

## 9. Resilience Patterns in Kubernetes

### 9.1 Liveness Probe (Is pod alive?)
```yaml
livenessProbe:
  httpGet:
    path: /health
    port: 5000
  initialDelaySeconds: 30
  periodSeconds: 10

# If /health fails 3 times → kubelet restarts container
```

**Purpose:** Detect zombie processes (container running but app hung)

### 9.2 Readiness Probe (Can pod serve traffic?)
```yaml
readinessProbe:
  httpGet:
    path: /ready
    port: 5000
  initialDelaySeconds: 5
  periodSeconds: 5

# If /ready fails → kube-proxy removes from service endpoints
# Traffic stops being sent, but pod isn't restarted
```

**Purpose:** Prevent sending traffic to warming-up or degraded pods

### 9.3 Rolling Update
```yaml
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxSurge: 1        # Allow 1 extra pod
    maxUnavailable: 0  # Keep all available during update

# Timeline:
# T+0s:  3 old pods running
# T+10s: Deploy new image
#        - Create pod 4 with new image
#        - Wait for readiness
# T+20s: - Remove pod 1 (old image)
#        - Create pod 5 with new image
# T+30s: - Remove pod 2
#        - Remove pod 3
# T+40s: All 3 pods have new image, zero downtime
```

---

## 10. Summary: Why This Architecture Works

| Challenge | Docker Compose | Kubernetes |
|-----------|----------------|-----------|
| **Pod Failure** | Manual restart | Automatic via ReplicaSet |
| **Node Failure** | App down | Reschedule to healthy node |
| **Scaling** | Manual editing | `kubectl scale` or HPA |
| **Updates** | Downtime | Rolling update (zero downtime) |
| **Service Discovery** | Hardcoded hostnames | DNS-based, automatic |
| **Load Balancing** | External tool | Built-in Service load balancing |
| **Config Management** | Environment files | ConfigMaps/Secrets |
| **Storage** | Host volumes | PersistentVolumes (cluster-aware) |

**For FeastFlow Production:**
- Frontend scales during peak hours (HPA watches CPU)
- Backend automatically heals from failures
- Database data persists across pod/node failures
- Updates happen with zero downtime
- Configuration centralized and versioned
- All infrastructure as code (manifests)

---

## 11. Deploying FeastFlow on Kubernetes

### Step 1: Cluster Setup
```bash
# Create cluster (minikube for local dev)
minikube start

# Verify control plane
kubectl get componentstatuses
# or in newer versions:
kubectl get nodes
```

### Step 2: Apply Manifests
```bash
# Apply in order (namespace first)
kubectl apply -f devops/kubernetes/00-namespace.yaml
kubectl apply -f devops/kubernetes/01-configmap.yaml
kubectl apply -f devops/kubernetes/02-secrets.yaml
kubectl apply -f devops/kubernetes/03-postgres-pvc.yaml
kubectl apply -f devops/kubernetes/04-postgres-deployment.yaml
kubectl apply -f devops/kubernetes/05-postgres-service.yaml
kubectl apply -f devops/kubernetes/06-backend-deployment.yaml
kubectl apply -f devops/kubernetes/07-backend-service.yaml
kubectl apply -f devops/kubernetes/08-frontend-deployment.yaml
kubectl apply -f devops/kubernetes/09-frontend-service.yaml
kubectl apply -f devops/kubernetes/10-ingress.yaml
```

### Step 3: Verify Deployment
```bash
# Check all pods
kubectl get pods -n feastflow

# Check services
kubectl get services -n feastflow

# Check ingress
kubectl get ingress -n feastflow

# Watch rollout
kubectl rollout status deployment/feastflow-backend -n feastflow

# View pod logs
kubectl logs deployment/feastflow-backend -n feastflow -f
```

---

## References & Learning Resources

- [Kubernetes Architecture Documentation](https://kubernetes.io/docs/concepts/architecture/)
- [Kubernetes Components Explained](https://kubernetes.io/docs/concepts/overview/components/)
- [Control Plane-Node Communication](https://kubernetes.io/docs/concepts/architecture/control-plane-node-communication/)
- [FeastFlow Cloud-Native Architecture Document](./cloud-native-architecture.md)
