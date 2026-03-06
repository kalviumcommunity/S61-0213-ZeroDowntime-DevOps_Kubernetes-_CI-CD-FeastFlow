# Observability Foundations: Metrics, Logs, and Traces

## Purpose

This document captures Sprint #3 observability understanding for FeastFlow.

Scope of this contribution:

- Explain observability (beyond monitoring)
- Explain the three pillars: metrics, logs, traces
- Clarify what questions each signal answers
- Map each signal to real FeastFlow situations

Out of scope for this sprint item:

- No Prometheus/Grafana/Jaeger installation steps
- No dashboard setup
- No tracing SDK integration tasks

## Observability vs Monitoring

Monitoring tells us whether known failure conditions are happening.

- Example: CPU > 80%, pod restart count increased, `/health` failed.

Observability helps us investigate unknown behavior by using system outputs.

- Example: "Checkout latency increased only for some users after deploy" and we need to discover why.

In short:

- Monitoring is alerting on known conditions.
- Observability is understanding internal behavior from emitted signals.

## The Three Pillars

| Pillar | What it is | Best for | Typical question answered |
| --- | --- | --- | --- |
| Metrics | Numeric time-series measurements | Trends, SLOs, alerting, capacity | "Is latency/error rate getting worse?" |
| Logs | Timestamped event records with context | Root-cause details for specific failures | "What exactly failed for this request?" |
| Traces | End-to-end request path across services | Cross-service latency and dependency analysis | "Where did this request spend time?" |

## What Each Signal Solves in Practice

### Metrics

Use metrics first to detect and quantify system behavior.

- Fast to aggregate across pods/services
- Good for thresholds and trend-based decisions
- Ideal for answering "how much" and "how often"

FeastFlow examples:

- API error rate during dinner-hour traffic
- P95 response latency for checkout endpoints
- HPA-related CPU and memory utilization trends

### Logs

Use logs to inspect exact events around a failure.

- High-detail context (error stack, request metadata, component output)
- Best for explaining *why* a known issue happened
- Useful during rollout/rollback troubleshooting

FeastFlow examples:

- Backend logs show DB connection timeout during rollout
- Ingress logs show repeated 502 for `/api/*`
- Application logs reveal invalid payload or auth token failure

### Traces

Use traces for request-level journey and latency breakdown.

- Shows a single request across frontend, backend, and database hops
- Identifies bottlenecks between services
- Strong for intermittent issues where aggregate metrics look normal

FeastFlow examples:

- Order creation request is slow only when pricing call fans out
- Backend endpoint appears healthy overall, but one downstream call dominates latency
- Random timeout occurs only on a specific service path

## Decision Guide: Which Signal First?

1. Start with **metrics** to confirm impact and scope.
2. Use **logs** to inspect concrete error events.
3. Use **traces** when problem spans multiple services or latency path is unclear.

This sequence avoids random debugging and narrows investigation quickly.

## Scenario Mapping for This Project

### Scenario 1: "Users report slow checkout after a release"

- Start with metrics: request latency and error rate trend before vs after release
- Then logs: backend exceptions, DB timeout messages, ingress upstream failures
- Then traces: identify whether latency is in backend handler, DB query, or downstream service call

### Scenario 2: "Backend replicas scale up frequently"

- Start with metrics: CPU/memory and request-rate patterns triggering HPA
- Then logs: check for retry storms or repeated expensive operations
- Traces optional: verify if one endpoint causes high per-request work

### Scenario 3: "Intermittent 500 errors, cannot reproduce locally"

- Start with metrics: rate and timeframe of 500 spikes
- Then logs: correlate failing request ids and stack traces
- Then traces: follow failing requests across service boundaries to isolate the failing hop

## Current-State Observability in This Repo

Today, this repository already demonstrates basic operational visibility through:

- Kubernetes events and resource inspection (`kubectl describe`, `kubectl get events`)
- Workload and container logs (`kubectl logs`)
- Resource metrics for scaling behavior (`kubectl top`, HPA data)

This is enough for Sprint #3 conceptual submission because the focus is reasoning, not tool installation.

## Sprint #3 Submission Alignment Checklist

- [x] Explain observability clearly (not equal to monitoring)
- [x] Explain metrics, logs, and traces
- [x] Show differences and use cases
- [x] Map pillars to real FeastFlow scenarios
- [x] Keep contribution conceptual and repository-relevant
