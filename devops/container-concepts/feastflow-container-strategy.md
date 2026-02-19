# Feast Flow Container Strategy

## Why Feast Flow Uses Containers

Feast Flow is a cloud-native food delivery platform built on **microservices** and **Kubernetes**. Using containers instead of traditional VM-based deployments solves critical challenges:

### 1. Multiple Microservices with Different Requirements

Feast Flow decomposes the application into specialized services:

- **Frontend** (Next.js): Serves the web UI for customers and restaurant owners
- **Pricing Service**: Calculates delivery fees, surge pricing, and discounts
- **Menu Service**: Manages restaurant menus, items, and availability
- **Order Service**: Handles order creation, state transitions, and tracking
- **Restaurant Service**: Manages restaurant profiles, hours, and locations
- **Payment Service**: Processes payments and refunds
- **Notification Service**: Sends emails, SMS, and push notifications
- **Admin Service**: Provides dashboards for audit logs, system health, and promotions

Each service:
- Has different runtime dependencies (Node.js, Python, Go)
- Scales independently based on traffic patterns
- Deploys on its own schedule without affecting others

**Containers enable this diversity.** Each service is packaged with exactly its required runtime and dependencies, isolated from others. On a single Kubernetes node, the frontend (Node 20), pricing (Python 3.11), and payment (Go 1.21) containers coexist without conflicts.

### 2. Zero-Downtime, Canary, and Rolling Updates

Feast Flow promises **99.9% uptime** to restaurants and customers. Every code change must deploy without interrupting active orders or sessions.

Containers enable this through Kubernetes **rolling updates**:

1. New container image is pushed to the registry
2. Kubernetes starts new pods with the updated image
3. New pods pass readiness checks (health endpoints return 200 OK)
4. Traffic gradually shifts from old pods to new pods
5. Old pods are terminated only after new ones are stable

For risky changes (like a new pricing algorithm), Feast Flow uses **canary deployments**:
- Deploy the new `pricing-service:v2.1` to 10% of users
- Monitor error rates, latency, and business metrics
- If successful, roll out to 100%; if not, roll back in seconds

**Without containers:** Updating requires SSH-ing into VMs, stopping processes, deploying new code, and restarting—causing 30–60 seconds of downtime per server.

### 3. Multi-Environment Consistency

Feast Flow runs in four environments:

- **Local development** (developer laptops)
- **CI/CD** (GitHub Actions runners)
- **Staging** (pre-production testing)
- **Production** (live customer traffic)

The container image built from a Pull Request is the **same artifact** that runs in all environments:

```
developer commits → CI builds image → tagged as pricing-service:pr-42
→ deployed to staging → tested by QA → promoted to production
```

**Guarantee:** If it works in staging, it works in production. No "works on my machine" issues because the machine (container) is identical.

With VMs, you'd need to:
- Maintain OS images or provisioning scripts for each environment
- Deal with drift (dev uses Ubuntu 22.04, prod uses 20.04)
- Debug environment-specific bugs caused by different library versions

## Containers in the Feast Flow CI/CD Pipeline

Feast Flow's CI/CD pipeline follows this flow:

```
Source Code (Git) → Build (GitHub Actions) → Container Image → Registry (GHCR) → Deploy (Kubernetes)
```

### Step-by-Step Process

1. **Developer pushes code** to a feature branch
   - Example: Update pricing algorithm in `services/pricing/pricing.py`

2. **GitHub Actions workflow triggers**
   - Checks out code
   - Runs linters and unit tests
   - **Builds a container image** using `Dockerfile`:
     ```
     FROM python:3.11-slim
     COPY requirements.txt .
     RUN pip install -r requirements.txt
     COPY . /app
     CMD ["python", "app.py"]
     ```

3. **Image is tagged and pushed** to GitHub Container Registry:
   - `ghcr.io/feastflow/pricing-service:pr-123`
   - `ghcr.io/feastflow/pricing-service:commit-a1b2c3`

4. **ArgoCD detects new image** (or manual trigger)
   - Updates Kubernetes Deployment manifest to reference new image
   - Kubernetes pulls image from registry

5. **Kubernetes creates new pods**
   - Schedules pods onto nodes with available resources
   - Containers start, application initializes
   - Readiness probe passes (`GET /health` returns 200)

6. **Traffic shifts to new pods**
   - Service (load balancer) routes requests to new pods
   - Old pods are terminated gracefully (finish in-flight requests)

**Result:** Code changes become running containers in 5–10 minutes, without manual SSH or deployment scripts.

## How Containers and Kubernetes Work Together for Zero-Downtime

### Rolling Updates

When Feast Flow deploys a new version of the `order-service`:

- **Before:** 5 pods running `order-service:v1.9`, handling customer orders
- **Kubernetes starts:** 1 new pod with `order-service:v2.0`
- **New pod passes health check:** Kubernetes adds it to the service's endpoint list
- **Kubernetes terminates:** 1 old pod (now 4 old + 1 new)
- **Repeat:** Until all 5 pods are running v2.0

At every moment, at least 4 pods are available to serve traffic. **Zero downtime.**

If v2.0 fails health checks (crashes, returns 500 errors), Kubernetes:
- Stops the rollout automatically
- Keeps old pods running
- Alerts the team via monitoring (Prometheus/Grafana)

### Canary Releases

For high-risk changes (new payment integration, experimental recommendation engine), Feast Flow uses **canary deployments**:

- Deploy `pricing-service:v2.0-canary` alongside `pricing-service:v1.9-stable`
- Configure Istio or Nginx Ingress to send:
  - 10% of traffic → canary version
  - 90% of traffic → stable version
- Monitor metrics: error rate, latency, conversion rate
- If canary is healthy after 30 minutes:
  - Increase to 50%, then 100%
- If canary shows issues:
  - Roll back by deleting canary pods (takes 5 seconds)

**Key enabler:** Containers start/stop in seconds. Running two versions side-by-side is cheap and safe.

### Container Health Checks

Kubernetes uses **liveness** and **readiness** probes to ensure containers are healthy:

- **Liveness probe:** Is the container alive? If it fails 3 times, Kubernetes restarts the container.
  - Example: `GET /health` every 10 seconds
- **Readiness probe:** Is the container ready to serve traffic? If it fails, Kubernetes removes it from the load balancer.
  - Example: `GET /ready` (checks database connection, cache warmup)

This prevents:
- Sending traffic to crashing containers
- Terminating containers prematurely during startup
- Cascading failures from unhealthy pods

**Without containers:** You'd need custom scripts to monitor processes, restart them, and update load balancers—error-prone and slow.

## When Containers Are Appropriate vs When VMs Are Still Used

### Use Containers For:

| **Use Case** | **Why Containers Win** |
|--------------|------------------------|
| **Application services** (frontend, pricing, menu, order) | Fast startup, easy scaling, immutable deployments, zero-downtime updates. |
| **Background workers** (order processing, email queue consumers) | Isolated processes, auto-scaling based on queue depth, can run alongside web services. |
| **Ephemeral CI jobs** (build, test, lint, security scans) | Clean environment per job, parallel execution, no persistent state. |
| **Scheduled tasks** (report generation, data cleanup) | Kubernetes CronJobs run containers on a schedule, no manual cron management. |
| **Multi-tenant workloads** (Feast Flow running for multiple clients) | Each tenant gets isolated containers with resource limits. |

### Use VMs For:

| **Use Case** | **Why VMs Win** |
|--------------|-----------------|
| **Kubernetes worker nodes** | Containers need a host OS with a container runtime (Docker/containerd). VMs provide this foundation. |
| **Managed databases** (PostgreSQL, Redis, Elasticsearch) | Databases need stable storage and predictable I/O. Managed services (AWS RDS, ElastiCache) run on VMs optimized for database workloads. |
| **Stateful legacy applications** | Apps not designed for containers (e.g., uses local filesystem for data, expects fixed IP addresses). |
| **High-security workloads** | VMs provide hardware-level isolation for regulatory compliance (PCI-DSS, HIPAA). |
| **Windows-based applications** | If Feast Flow integrated with a Windows-based inventory system, you'd run it on Windows VMs. |

### Hybrid Approach in Feast Flow

In practice, Feast Flow uses **both**:

- **Containers:** All microservices (8+ services) run as containers on Kubernetes.
- **VMs:** 
  - 3–5 Kubernetes worker nodes (AWS EC2 or Azure VMs)
  - 1 managed PostgreSQL instance (runs on cloud provider's VMs)
  - 1 managed Redis cluster (runs on cloud provider's VMs)

## Real-World Feast Flow Scenarios

### Scenario 1: Rolling Out a New Pricing Algorithm

**Situation:** Feast Flow's data science team built a new machine learning model to calculate delivery fees. It considers traffic, weather, and restaurant popularity. The team wants to test it on 5% of users before full rollout.

**Container-Based Solution:**

1. Package the new model in a container: `pricing-service:v2.1-ml-model`
2. Deploy as a canary:
   - 95% of pricing requests → `pricing-service:v2.0` (existing rule-based algorithm)
   - 5% of requests → `pricing-service:v2.1-ml-model`
3. Monitor for 24 hours:
   - Compare revenue per order (v2.0 vs v2.1)
   - Check error rates and response times
4. If successful: Gradually increase to 10%, 25%, 50%, 100%
5. If problematic: Delete canary pods (5 seconds) or scale to zero

**Why containers excel:**
- **Fast iteration:** Deploy, test, roll back multiple times per day.
- **Isolation:** ML model has heavy dependencies (TensorFlow, NumPy). Old algorithm uses lightweight Python. Both run on the same nodes without conflicts.
- **Low risk:** Only 5% of users affected. Roll back is instant.

**With VMs:** You'd need to:
- Provision separate VMs for the canary (3–10 minutes).
- Configure load balancer rules manually.
- Risk wasting VM costs if the test fails.
- Deal with model dependencies conflicting with existing runtime.

### Scenario 2: Spinning Up a Staging Environment That Mirrors Production

**Situation:** Feast Flow's QA team needs a staging environment identical to production to test a major release: integrated payments via Stripe, new admin dashboard features, and menu recommendation engine.

**Container-Based Solution:**

1. Use the same container images running in production:
   ```
   frontend:v1.5
   pricing-service:v2.0
   menu-service:v1.8
   order-service:v3.1
   payment-service:v2.2
   ```
2. Deploy to a separate Kubernetes namespace or cluster:
   - Apply the same Kubernetes manifests (Deployments, Services, Ingress)
   - Use a different subdomain: `staging.feastflow.com`
3. Connect to staging databases (smaller managed PostgreSQL instances)
4. Run end-to-end tests: UI automation, API tests, load tests
5. If tests pass: Promote images to production by updating production manifests

**Why containers excel:**
- **Consistency:** Staging uses the **exact same container images** as production. No infrastructure drift.
- **Speed:** Spin up staging in 5–10 minutes (vs. 1–2 hours with VM provisioning and configuration management).
- **Cost:** Scale down staging to zero replicas outside business hours. Containers don't consume resources when stopped.

**With VMs:** You'd need to:
- Provision VMs for each service (frontend VM, pricing VM, etc.).
- Install runtimes, dependencies, and application code manually or via Ansible/Chef.
- Deal with "staging works, but production fails" because VMs have subtle differences (OS patches, library versions).
- Pay for idle VMs even when staging isn't used.

### Scenario 3: Handling Two Services with Different Runtime Dependencies

**Situation:** Feast Flow's **notification service** (Python 3.9, uses Celery and Redis) and **payment service** (Node.js 20, uses Express and Stripe SDK) need to run on the same infrastructure.

**Container-Based Solution:**

1. Build separate container images:
   - `notification-service:v1.0` (Python 3.9, Celery, Redis client)
   - `payment-service:v2.0` (Node.js 20, Express, Stripe SDK)
2. Deploy both to Kubernetes:
   - Each service runs in its own pods
   - Kubernetes schedules them onto nodes with available resources
   - Both can run on the same node without dependency conflicts
3. Each service scales independently:
   - Payment service: 5 replicas (high traffic during lunch/dinner)
   - Notification service: 2 replicas (background task, less demand)

**Why containers excel:**
- **Isolation:** Python and Node.js dependencies are packaged separately. No conflicts.
- **Density:** Both services share the same Kubernetes nodes, maximizing resource utilization.
- **Independent scaling:** Payment service spikes during meal times. Notification service is steady. Each scales based on its own metrics.

**With VMs:** You'd need to:
- Run each service on separate VMs to avoid dependency conflicts (Python vs Node.js).
- Overprovision VMs (payment VM needs 4 CPUs at peak but only 1 CPU most of the time).
- Manually update load balancers when adding/removing VMs.
- Pay for idle capacity (notification VM is mostly empty).

---

## Summary

Feast Flow uses containers because they:
- **Enable microservices** with isolated dependencies
- **Support zero-downtime deployments** through rolling updates and canaries
- **Provide fast, consistent environments** from dev to production
- **Scale elastically** to handle unpredictable food delivery traffic
- **Reduce costs** by maximizing resource utilization

VMs still play a role as **Kubernetes nodes** and **managed database servers**, but containers run the application logic. This hybrid approach gives Feast Flow the best of both worlds: the stability of VMs as infrastructure and the agility of containers as the deployment unit.
