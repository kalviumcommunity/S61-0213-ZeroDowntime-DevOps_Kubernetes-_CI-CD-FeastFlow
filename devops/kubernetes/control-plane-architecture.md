# Kubernetes Control Plane Deep Dive

## Overview

The control plane is responsible for making all decisions in the cluster. It consists of multiple components that work together to maintain the desired state of applications. This document breaks down each control plane component and how they interact to manage FeastFlow.

---

## 1. API Server (`kube-apiserver`)

### Role
The API Server is the **single entry point** for all Kubernetes cluster operations. It's the only component that directly accesses etcd, enforcing all access control and validation.

### How It Works

```
User/Tool → API Server → etcd (storage)
  │            │
  ├─ kubectl    ├─ Authentication (who are you?)
  ├─ Helm       ├─ Authorization (what can you do?)
  ├─ REST client├─ Validation (is request valid?)
  │             ├─ Mutation (convert/defaults)
  │             └─ Storage → etcd
```

### FeastFlow Example: Creating a Deployment

```bash
$ kubectl apply -f 06-backend-deployment.yaml
```

**What happens inside API Server:**

```
1. AUTHENTICATION
   └─ Verify credentials (kubeconfig certificate)

2. AUTHORIZATION
   └─ Verify: "User 'admin' can create deployments" → Yes

3. VALIDATION
   ├─ Check YAML syntax
   ├─ Verify all required fields present
   │  └─ name: ✓, replicas: ✓, image: ✓, etc.
   ├─ Check for conflicts (name already exists?)
   └─ Result: Valid ✓

4. MUTATION (Webhooks)
   ├─ Apply defaults (replicas=1 if not specified)
   ├─ Label injection (system labels added)
   └─ Modified spec created

5. PERSISTENCE
   ├─ Store in etcd with key:
   │  /kubernetes.io/deployments/default/feastflow-backend
   ├─ Return 201 Created response
   └─ Event created: "DeploymentCreated"

6. TRIGGER WATCH
   └─ All controllers watching for Deployment changes
      are notified of the new deployment
```

### Key Characteristics

- **Stateless**: Can run multiple replicas (for HA)
- **RESTful**: All operations are HTTP methods (GET, POST, PUT, DELETE)
- **Versioned APIs**: Different API versions coexist (v1, v1beta1, etc.)
- **Single Source of Truth**: Always defers to etcd for state

---

## 2. etcd (Cluster State Database)

### Role
etcd is a **distributed key-value database** that stores all cluster configuration and state. It's the "source of truth" for everything in Kubernetes.

### Architecture

```
┌─────────────────────────────────────────┐
│  etcd Cluster (Highly Available)        │
│  (Usually 3, 5, or 7 nodes)             │
│                                         │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐
│  │etcd Node 1│  │etcd Node 2│  │etcd Node 3│
│  │(leader)  │  │(follower) │  │(follower) │
│  │          │  │           │  │           │
│  │Database  │  │Database   │  │Database   │
│  │(exact    │  │(exact     │  │(exact     │
│  │copy)     │  │copy)      │  │copy)      │
│  └──────────┘  └──────────┘  └──────────┘
│        │               │               │
│        └───────────────┼───────────────┘
│                        │ Raft Consensus
│            (All writes go to leader)
│            (Reads from any node)
```

### Data Structure

etcd stores Kubernetes objects as key-value pairs:

```
/kubernetes.io/
├── namespaces/default
├── deployments/default/feastflow-backend
├── pods/default/feastflow-backend-abc123
├── services/default/feastflow-backend
├── secrets/default/feastflow-secrets
├── configmaps/default/feastflow-config
├── persistentvolumes/postgres-pv
├── persistentvolumeclaims/default/postgres-pvc
└── ... (all cluster state)
```

### Example: Deployment State in etcd

```json
{
  "apiVersion": "apps/v1",
  "kind": "Deployment",
  "metadata": {
    "name": "feastflow-backend",
    "namespace": "default",
    "uid": "550e8400-e29b-41d4-a716-446655440000",
    "generation": 1
  },
  "spec": {
    "replicas": 3,
    "selector": {
      "matchLabels": {"app": "feastflow-backend"}
    },
    "template": {
      "metadata": {
        "labels": {"app": "feastflow-backend"}
      },
      "spec": {
        "containers": [{
          "name": "backend",
          "image": "feastflow-backend:latest",
          "resources": {
            "requests": {"cpu": "100m", "memory": "128Mi"}
          }
        }]
      }
    }
  },
  "status": {
    "replicas": 3,
    "updatedReplicas": 3,
    "readyReplicas": 3,
    "availableReplicas": 3,
    "observedGeneration": 1
  }
}
```

### Consistency Guarantees

**Strongly Consistent:**
- All nodes have exact same data
- Write → all replicas updated (before write completes)
- Read from any node returns latest data

**Example: Backend Pod Restart**
```
Scenario: Admin scales backend from 3 to 5 replicas

$ kubectl scale deployment feastflow-backend --replicas=5

Timeline:
T+0:  API Server writes to etcd leader
T+1:  Leader replicates to follower 1
T+2:  Leader replicates to follower 2
      → Quorum reached (3/3 nodes have data)
      → Write confirmed to client
T+5:  Scheduler sees "need 5 pods, have 3"
      → Creates 2 new pods

Result: Guaranteed consistency across all control plane nodes
```

### Why Multiple etcd Nodes Matter

```
Scenario: etcd node fails

3-node cluster:
├─ Node 1: etcd + API Server (leader)
├─ Node 2: etcd + backup API Server
└─ Node 3: etcd + backup API Server

Node 1 crashes:
└─► etcd followers (2,3) reach quorum
    └─► Node 2 elected as new leader
    └─► Cluster continues operating

1-node etcd (dangerous):
└─► Single point of failure
    └─► etcd crash → cluster completely down
    └─► Entire cluster state lost

Result: Multi-node etcd provides high availability
```

---

## 3. Scheduler (`kube-scheduler`)

### Role
The Scheduler **assigns newly created Pods to Worker Nodes** based on resource requirements, constraints, and policies.

### Scheduling Algorithm

```
┌────────────────────────────────────────────────┐
│  Scheduler: Pod Waiting to be Placed           │
│                                                │
│  1. FILTER (eliminate ineligible nodes)        │
│     ├─ Enough CPU? (100m requested)            │
│     ├─ Enough memory? (128Mi requested)        │
│     ├─ Disk space available?                   │
│     ├─ Node selector matches?                  │
│     ├─ Node taints/tolerations?                │
│     └─ Result: [node-1, node-2, node-3]        │
│                                                │
│  2. SCORE (rank remaining nodes)               │
│     ├─ Pod affinity rules                      │
│     ├─ Node affinity preferences               │
│     ├─ Least CPU used (load balancing)         │
│     ├─ Image locality (minimize pulls)         │
│     └─ Result: [node-1(90), node-3(85), node-2(75)]
│                                                │
│  3. SELECT (pick highest scored)               │
│     └─ node-1 selected (score: 90)             │
│                                                │
│  4. BIND (assign to etcd)                      │
│     └─ pod.spec.nodeName = "node-1"            │
│         stored in etcd → kubelet notified       │
└────────────────────────────────────────────────┘
```

### FeastFlow Example: Scheduling Backend Pod

```yaml
kind: Pod
metadata:
  name: feastflow-backend-abc123
spec:
  containers:
  - name: backend
    image: feastflow-backend:latest
    resources:
      requests:
        cpu: 100m          # Need at least 100m CPU
        memory: 128Mi      # Need at least 128Mi RAM
      limits:
        cpu: 500m
        memory: 512Mi
```

**Scheduler Decision:**

```
Available Worker Nodes:
├─ worker-1: [Free: 400m CPU, 512Mi RAM] → Can fit (✓)
├─ worker-2: [Free: 50m CPU, 512Mi RAM]  → Cannot fit - only 50m (✗)
└─ worker-3: [Free: 600m CPU, 1Gi RAM]   → Can fit (✓)

Scoring:
├─ worker-1: Score 85 (good resources, moderate load)
└─ worker-3: Score 92 (excellent resources, lighter)

Decision: Assign to worker-3 (highest score)

Result:
└─ pod.spec.nodeName = "worker-3"
   kubelet on worker-3 sees assignment
   → Pulls image → Starts container
```

### Affinity Rules (Advanced Scheduling)

**Pod Affinity Example: Keep Frontend and Backend Together**

```yaml
kind: Pod
metadata:
  name: feastflow-backend-abc123
spec:
  affinity:
    podAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
      - labelSelector:
          matchExpressions:
          - key: app
            operator: In
            values:
            - feastflow-frontend
        topologyKey: kubernetes.io/hostname

# Effect: Schedule backend pods on same node as frontend
#         (reduces network latency)
```

**Node Affinity Example: Schedule on GPU Node**

```yaml
affinity:
  nodeAffinity:
    preferredDuringSchedulingIgnoredDuringExecution:
    - weight: 100
      preference:
        matchExpressions:
        - key: gpu
          operator: In
          values:
          - "true"

# Effect: Prefer nodes with GPU label
#         (for ML workloads, if applicable)
```

---

## 4. Controller Manager (`kube-controller-manager`)

### Role
The Controller Manager runs multiple **controllers** that continuously monitor cluster state and take actions to reconcile actual state with desired state.

### Core Controllers for FeastFlow

#### 4.1 Deployment Controller

```
Desired State (in etcd):
  Deployment: feastflow-backend
    replicas: 3
    selector: app=feastflow-backend
    image: feastflow-backend:latest

Reconciliation Loop:
┌────────────────────────────────────────────────┐
│ Deployment Controller (runs continuously)      │
│                                                │
│ 1. Query etcd for all Deployments             │
│    └─► Found: feastflow-backend (replicas=3) │
│                                                │
│ 2. Check current ReplicaSets                  │
│    └─► Found: feastflow-backend-abc123        │
│                                                │
│ 3. Check current Pods with label app=... │
│    ├─ pod-1 (ready, running)                 │
│    ├─ pod-2 (ready, running)                 │
│    ├─ pod-3 (CrashLoopBackOff - bad)         │
│    └─ pod-4 (running, from old ReplicaSet)   │
│                                                │
│ 4. Reconcile                                  │
│    └─ Desired: 3 ready pods                  │
│       Actual: 2 ready pods                   │
│       Action: "Create 1 new pod"              │
│                                                │
│ 5. Execute Action                            │
│    └─ Create Pod: feastflow-backend-xyz789   │
│       Write to etcd                          │
│       Trigger Scheduler                      │
│                                                │
│ 6. Loop back (every few seconds)              │
│    └─ Verify desired == actual                │
└────────────────────────────────────────────────┘
```

#### 4.2 ReplicaSet Controller

```
ReplicaSet Responsibilities:
├─ Desired: 3 pod replicas
├─ Watch pod status continuously
└─ Reconciliation actions:

Scenario 1: Pod Crashes
├─ Desired: 3 pods (pod-1, pod-2, pod-3)
├─ Actual: 2 pods (pod-1, pod-2) - pod-3 crashed
├─ Action: Create pod-4 with same spec
└─ Result: Back to 3 running pods

Scenario 2: Node Failure
├─ Desired: 3 pods total
├─ Node-1 crashes (has pod-1, pod-2)
├─ Pods on Node-1 → Evicted (terminating)
├─ ReplicaSet sees: Only 1 actual pod (pod-3)
├─ Action: Create pod-4, pod-5 to reach 3
├─ Scheduler places on healthy nodes
└─ Result: 3 pods distributed across nodes

Scenario 3: Manual Scale Up
├─ User: kubectl scale replica set feastflow-backend --replicas=5
├─ Desired: 5 pods
├─ Actual: 3 pods
├─ Action: Create pod-4, pod-5
└─ Result: 5 running pods
```

#### 4.3 Service Controller

```
When Service Created:
kind: Service
metadata:
  name: feastflow-backend
spec:
  type: ClusterIP
  ports:
  - port: 5000
    targetPort: 5000
  selector:
    app: feastflow-backend

Service Controller Actions:
└─ Allocate Service IP: 10.96.0.100
   Create Endpoints object listing pod IPs:
   {
     "name": "feastflow-backend",
     "addresses": [
       {"ip": "10.244.0.5", "targetRef": {"name": "pod-1"}},
       {"ip": "10.244.0.6", "targetRef": {"name": "pod-2"}},
       {"ip": "10.244.0.7", "targetRef": {"name": "pod-3"}}
     ]
   }

Continuous Monitoring:
├─ Pod added (new replica)
│  └─ Add IP to Endpoints
├─ Pod removed (crash, node failure)
│  └─ Remove IP from Endpoints
└─ Pod not ready (liveness probe failing)
   └─ Remove from Endpoints (but pod still exists)
```

#### 4.4 StatefulSet Controller

```
Why StatefulSet for Database (not simple Deployment)?

Deployment Behavior:
├─ Pods named: feastflow-backend-abc123, feastflow-backend-xyz456, ...
├─ Replicas scale up/down dynamically
├─ Pod identity not important
└─ Problem: Database needs stable identity

StatefulSet Behavior:
├─ Pods named: postgres-0, postgres-1, postgres-2, ...
├─ Ordered deployment/termination (0, then 1, then 2)
├─ Each pod gets persistent identity
├─ Each pod gets persistent volume (postgres-0 → vol-0)
└─ Solution: Database pod always knows its volume

Example Scenario:
┌─────────────────────────────────────────┐
│ StatefulSet: postgres (replicas=1)      │
└─────────────────────────────────────────┘

Initial Creation:
└─ Create postgres-0 pod
   Mount PersistentVolume: postgres-pvc-0
   Start PostgreSQL server

Node Failure:
└─ Node-1 hosting postgres-0 crashes
   └─ postgres-0 pod evicted
   └─ New postgres-0 pod created on node-2
   └─ Same volume mounted (from shared storage)
   └─ Database online with all data

Why This Works:
├─ Pod name stays: postgres-0
├─ Volume stays: postgres-pvc-0
├─ Backend always knows DB is at postgres-0
└─ Connection preserved or automatically retried
```

#### 4.5 Node Controller

```
Node Controller Monitors All Nodes:

Node Status States:
├─ Ready: Node is healthy, accepting pods
├─ NotReady: Node offline or unresponsive
├─ SchedulingDisabled: Node cordoned (manual)
└─ DiskPressure: Storage low

FeastFlow Scenario:
┌────────────────────────────────────────┐
│ Node-1 Network Partition (node crashes)│
└────────────────────────────────────────┘

Timeline:
T+0:  Node-1 becomes unreachable
      └─ kubelet can't heartbeat to API Server

T+40s (nodeStatusUpdateFrequency):
      └─ Node Controller: "No heartbeat from node-1, mark NotReady"

T+5m (podEvictionTimeout):
      └─ Node Controller: "Node has been NotReady for 5 min, evict pods"
      └─ All pods on node-1 evicted
      └─ Deployment Controller sees missing pods
      └─ New pods scheduled on healthy nodes

Result:
├─ User doesn't need to manually fix
├─ Cluster automatically heals
└─ FeastFlow keeps running on other nodes
```

---

## 5. Control Plane-to-Worker Communication

### How Control Plane Commands Reach Kubelet

```
┌────────────────────────────────────────────────┐
│ API Server (Control Plane)                     │
│                                                │
│ kubectl apply -f deployment.yaml               │
│ → Stored in etcd                              │
│ → Scheduler assigns pods                      │
│ → Controller creates ReplicaSets/Pods          │
└────────────────────────────────────────────────┘
                    │
                    ▼ (API Push)
          How does pod spec get
          to the worker node?
                    │
                    ▼
┌────────────────────────────────────────────────┐
│ Kubelet (Worker Node)                          │
│                                                │
│ Watch mechanism:                               │
│ └─ kubelet WATCHES api-server                  │
│    "Give me pod specs for node-1"              │
│    └─ kubelet: "I'm watching pods assigned"    │
│       └─ API Server sends spec when created    │
│                                                │
│ Or: Polling                                   │
│ └─ Every 20s kubelet queries:                  │
│    "Any pods assigned to node-1?"              │
│    └─ API Server: "Yes, pod-1, pod-2, pod-3" │
└────────────────────────────────────────────────┘
                    │
                    ▼ Kubelet Executes
          1. Pull image (if not cached)
          2. Create container via runtime
          3. Monitor health (probes)
          4. Report status back to API Server
```

---

## 6. High Availability Control Plane

### Single Node (Development)

```
┌─────────────────────────────┐
│ Master Node                 │
├─────────────────────────────┤
│ - API Server                │
│ - etcd                      │
│ - Scheduler                 │
│ - Controller Manager        │
│ - CoreDNS                   │
└─────────────────────────────┘

Problem: Single Point of Failure
└─ Master crashes → Cluster down
   └─ Existing pods keep running
   └─ But can't deploy/scale/update
```

### Multi-Node (Production)

```
┌─────────────────────────────┐
│ ┌─ Master Node 1 ──┐        │
│ │ API Server        │        │
│ │ Scheduler         │        │
│ │ Ctrl Manager      │        │
│ └───────────────────┘        │
│ ┌─ Master Node 2 ──┐        │
│ │ API Server        │        │
│ │ Scheduler         │        │
│ │ Ctrl Manager      │        │
│ └───────────────────┘        │
│ ┌─ Master Node 3 ──┐        │
│ │ API Server        │        │
│ │ Scheduler         │        │
│ │ Ctrl Manager      │        │
│ └───────────────────┘        │
│ ┌─ etcd Cluster (3,5,7 nodes)
│   - Distributed consensus     │
│   - Each master runs etcd     │
│   - Quorum: ⌈n/2⌉ nodess      │
│ └───────────────────────────┘ │
└─────────────────────────────┘

Load Balancer: 10.96.0.1 (virtual IP)
└─ Routes API requests to healthy masters

Resilience:
├─ Master-1 crashes → Master-2,3 handling requests
├─ etcd-1 crashes → etcd-2,3 have full data (quorum)
├─ Master-2 + etcd-2 crash → Still functional (3 is enough)
└─ Master-1,2,3 crash → Cluster down (no control plane)
```

---

## 7. Control Plane Decisions for FeastFlow

### Decision 1: Pod Eviction (Graceful Shutdown)

```
Scenario: Rolling update of backend pods

$ kubectl rolling-restart deployment/feastflow-backend

Timeline:
T+0:   Eviction signal sent to pod-1
       └─ terminationGracePeriodSeconds: 30
          Pod receives SIGTERM signal

T+0-25s: Pod shutdown sequence
       ├─ App responds to SIGTERM
       ├─ Close client connections gracefully
       ├─ Stop accepting new requests
       ├─ Wait for in-flight requests to complete
       └─ Exit with code 0

T+25s: Pod clean exit detected
       └─ Container removed

T+30s: If still running, SIGKILL (force kill)

New pod created:
└─ New pod-4 with new image starts
   └─ Readiness probe fails initially
   └─ Not added to service endpoints yet
   └─ Waits for /ready endpoint to respond
   └─ Eventually becomes ready
   └─ Added to service endpoints
   └─ Starts receiving traffic

Result: Zero downtime (old pod drains, new pod warm up)
```

### Decision 2: Resource-Based Eviction

```
Scenario: Node running out of memory

Node Memory Status:
├─ Total: 8 Gi
├─ Used: 7.5 Gi
├─ Available: 0.5 Gi
└─ Threshold: 1 Gi (memory pressure)

Kubelet Eviction Decision:
┌──────────────────────────────────┐
│ Node: MEMORY PRESSURE            │
│ Available < Threshold            │
│                                  │
│ Evict pods (in priority order):  │
│ 1. Pods using more than request  │
│ 2. Worst offenders first         │
│ 3. Try to free at least 1 Gi     │
└──────────────────────────────────┘

FeastFlow Example:
├─ feastflow-backend: Requested 128Mi, using 200Mi
│  └─ EVICT (over limit)
├─ feastflow-frontend: Requested 64Mi, using 64Mi
│  └─ Keep (within limit)

Result:
├─ Backend pod evicted
├─ Deployment Controller sees missing pod
├─ New backend pod created on other nodes
└─ Pressure relieved
```

---

## 8. Control Plane Observability

### Checking Control Plane Health

```bash
# View control plane components
kubectl get componentstatuses
# or (newer k8s)
kubectl get nodes
kubectl get nodes -o wide

# Check API Server logs
kubectl logs -n kube-system -l component=kube-apiserver

# Check Scheduler logs
kubectl logs -n kube-system -l component=kube-scheduler

# Check Controller Manager logs
kubectl logs -n kube-system -l component=kube-controller-manager

# Check etcd (if accessible)
kubectl logs -n kube-system -l component=etcd
```

### Key Metrics

```
API Server:
├─ Request latency (should be < 100ms p99)
├─ Request rate (requests/sec)
└─ Error rate (validation, authorization failures)

Scheduler:
├─ Scheduling latency (pod creation to node assignment)
├─ Pod scheduling rate
└─ Failed scheduling attempts

Controller Manager:
├─ Reconciliation latency (how fast reacts to changes)
├─ Work queue depth (backlog of changes)
└─ Error rate in controllers
```

---

## 9. Control Plane Failure Scenarios

### Scenario 1: API Server Overloaded

```
Problem: Too many API requests
├─ Pods frequently talking to API Server
├─ Large updates/watches
└─ API Server CPU maxed

Impact on FeastFlow:
├─ kubectl commands slow
├─ Pod evictions slow to process
├─ Scheduler slower to assign pods
└─ Controllers react slower to state changes

Solution:
├─ Upgrade API Server (more CPU/memory)
├─ Scale API Servers (multiple replicas)
├─ Implement rate limiting
└─ Optimize client code (batch operations)
```

### Scenario 2: etcd Corruption

```
Problem: etcd data corruption
├─ Hardware failure
├─ Software bug
└─ Accidental deletion

Impact:
└─ Entire cluster state corrupted
   └─ Deployments specs lost
   └─ Service configs lost
   └─ Secret data lost

Prevention:
├─ Regular backups (etcd snapshots daily)
├─ Multi-node etcd (detects corruption)
└─ Monitoring (verify etcd health)

Recovery:
├─ Restore from backup
├─ Rebuild cluster if necessary
└─ Data loss if backup is old
```

---

## Summary: Control Plane Responsibilities

| Component | Job | FeastFlow Impact |
|-----------|-----|-----------------|
| **API Server** | Accept/validate operations | Every kubectl command |
| **etcd** | Store state | Deployment specs, pod configs |
| **Scheduler** | Assign pods to nodes | Where frontend/backend/DB run |
| **Deployment Controller** | Maintain replica count | 3 backend pods always running |
| **Service Controller** | Manage service endpoints | Frontend finds backend via DNS |
| **StatefulSet Controller** | Maintain database identity | Database pod stable across restarts |

The control plane ensures FeastFlow stays in the desired state, automatically healing failures and responding to user commands.
