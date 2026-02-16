Project Overview

This project solves the problem of service disruption during deployments.
Previously, any backend update required a full system restart, causing 15-minute downtime during peak dinner hours.

Our solution enables:

 Zero-downtime deployments

 Real-time pricing updates

 Real-time menu updates

 Canary / Rolling deployments

 Production-like staging environment

 Horizontal scalability across cities

Architecture
High-Level Components

API Gateway

Microservices (Pricing, Menu, Order, Admin)

Customer UI

Admin Dashboard UI

Kubernetes Cluster

CI/CD Pipeline

Redis Cache

Message Broker

Monitoring Stack

Tech Stack

Backend

Node.js / Spring Boot (Microservices)

REST APIs

Event-driven architecture

Frontend

React / Next.js (Customer UI)

React Admin Dashboard

DevOps

Kubernetes

Docker

GitHub Actions

Argo CD

Data & Messaging

PostgreSQL / MongoDB

Redis

Apache Kafka

Monitoring

Prometheus

Grafana

Deployment Strategy

Rolling Updates (default)

Canary Deployment for pricing updates

Automatic rollback on failure

Separate staging and production clusters

Real-Time Updates Flow

Admin updates pricing/menu via dashboard

Event published to Kafka

Pricing/Menu service consumes event

Redis cache updated instantly

Customer UI reflects changes in real-time

No restart required. No downtime.

Project Structure
/frontend
  /customer-ui
  /admin-ui

/backend
  /pricing-service
  /menu-service
  /order-service
  /admin-service

/devops
  /k8s-manifests
  /helm-charts
  /ci-cd

CI/CD Artifact Flow

Source → Image → Registry → Cluster

=>Objective

To understand how a Git commit becomes a deployable artifact and runs inside a Kubernetes cluster using a CI/CD pipeline.

 Artifact Flow Overview

In modern DevOps, code is not deployed directly.
Each change becomes an immutable artifact that moves through controlled stages:

Source (Git Commit)
        ↓
CI Pipeline
        ↓
Docker Image
        ↓
Container Registry
        ↓
Kubernetes Cluster

1️ Source (Git)

Developer pushes code or merges a Pull Request

Each commit has a unique commit hash

The commit triggers the CI pipeline

The commit identifies exactly what version of code is being built.

2️ CI Pipeline

The CI pipeline (e.g., GitHub Actions):

Checks out code

Runs tests

Builds a Docker image

Tags the image

Pushes it to a registry

CI produces a Docker image artifact — it does not deploy source code directly.

3️ Docker Image (Immutable Artifact)

A Docker image contains:

Application code

Dependencies

Runtime

Configuration

Images are immutable.
Every new commit creates a new image.

Example:

app:commit-a1b2
app:commit-c3d4

4️ Image Tags and Digests

Image Tags
Human-readable labels (latest, v1.2.0, commit-xyz).

Image Digests
Cryptographic identifiers (sha256:...) that guarantee the exact image version.

5️ Container Registry

Images are stored in a registry (Docker Hub, GitHub Container Registry, AWS ECR).

Registries provide:

Version storage

Traceability (image → commit)

Secure access

Kubernetes pulls images from the registry.

6️ Kubernetes Deployment

Kubernetes runs the image in the cluster.

Deployment defines:

Image name

Tag/version

Replicas

Rolling update strategy

When the image changes, Kubernetes performs a rolling update without downtime.

 Rollbacks

If a release fails:

Identify the previous stable image

Update deployment to that image

Kubernetes rolls back automatically

Rollbacks are safe because:

Images are immutable

Registry stores history

Deployments reference exact versions

[Learning Concept-2] Kubernetes Application Lifecycle & Deployment Mechanics

In this lesson, you’ll explore how Kubernetes manages the full lifecycle of an application - from creation and scheduling to updates, failures, and recovery.

You’ll move beyond “Kubernetes runs containers” to understanding what actually happens inside the cluster when you deploy, scale, update, or break an application.

By the end of this lesson, you’ll be able to reason about pod behavior, understand rollout outcomes, and diagnose common failure states - critical skills for operating real production systems.

Objective
To help students understand how Kubernetes creates, manages, updates, and recovers workloads.

Students should be able to:

Explain pod creation and scheduling
Describe the role of ReplicaSets during deployments
Understand how health probes and resource limits affect pod behavior
Identify common failure states and what they indicate during deployments
Here’s What You Need to Understand
1. The Kubernetes Application Lifecycle (Big Picture)
When you deploy an application to Kubernetes, it goes through a well-defined lifecycle.

At a high level:

Deployment Created
        ↓
ReplicaSet Created
        ↓
Pods Created
        ↓
Pods Scheduled on Nodes
        ↓
Containers Start
        ↓
Health Checks Pass
        ↓
Application Becomes Available
Kubernetes continuously watches this process and tries to keep the system in the desired state.

2. Pod Creation & Scheduling
A Pod is the smallest unit Kubernetes deploys.

What Happens When You Apply a Deployment
You apply a Deployment manifest
Kubernetes creates a ReplicaSet
The ReplicaSet creates the required number of Pods
The Scheduler assigns each Pod to a Node
The kubelet on that node starts the container
Key Insight: You never create Pods directly in production - Deployments and ReplicaSets manage them for you.

3. ReplicaSets - Maintaining Desired State
A ReplicaSet ensures that the desired number of pods are always running.

Example:

replicas: 3
What the ReplicaSet does:

If a pod crashes → a new pod is created
If a node fails → pods are recreated elsewhere
If replicas are increased → new pods are started
If replicas are decreased → pods are terminated
Key Idea: ReplicaSets are the self-healing mechanism behind Kubernetes deployments.

4. Deployment Rollouts & Update Mechanics
When you update your application (for example, a new image version), Kubernetes performs a rollout.

Rolling Update Strategy (Default)
During a rollout:

New pods are created with the new image
Old pods are terminated gradually
Traffic shifts incrementally
Availability is maintained
Possible rollout outcomes:

Successful rollout → all new pods become ready
Paused rollout → waiting for manual intervention
Failed rollout → new pods never become healthy
You can inspect rollout state using:

Deployment status
Pod readiness
ReplicaSet history
5. Health Probes - How Kubernetes Knows a Pod Is Healthy
Kubernetes does not guess pod health - it uses probes.

Types of Probes
Liveness Probe Checks if the container is alive → Failing this causes a container restart

Readiness Probe Checks if the pod can receive traffic → Failing this removes the pod from service load balancing

Startup Probe Used for slow-starting applications → Prevents premature restarts

Key Insight: Incorrect probes are one of the most common causes of broken deployments.

6. Resource Limits & Scheduling Behavior
Each pod can define:

CPU requests & limits
Memory requests & limits
These directly affect:

Whether a pod can be scheduled
Whether it gets throttled
Whether it gets terminated
Common behaviors:

CPU limit exceeded → throttling
Memory limit exceeded → pod is OOMKilled
Requests too high → pod stuck in Pending
7. Common Pod States & Failure Conditions
Understanding pod states is essential for debugging.

Common Pod States
Pending → Scheduler cannot place the pod
Running → Container is executing
CrashLoopBackOff → App keeps crashing
ImagePullBackOff → Image cannot be pulled
OOMKilled → Memory limit exceeded
Terminating → Pod is shutting down
Each state tells you exactly where the failure is happening.

8. Failure Recovery & Self-Healing
Kubernetes automatically responds to failures:

Pod crashes → restarted
Node fails → pods rescheduled
Health checks fail → traffic rerouted
Replica count violated → corrected
Important: Kubernetes guarantees desired state, not that your application logic is correct.

9. What You Should Be Able to Explain After This Lesson
You should confidently explain:

How pods are created and scheduled
How ReplicaSets maintain availability
What happens during a rolling update
How probes affect pod lifecycle
Why pods fail and how Kubernetes reacts
Tips for Success
Always start debugging from Pod status
Think in terms of desired vs current state
Remember: Kubernetes reacts to signals — probes, limits, and configs matter
Use mental models, not memorization
Pro Tip: If you understand why a pod is unhealthy, you understand Kubernetes.

Additional Reference Resources
Kubernetes Concepts Overview

Pods

Deployments

ReplicaSets

Probes (Liveness, Readiness, Startup)

Resource Management for Pods

By mastering Kubernetes application lifecycle mechanics, you gain the ability to deploy confidently, debug failures quickly, and operate systems reliably — the core responsibility of any DevOps or platform engineer.

