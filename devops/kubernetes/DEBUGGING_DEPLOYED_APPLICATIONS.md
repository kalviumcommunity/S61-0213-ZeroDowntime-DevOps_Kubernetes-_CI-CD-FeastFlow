# Debugging Deployed Applications Using `kubectl` and Logs

## Purpose

This guide demonstrates a production-operator debugging workflow for Sprint #3.
The goal is to diagnose a runtime failure using observable Kubernetes signals, not guesswork.

## Incident Scenario

Workload: `deployment/feastflow-backend` in namespace `feastflow`

Failure type used in this project: invalid container image update causing `ErrImagePull` and `ImagePullBackOff`

This scenario is already supported by:

- `devops/kubernetes/rollout-demo.ps1`
- `devops/kubernetes/rollout-demo.sh`

Both scripts intentionally set a bad image tag (`feastflow-backend:rollback-demo-bad`) to trigger a realistic rollout failure.

## Debugging Workflow

Use this sequence exactly when investigating a failed deployment.

### 1. Identify the Symptom

```bash
kubectl get deployments -n feastflow
kubectl get pods -n feastflow -l component=backend
kubectl rollout status deployment/feastflow-backend -n feastflow --timeout=45s
```

What to look for:

- rollout does not complete in expected time
- backend pods show `ErrImagePull` or `ImagePullBackOff`
- Ready replicas stay below desired replicas

### 2. Inspect the Resource State

```bash
kubectl describe deployment feastflow-backend -n feastflow
kubectl get rs -n feastflow -l component=backend
```

Why this matters:

- confirms desired image in Deployment spec
- shows whether a new ReplicaSet was created
- verifies the controller is trying to progress rollout

### 3. Inspect Pod-Level Failure Signals

```bash
kubectl get pods -n feastflow -l component=backend
kubectl describe pod <failing-pod-name> -n feastflow
```

Key fields to inspect in `describe pod`:

- `State`
- `Last State`
- `Reason`
- `Message`
- `Events`

Expected indicators for this incident:

- `Reason: ErrImagePull`
- `Reason: ImagePullBackOff`
- event messages indicating image could not be pulled or tag not found

### 4. Check Events Chronologically

```bash
kubectl get events -n feastflow --sort-by='.lastTimestamp'
```

Why this matters:

- events show exact control-plane sequence (Scheduled -> Pulling -> Failed)
- helps separate first failure from follow-on failures

### 5. Check Logs Where Applicable

For image pull failures, container logs may be empty because the container never starts.
Still run log checks to prove this step was attempted:

```bash
kubectl logs deployment/feastflow-backend -n feastflow --tail=50
kubectl logs <failing-pod-name> -n feastflow --previous
```

Interpretation:

- no useful app logs + image pull events strongly indicates startup never reached application code

## Symptom vs Root Cause (Required in PR)

### Observed Symptom

`feastflow-backend` rollout stalled; one or more pods were stuck in `ImagePullBackOff`, and desired readiness was not reached.

### Root Cause

Deployment image was updated to a non-existent tag (`feastflow-backend:rollback-demo-bad`).
The kubelet/container runtime could not pull the image, so replacement pods never became Ready.

## Recovery Action

Rollback to the previous stable Deployment revision.

```bash
kubectl rollout history deployment/feastflow-backend -n feastflow
kubectl rollout undo deployment/feastflow-backend -n feastflow
kubectl rollout status deployment/feastflow-backend -n feastflow
```

## Verification After Recovery

```bash
kubectl get deployments -n feastflow
kubectl get pods -n feastflow -l component=backend
kubectl get events -n feastflow --sort-by='.lastTimestamp'
```

Success criteria:

- deployment reaches Available state
- backend pods return to `Running` with readiness `1/1`
- no new image-pull failures continue after rollback

## Repeatable Operator Checklist

1. Detect failure from rollout or pod status.
2. Inspect Deployment and ReplicaSet state.
3. Inspect failing pod details and events.
4. Confirm whether logs are available.
5. State symptom separately from root cause.
6. Apply rollback or fix.
7. Verify steady state after recovery.

## Optional Reproduction Commands

Use one of these to reproduce and capture evidence for your PR.

Windows:

```powershell
.\devops\kubernetes\rollout-demo.ps1
```

Linux/Mac:

```bash
bash devops/kubernetes/rollout-demo.sh
```

These scripts include a successful update, controlled failure simulation, and rollback verification.
