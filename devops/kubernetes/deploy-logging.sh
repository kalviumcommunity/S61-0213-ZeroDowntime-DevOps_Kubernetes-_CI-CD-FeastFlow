#!/bin/bash
# deploy-logging.sh
# Deploys the complete centralized logging stack (Loki + Fluent Bit + Grafana)

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ $1${NC}"
}

print_section() {
    echo -e "\n${CYAN}--- $1 ---${NC}"
}

echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}FeastFlow Centralized Logging Deployment${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""

# Check if namespace exists
print_section "Checking Prerequisites"

if kubectl get namespace feastflow &>/dev/null; then
    print_success "Namespace exists"
else
    print_info "Creating feastflow namespace..."
    kubectl apply -f 00-namespace.yaml
    print_success "Namespace created"
fi

# Deploy logging components
print_section "Deploying Logging Stack"

print_info "Deploying Loki (log storage and indexing)..."
if kubectl apply -f 15-loki.yaml; then
    print_success "Loki deployed"
else
    echo -e "${RED}✗ Failed to deploy Loki${NC}"
    exit 1
fi

print_info "Deploying Fluent Bit (log collector)..."
if kubectl apply -f 16-fluent-bit.yaml; then
    print_success "Fluent Bit deployed"
else
    echo -e "${RED}✗ Failed to deploy Fluent Bit${NC}"
    exit 1
fi

print_info "Deploying Grafana (log visualization)..."
if kubectl apply -f 17-grafana.yaml; then
    print_success "Grafana deployed"
else
    echo -e "${RED}✗ Failed to deploy Grafana${NC}"
    exit 1
fi

# Wait for deployments to be ready
print_section "Waiting for Components to be Ready"

print_info "Waiting for Loki to be ready..."
if kubectl wait --for=condition=available --timeout=120s deployment/loki -n feastflow; then
    print_success "Loki is ready"
else
    echo -e "${RED}✗ Loki did not become ready in time${NC}"
fi

print_info "Waiting for Fluent Bit to be ready..."
sleep 10
FLUENT_BIT_READY=$(kubectl get daemonset fluent-bit -n feastflow -o jsonpath='{.status.numberReady}' 2>/dev/null || echo "0")
FLUENT_BIT_DESIRED=$(kubectl get daemonset fluent-bit -n feastflow -o jsonpath='{.status.desiredNumberScheduled}' 2>/dev/null || echo "0")
if [ "$FLUENT_BIT_READY" == "$FLUENT_BIT_DESIRED" ]; then
    print_success "Fluent Bit is ready ($FLUENT_BIT_READY/$FLUENT_BIT_DESIRED pods)"
else
    print_info "Fluent Bit: $FLUENT_BIT_READY/$FLUENT_BIT_DESIRED pods ready (may take a moment)"
fi

print_info "Waiting for Grafana to be ready..."
if kubectl wait --for=condition=available --timeout=120s deployment/grafana -n feastflow; then
    print_success "Grafana is ready"
else
    echo -e "${RED}✗ Grafana did not become ready in time${NC}"
fi

# Get Grafana URL
print_section "Access Information"

GRAFANA_PORT=$(kubectl get service grafana -n feastflow -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null)
if [ -n "$GRAFANA_PORT" ]; then
    echo ""
    echo -e "${GREEN}Centralized Logging Stack Deployed Successfully! 🎉${NC}"
    echo ""
    echo -e "${CYAN}Access Grafana:${NC}"
    echo -e "${NC}  URL:      http://localhost:$GRAFANA_PORT${NC}"
    echo -e "${NC}  Username: admin${NC}"
    echo -e "${NC}  Password: feastflow2024${NC}"
    echo ""
    echo -e "${CYAN}Quick Start:${NC}"
    echo -e "${NC}  1. Open http://localhost:$GRAFANA_PORT in your browser${NC}"
    echo -e "${NC}  2. Login with admin/feastflow2024${NC}"
    echo -e "${NC}  3. Go to Explore (compass icon)${NC}"
    echo -e "${NC}  4. Select 'Loki' datasource${NC}"
    echo -e "${YELLOW}  5. Try query: {k8s_namespace_name=\"feastflow\"}${NC}"
    echo ""
    echo -e "${CYAN}Verify Installation:${NC}"
    echo -e "${YELLOW}  ./verify-centralized-logging.sh${NC}"
    echo ""
    echo -e "${CYAN}Documentation:${NC}"
    echo -e "${NC}  See CENTRALIZED_LOGGING.md for detailed usage guide${NC}"
    echo ""
fi

# Show deployed resources
print_section "Deployed Resources"

echo ""
echo -e "${CYAN}Pods:${NC}"
kubectl get pods -n feastflow -l component=logging

echo -e "\n${CYAN}Services:${NC}"
kubectl get svc -n feastflow -l component=logging

echo -e "\n${CYAN}PersistentVolumeClaims:${NC}"
kubectl get pvc -n feastflow | grep -E "loki|grafana" || echo "No PVCs found yet (may be pending)"

echo ""
echo -e "${CYAN}========================================${NC}"
echo -e "${GREEN}Deployment Complete!${NC}"
echo -e "${CYAN}========================================${NC}"
