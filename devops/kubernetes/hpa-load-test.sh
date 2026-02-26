#!/bin/bash
# HPA Load Test and Verification Script
# Generates load on backend to trigger HPA scaling
# Monitors scaling behavior in real-time

set -e

# Default parameters
DURATION=180  # Duration in seconds (default 3 minutes)
CONCURRENT=10  # Number of concurrent requests
TARGET="backend"  # Target deployment: backend or frontend

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --duration)
            DURATION="$2"
            shift 2
            ;;
        --concurrent)
            CONCURRENT="$2"
            shift 2
            ;;
        --target)
            TARGET="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Colors
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
GRAY='\033[0;37m'
NC='\033[0m'

echo -e "${CYAN}================================================${NC}"
echo -e "${CYAN}  FeastFlow HPA Load Test & Verification${NC}"
echo -e "${CYAN}================================================${NC}"
echo ""

# Verify prerequisites
echo -e "${GREEN}[Pre-check] Verifying prerequisites...${NC}"

# Check if metrics-server is available
echo -e "${YELLOW}Checking metrics-server...${NC}"
if ! kubectl get deployment metrics-server -n kube-system &> /dev/null; then
    echo -e "${YELLOW}WARNING: metrics-server not found. Installing...${NC}"
    echo -e "${GRAY}Command: kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml${NC}"
    kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
    echo -e "${YELLOW}Waiting 30s for metrics-server to be ready...${NC}"
    sleep 30
fi

# For KIND clusters, patch metrics-server to disable TLS verification
echo -e "${YELLOW}Patching metrics-server for KIND cluster...${NC}"
kubectl patch deployment metrics-server -n kube-system --type='json' -p='[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"}]' 2>/dev/null || true

echo -e "${GREEN}✓ Prerequisites checked${NC}"

# Verify HPA exists
echo -e "\n${GREEN}[Step 1] Verifying HPA configuration...${NC}"
HPA_NAME="feastflow-${TARGET}-hpa"
if ! kubectl get hpa $HPA_NAME -n feastflow &> /dev/null; then
    echo -e "${RED}ERROR: HPA '$HPA_NAME' not found. Applying configuration...${NC}"
    kubectl apply -f devops/kubernetes/12-backend-hpa.yaml
    sleep 10
fi

echo -e "\n${YELLOW}Current HPA Status:${NC}"
kubectl get hpa $HPA_NAME -n feastflow

# Show initial deployment state
echo -e "\n${GREEN}[Step 2] Initial State${NC}"
DEPLOYMENT_NAME="feastflow-${TARGET}"
kubectl get deployment $DEPLOYMENT_NAME -n feastflow
kubectl top pods -n feastflow -l component=$TARGET 2>/dev/null || echo "Waiting for metrics..."

# Get service endpoint
echo -e "\n${GREEN}[Step 3] Preparing Load Test${NC}"
SERVICE_IP=$(kubectl get svc $DEPLOYMENT_NAME -n feastflow -o jsonpath='{.spec.clusterIP}')
SERVICE_PORT=$(kubectl get svc $DEPLOYMENT_NAME -n feastflow -o jsonpath='{.spec.ports[0].port}')
ENDPOINT="http://${SERVICE_IP}:${SERVICE_PORT}/api/health"

echo -e "${CYAN}Target Endpoint: $ENDPOINT${NC}"
echo -e "${CYAN}Duration: $DURATION seconds${NC}"
echo -e "${CYAN}Concurrent Requests: $CONCURRENT${NC}"

# Start load test in background
echo -e "\n${GREEN}[Step 4] Starting Load Test...${NC}"
echo -e "${YELLOW}Generating CPU load to trigger HPA...${NC}"

# Create load test function
generate_load() {
    local endpoint=$1
    local duration=$2
    local concurrent=$3
    local end_time=$(($(date +%s) + duration))
    
    while [ $(date +%s) -lt $end_time ]; do
        for ((i=1; i<=concurrent; i++)); do
            (
                for ((j=1; j<=100; j++)); do
                    curl -s -m 2 "$endpoint" &> /dev/null || true
                done
            ) &
        done
        wait
    done
}

# Start load generator in background
generate_load "$ENDPOINT" "$DURATION" "$CONCURRENT" &
LOAD_PID=$!

echo -e "${GREEN}Load test started (PID: $LOAD_PID)${NC}"
echo -e "\n${YELLOW}Monitoring HPA scaling behavior...${NC}"
echo -e "${GRAY}(Press Ctrl+C to stop monitoring, load test will continue)${NC}"
echo ""

# Monitor loop
START_TIME=$(date +%s)
ITERATION=0

monitor_scaling() {
    while [ $(($(date +%s) - START_TIME)) -lt $((DURATION + 30)) ]; do
        ((ITERATION++))
        ELAPSED=$(($(date +%s) - START_TIME))
        
        echo -e "${CYAN}--- Iteration $ITERATION (${ELAPSED}s elapsed) ---${NC}"
        
        # Show HPA status
        echo -e "\n${YELLOW}HPA Status:${NC}"
        kubectl get hpa $HPA_NAME -n feastflow
        
        # Show pod metrics
        echo -e "\n${YELLOW}Pod Metrics:${NC}"
        kubectl top pods -n feastflow -l component=$TARGET 2>/dev/null || echo "Metrics not ready yet..."
        
        # Show deployment replicas
        echo -e "\n${YELLOW}Deployment Status:${NC}"
        kubectl get deployment $DEPLOYMENT_NAME -n feastflow -o custom-columns=NAME:.metadata.name,DESIRED:.spec.replicas,CURRENT:.status.replicas,READY:.status.readyReplicas,UP-TO-DATE:.status.updatedReplicas
        
        # Show pod list
        echo -e "\n${YELLOW}Pods:${NC}"
        kubectl get pods -n feastflow -l component=$TARGET -o wide
        
        echo -e "\n${GRAY}------------------------------------------------------------${NC}"
        sleep 15
    done
}

# Run monitoring with trap for Ctrl+C
trap "echo -e '\n${YELLOW}Monitoring stopped by user.${NC}'; kill $LOAD_PID 2>/dev/null || true" INT
monitor_scaling
trap - INT

# Wait for load test to complete
echo -e "\n${YELLOW}Waiting for load test to complete...${NC}"
wait $LOAD_PID 2>/dev/null || true

# Final status
echo -e "\n${GREEN}[Step 5] Final Status${NC}"
echo -e "\n${YELLOW}Final HPA Status:${NC}"
kubectl get hpa $HPA_NAME -n feastflow

echo -e "\n${YELLOW}Final Deployment Status:${NC}"
kubectl get deployment $DEPLOYMENT_NAME -n feastflow

echo -e "\n${YELLOW}Final Pod Metrics:${NC}"
kubectl top pods -n feastflow -l component=$TARGET 2>/dev/null || echo "Metrics not available"

# Show scaling events
echo -e "\n${GREEN}[Step 6] Scaling Events${NC}"
echo -e "${YELLOW}Recent HPA scaling events:${NC}"
kubectl describe hpa $HPA_NAME -n feastflow | grep -A 20 "Events:"

echo -e "\n${CYAN}================================================${NC}"
echo -e "${CYAN}  Load Test Complete!${NC}"
echo -e "${CYAN}================================================${NC}"
echo -e "\n${YELLOW}Observations:${NC}"
echo -e "${GREEN}✓ Check if replicas increased during load${NC}"
echo -e "${GREEN}✓ Note the scaling threshold that triggered autoscaling${NC}"
echo -e "${GREEN}✓ Observe scale-down behavior after load stops${NC}"
echo -e "\n${CYAN}Note: Scale-down is gradual (5-min stabilization window)${NC}"
echo -e "${GRAY}Monitor with: kubectl get hpa $HPA_NAME -n feastflow --watch${NC}"
