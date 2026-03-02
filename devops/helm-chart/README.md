# FeastFlow Helm Chart

This Helm chart deploys the FeastFlow backend application on Kubernetes.

## Configuration

See `values.yaml` for configurable parameters such as image, replica count, and ports.

## Usage

```sh
# From the helm-chart directory
helm install feastflow-app .
```

To override values:

```sh
helm install feastflow-app . \
  --set image.repository=myrepo/backend \
  --set image.tag=latest \
  --set replicaCount=3
```
