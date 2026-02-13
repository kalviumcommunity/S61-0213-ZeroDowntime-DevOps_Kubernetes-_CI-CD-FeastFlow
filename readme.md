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