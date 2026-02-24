# Understanding Kubernetes Pods and ReplicaSets

## 📚 Core Concepts

### What is a Pod?

A **Pod** is the smallest deployable unit in Kubernetes. Think of it as a wrapper around one or more containers.

**Key Characteristics:**
- **Atomic Unit**: Can't be split across nodes - all containers in a pod run on the same node
- **Shared Resources**: Containers in a pod share network namespace (IP address) and can share volumes
- **Ephemeral**: Pods are designed to be disposable and replaceable
- **Single Instance**: A Pod represents a single instance of your applicationIf you manually create a Pod and it dies, it's gone forever (no automatic restart)

**Real-World Analogy:**
A Pod is like a **single server instance**. If that server crashes and you haven't set up auto-scaling or redundancy, your service goes down.

### What is a ReplicaSet?

A **ReplicaSet** ensures that a specified number of identical Pod replicas are running at all times.

**Key Characteristics:**
- **Desired State Management**: You declare "I want 3 replicas" and Kubernetes maintains exactly 3
- **Self-Healing**: If a Pod dies, the ReplicaSet automatically creates a new one
- **High Availability**: Multiple replicas mean your service stays up even if some pods fail
- **Label-Based Selection**: Uses labels to identify which Pods it manages

**Real-World Analogy:**
A ReplicaSet is like an **auto-scaling group** with a health monitor. If any server crashes, it automatically spins up a replacement to maintain your desired count.

---

## 🎯 Why ReplicaSets Instead of Individual Pods?

| Aspect | Individual Pod | ReplicaSet |
|--------|---------------|------------|
| **Failure Recovery** | Pod dies → Application down ❌ | Pod dies → New pod auto-created ✅ |
| **Scalability** | Manual creation of each pod | Declare replicas: scale instantly |
| **Load Distribution** | Single instance → bottleneck | Multiple replicas → distributed load |
| **Rolling Updates** | Manual replacement, downtime | Managed updates (with Deployments) |
| **High Availability** | Single point of failure | Redundancy across replicas |

**Bottom Line:** You should almost never create standalone Pods in production. Use ReplicaSets (or better yet, Deployments which manage ReplicaSets).

---

## 📋 YAML Structure Explained

### Pod YAML Structure

```yaml
apiVersion: v1              # API version for Pods
kind: Pod                   # Object type
metadata:
  name: my-app-pod          # Unique name
  namespace: default
  labels:                   # Key-value pairs for organization
    app: my-app
    tier: backend
spec:                       # Desired state definition
  containers:               # List of containers in this pod
  - name: main-container
    image: my-app:v1.0
    ports:
    - containerPort: 8080
    resources:              # Resource requests and limits
      requests:
        memory: "128Mi"
        cpu: "100m"
      limits:
        memory: "256Mi"
        cpu: "500m"
```

### ReplicaSet YAML Structure

```yaml
apiVersion: apps/v1         # API version for ReplicaSets
kind: ReplicaSet
metadata:
  name: my-app-replicaset
spec:
  replicas: 3               # DESIRED STATE: 3 pods
  selector:                 # How to find pods to manage
    matchLabels:
      app: my-app
      tier: backend
  template:                 # Pod template - blueprint for replicas
    metadata:
      labels:               # Must match selector labels
        app: my-app
        tier: backend
    spec:                   # Same as Pod spec
      containers:
      - name: main-container
        image: my-app:v1.0
        # ... rest of container spec
```

**Critical Points:**
1. **selector.matchLabels** must match **template.metadata.labels**
2. The **template** section is essentially a Pod specification
3. **replicas** defines the desired state - Kubernetes continuously works to maintain this

---

## 🚀 Demo Instructions

### Prerequisites

1. **Kubernetes cluster running** (kind, minikube, or other)
2. **Namespace created**:
   ```bash
   kubectl apply -f ../00-namespace.yaml
   ```

3. **ConfigMap and Secrets created**:
   ```bash
   kubectl apply -f ../01-configmap.yaml
   kubectl apply -f ../02-secrets.yaml
   ```

4. **Docker images built and loaded**:
   ```bash
   # Build images (from project root)
   cd backend
   docker build -t feastflow-backend:latest .
   cd ../frontend/app
   docker build -t feastflow-frontend:latest .
   
   # Load into kind cluster (if using kind)
   kind load docker-image feastflow-backend:latest
   kind load docker-image feastflow-frontend:latest
   ```

---

### Step 1: Deploy Standalone Pods

```bash
# Apply the pod configuration
kubectl apply -f 01-simple-pod.yaml

# Check pods
kubectl get pods -n feastflow

# Describe a pod to see details
kubectl describe pod feastflow-backend-pod -n feastflow

# Check logs
kubectl logs feastflow-backend-pod -n feastflow

# Get more detailed information
kubectl get pods -n feastflow -o wide
```

**Expected Output:**
```
NAME                      READY   STATUS    RESTARTS   AGE
feastflow-backend-pod     1/1     Running   0          10s
feastflow-frontend-pod    1/1     Running   0          10s
```

### Step 2: Test Pod Self-Healing (or lack thereof)

```bash
# Delete a standalone pod
kubectl delete pod feastflow-backend-pod -n feastflow

# Check pods again
kubectl get pods -n feastflow

# Notice: The pod is gone and NOT recreated!
# This demonstrates why standalone pods aren't suitable for production
```

**Key Observation:** The pod is permanently deleted. No automatic recovery.

---

### Step 3: Deploy ReplicaSets

```bash
# Clean up standalone pods first
kubectl delete -f 01-simple-pod.yaml

# Apply ReplicaSet configuration
kubectl apply -f 02-replicaset.yaml

# Check ReplicaSets
kubectl get replicasets -n feastflow
kubectl get rs -n feastflow  # Short form

# Check pods created by ReplicaSet
kubectl get pods -n feastflow --show-labels

# Describe ReplicaSet to see events
kubectl describe rs feastflow-backend-replicaset -n feastflow
```

**Expected Output:**
```
NAME                            DESIRED   CURRENT   READY   AGE
feastflow-backend-replicaset    3         3         3       20s
feastflow-frontend-replicaset   2         2         2       20s
```

```
NAME                                  READY   STATUS    LABELS
feastflow-backend-replicaset-a1b2c    1/1     Running   app=feastflow,component=backend,managed-by=replicaset
feastflow-backend-replicaset-d3e4f    1/1     Running   app=feastflow,component=backend,managed-by=replicaset
feastflow-backend-replicaset-g5h6i    1/1     Running   app=feastflow,component=backend,managed-by=replicaset
feastflow-frontend-replicaset-j7k8l   1/1     Running   app=feastflow,component=frontend,managed-by=replicaset
feastflow-frontend-replicaset-m9n0o   1/1     Running   app=feastflow,component=frontend,managed-by=replicaset
```

---

### Step 4: Test ReplicaSet Self-Healing

```bash
# Get current pods
kubectl get pods -n feastflow

# Delete one pod (copy actual pod name from above)
kubectl delete pod feastflow-backend-replicaset-XXXXX -n feastflow

# Immediately check pods again
kubectl get pods -n feastflow -w  # -w watches for changes

# Watch as Kubernetes automatically creates a new pod!
```

**Key Observation:** 
- The deleted pod disappears
- Almost immediately, a NEW pod is created
- The total count returns to the desired state (3 backend replicas)
- This is **self-healing** in action!

---

### Step 5: Scale ReplicaSets

```bash
# Scale up using kubectl
kubectl scale replicaset feastflow-backend-replicaset --replicas=5 -n feastflow

# Watch pods being created
kubectl get pods -n feastflow -w

# Check ReplicaSet status
kubectl get rs -n feastflow

# Scale down
kubectl scale rs feastflow-backend-replicaset --replicas=2 -n feastflow

# Watch pods being terminated
kubectl get pods -n feastflow -w
```

**Alternative: Edit YAML directly**
```bash
# Edit replicas in 02-replicaset.yaml (change replicas: 3 to replicas: 5)
# Then apply again
kubectl apply -f 02-replicaset.yaml

# Kubernetes will update to match the desired state
```

---

### Step 6: Understand Label Selectors

```bash
# See all pods with specific labels
kubectl get pods -n feastflow -l component=backend
kubectl get pods -n feastflow -l managed-by=replicaset

# Try to manually create a pod with the same labels
kubectl run manual-pod --image=feastflow-backend:latest -n feastflow \
  --labels="app=feastflow,component=backend,managed-by=replicaset"

# Watch what happens!
kubectl get pods -n feastflow
```

**What happens:**
The ReplicaSet will see that there are MORE pods than the desired count (because you manually added one) and will **terminate the excess pod** to maintain the desired state!

This demonstrates how ReplicaSets use labels to identify their managed pods.

---

## 🎥 Video Demo Checklist

For your video demo, make sure to show and explain:

### Part 1: Pods (5-7 minutes)
- [ ] **Show the Pod YAML** - explain key sections:
  - `apiVersion: v1` and `kind: Pod`
  - `metadata` (name, labels)
  - `spec.containers` (image, ports, resources)
  - Health probes (liveness, readiness)

- [ ] **Apply the Pod configuration**
  ```bash
  kubectl apply -f 01-simple-pod.yaml
  ```

- [ ] **Show running pods**
  ```bash
  kubectl get pods -n feastflow -o wide
  ```

- [ ] **Explain what a Pod represents:**
  - Smallest deployable unit
  - Wraps one or more containers
  - Shares network and storage
  - Single instance (not self-healing on its own)

- [ ] **Demonstrate Pod limitations:**
  - Delete a pod: `kubectl delete pod feastflow-backend-pod -n feastflow`
  - Show it doesn't come back
  - Explain why this isn't suitable for production

### Part 2: ReplicaSets (8-10 minutes)
- [ ] **Show the ReplicaSet YAML** - explain key sections:
  - `apiVersion: apps/v1` and `kind: ReplicaSet`
  - `spec.replicas` - the desired state
  - `spec.selector.matchLabels` - how it finds pods
  - `spec.template` - the pod blueprint

- [ ] **Explain selector and template relationship:**
  - Selector labels MUST match template labels
  - This is how ReplicaSet knows which pods it manages

- [ ] **Apply the ReplicaSet configuration**
  ```bash
  kubectl apply -f 02-replicaset.yaml
  ```

- [ ] **Show created pods**
  ```bash
  kubectl get rs -n feastflow
  kubectl get pods -n feastflow --show-labels
  ```

- [ ] **Explain why ReplicaSets exist:**
  - Self-healing: automatic pod replacement
  - High availability: multiple replicas
  - Scalability: easy to add/remove replicas
  - Desired state management

- [ ] **Demonstrate self-healing:**
  - Delete a pod: `kubectl delete pod <pod-name> -n feastflow`
  - Show immediate recreation
  - Explain: "Kubernetes constantly monitors and maintains desired state"

- [ ] **Demonstrate scaling:**
  ```bash
  kubectl scale rs feastflow-backend-replicaset --replicas=5 -n feastflow
  kubectl get pods -n feastflow
  kubectl scale rs feastflow-backend-replicaset --replicas=2 -n feastflow
  ```

- [ ] **Show YAML defines desired state:**
  - "The YAML tells Kubernetes what we want (desired state)"
  - "Kubernetes constantly works to match actual state to desired state"
  - "If actual state drifts (pod dies), Kubernetes corrects it"

### Part 3: Compare and Contrast (3-5 minutes)
- [ ] **Create comparison table or diagram showing:**
  - Pod vs ReplicaSet
  - When to use each
  - How ReplicaSets solve Pod limitations

- [ ] **Walk through your PR changes**
  - Show files added: `01-simple-pod.yaml`, `02-replicaset.yaml`, `README.md`
  - Explain the structure of your contribution
  - Show any documentation you added

### Part 4: Answer Scenario Question
- [ ] **Answer the scenario-based question from the assignment**
  - Speak clearly and demonstrate understanding
  - Use your running cluster as examples if helpful

---

## 🎓 Key Concepts to Emphasize

### Desired State vs Actual State

**Kubernetes operates on a reconciliation loop:**

1. **You declare desired state** in YAML: "I want 3 backend pods"
2. **Kubernetes reads the desired state** from the YAML
3. **Controllers continuously monitor actual state** (how many pods actually running?)
4. **If actual ≠ desired**, controllers take action to reconcile
   - If actual < desired: Create new pods
   - If actual > desired: Delete excess pods
   - If pod unhealthy: Replace it5. **Repeat forever** (continuous reconciliation)

This is called the **declarative model**: you declare what you want, not how to achieve it.

### Label Selectors

Labels are key-value pairs attached to objects. ReplicaSets use labels to:
- **Identify which pods they manage**
- **Loose coupling**: ReplicaSet doesn't "own" pods, it just manages any pod with matching labels
- **Flexible**: You can manually add labels to existing pods to bring them under management

**Example:**
```yaml
selector:
  matchLabels:
    app: feastflow
    component: backend
```
This ReplicaSet will manage ANY pod (new or existing) that has both labels.

---

## 🧹 Cleanup

```bash
# Delete ReplicaSets (this will also delete managed pods)
kubectl delete -f 02-replicaset.yaml

# Delete standalone pods (if any remain)
kubectl delete -f 01-simple-pod.yaml

# Verify cleanup
kubectl get pods -n feastflow
kubectl get rs -n feastflow
```

---

## ❓ Common Questions & Scenarios

### Q: Why aren't we using Deployments?
**A:** Deployments are higher-level abstractions that manage ReplicaSets. For this assignment, you need to understand the building blocks first:
- Pods (Level 0: basic unit)
- ReplicaSets (Level 1: replica management)
- Deployments (Level 2: adds rolling updates, rollback)

You'll learn Deployments next after mastering ReplicaSets.

### Q: Can a pod have multiple containers?
**A:** Yes! This is called a "sidecar pattern". Common use cases:
- Main app container + logging sidecar
- Main app + auth proxy
- Main app + metrics collector

### Q: What happens if I delete a ReplicaSet?
**A:** All pods managed by that ReplicaSet are also deleted. Use `kubectl delete rs <name> --cascade=orphan` to keep the pods.

### Q: Can two ReplicaSets manage the same pods?
**A:** Technically possible but dangerous! If both use the same label selectors, they'll fight over pod count. Don't do this in practice.

### Q: Why do pods get random names like `backend-xyz12`?
**A:** ReplicaSets generate unique names for each pod using the ReplicaSet name + random suffix. This ensures uniqueness.

---

## 📝 PR Description Template

Use this template for your Pull Request:

```markdown
## Sprint #3: Understanding Kubernetes Pods and ReplicaSets

### Overview
This PR introduces Kubernetes Pod and ReplicaSet configurations for the FeastFlow application, demonstrating core Kubernetes concepts of workload management.

### What Was Created

#### 1. Standalone Pods (`01-simple-pod.yaml`)
- **feastflow-backend-pod**: Single instance of backend API
- **feastflow-frontend-pod**: Single instance of Next.js frontend
- Demonstrates the basic Pod structure and limitations

#### 2. ReplicaSets (`02-replicaset.yaml`)
- **feastflow-backend-replicaset**: Manages 3 replicas of backend
- **feastflow-frontend-replicaset**: Manages 2 replicas of frontend
- Provides self-healing and high availability

#### 3. Documentation (`README.md`)
- Comprehensive guide explaining Pods vs ReplicaSets
- Step-by-step demo instructions
- YAML structure breakdown
- Key concepts and best practices

### Key Concepts Demonstrated

**Pods:**
- Smallest deployable unit in Kubernetes
- Wraps containers with shared networking and storage
- Ephemeral and not self-healing when created standalone

**ReplicaSets:**
- Ensures desired number of pod replicas
- Provides self-healing through continuous reconciliation
- Uses label selectors to identify managed pods
- Maintains high availability through replica management

**Desired State Management:**
- YAML defines desired state (e.g., "replicas: 3")
- Kubernetes controllers continuously reconcile actual state to match desired state
- If pods die, ReplicaSet automatically creates replacements

### How to Test

```bash
# Apply configurations
kubectl apply -f 01-simple-pod.yaml
kubectl apply -f 02-replicaset.yaml

# Verify pods running
kubectl get pods -n feastflow

# Test self-healing
kubectl delete pod <pod-name> -n feastflow
kubectl get pods -n feastflow  # Watch new pod appear

# Test scaling
kubectl scale rs feastflow-backend-replicaset --replicas=5 -n feastflow
```

### Files Changed
- ✅ `devops/kubernetes/pods-and-replicasets/01-simple-pod.yaml` (new)
- ✅ `devops/kubernetes/pods-and-replicasets/02-replicaset.yaml` (new)
- ✅ `devops/kubernetes/pods-and-replicasets/README.md` (new)
- ✅ `devops/kubernetes/pods-and-replicasets/demo-commands.sh` (new)

### Video Demo
[Insert your video link here]

The video demonstrates:
- Pod YAML structure and deployment
- Pod limitations (no self-healing)
- ReplicaSet YAML structure and deployment
- Self-healing demonstration
- Scaling demonstration
- How YAML defines desired state
- PR walkthrough

### Learning Outcomes
- ✅ Understand what a Pod is and why it's the smallest unit
- ✅ Understand why ReplicaSets are needed for production workloads
- ✅ Can explain how YAML defines desired state
- ✅ Can demonstrate Kubernetes managing pods automatically
```

---

## 🎯 Success Criteria

You've completed this assignment successfully when you can:

1. ✅ **Create and apply Pod YAML configurations**
2. ✅ **Create and apply ReplicaSet YAML configurations**
3. ✅ **Explain the difference between Pods and ReplicaSets**
4. ✅ **Demonstrate self-healing behavior**
5. ✅ **Explain how YAML defines desired state**
6. ✅ **Show Kubernetes maintaining replica count automatically**
7. ✅ **Submit a PR with proper documentation**
8. ✅ **Record a comprehensive video demo**

---

## 📚 Additional Resources

- [Kubernetes Pods Documentation](https://kubernetes.io/docs/concepts/workloads/pods/)
- [Kubernetes ReplicaSets Documentation](https://kubernetes.io/docs/concepts/workloads/controllers/replicaset/)
- [Understanding Kubernetes Objects](https://kubernetes.io/docs/concepts/overview/working-with-objects/)
- [Declarative vs Imperative Management](https://kubernetes.io/docs/concepts/overview/working-with-objects/object-management/)

---

**Good luck with your demo! 🚀**
