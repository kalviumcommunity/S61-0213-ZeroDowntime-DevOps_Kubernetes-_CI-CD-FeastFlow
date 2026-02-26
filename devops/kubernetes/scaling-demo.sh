#!/bin/bash
# Manual Scaling Demo Script for FeastFlow
# Demonstrates manual replica scaling in Kubernetes
# Author: DevOps Team
# Purpose: Show manual control over deployment replicas

set -e

# Colors for output
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
GRAY='\033[0;37m'
NC='\033[0m' # No Color

echo -e "${CYAN}================================================${NC}"
echo -e "${CYAN}  FeastFlow Manual Scaling Demonstration${NC}"
echo -e "${CYAN}================================================${NC}"
echo ""

# Function to display current status
show_deployment_status() {
    local deployment_name=$1
    
    echo -e "\n${YELLOW}Current Status of $deployment_name:${NC}"
    kubectl get deployment $deployment_name -n feastflow -o custom-columns=NAME:.metadata.name,READY:.status.readyReplicas,AVAILABLE:.status.availableReplicas,DESIRED:.spec.replicas
    pod_count=$(kubectl get pods -n feastflow -l component=backend --no-headers | wc -l)
    echo -e "${GREEN}Total Pods: $pod_count${NC}"
}

# Function to wait for rollout
wait_for_rollout() {
    local deployment_name=$1
    
    echo -e "\n${YELLOW}Waiting for rollout to complete...${NC}"
    kubectl rollout status deployment/$deployment_name -n feastflow --timeout=120s
}

# Check if namespace exists
echo -e "${GREEN}[Step 1] Verifying namespace...${NC}"
if ! kubectl get namespace feastflow &> /dev/null; then
    echo -e "${RED}ERROR: Namespace 'feastflow' not found. Please run setup first.${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Namespace exists${NC}"

# Show initial state
echo -e "\n${GREEN}[Step 2] Initial Deployment State${NC}"
show_deployment_status "feastflow-backend"

# Scale up demonstration
echo -e "\n${GREEN}[Step 3] Scaling UP from 2 to 5 replicas${NC}"
echo -e "${GRAY}Command: kubectl scale deployment feastflow-backend --replicas=5 -n feastflow${NC}"
kubectl scale deployment feastflow-backend --replicas=5 -n feastflow

echo -e "\n${YELLOW}Watching pods as they come online...${NC}"
sleep 3
timeout 30s kubectl get pods -n feastflow -l component=backend -w || true

show_deployment_status "feastflow-backend"

# Demonstrate immediate availability
echo -e "\n${GREEN}[Step 4] Verifying Service Load Distribution${NC}"
echo -e "${YELLOW}Checking endpoints registered with service...${NC}"
kubectl get endpoints feastflow-backend -n feastflow

# Scale down demonstration
echo -e "\n${GREEN}[Step 5] Scaling DOWN from 5 to 3 replicas${NC}"
echo -e "${GRAY}This demonstrates cost optimization during low-traffic periods${NC}"
kubectl scale deployment feastflow-backend --replicas=3 -n feastflow

wait_for_rollout "feastflow-backend"
show_deployment_status "feastflow-backend"

# Alternative methods demonstration
echo -e "\n${GREEN}[Step 6] Alternative Scaling Methods${NC}"
echo -e "${CYAN}Method 1 - Using kubectl scale (just demonstrated)${NC}"
echo -e "${GRAY}  kubectl scale deployment feastflow-backend --replicas=N -n feastflow${NC}"

echo -e "\n${CYAN}Method 2 - Using kubectl patch${NC}"
echo -e "${GRAY}  kubectl patch deployment feastflow-backend -n feastflow -p '{\"spec\":{\"replicas\":4}}'${NC}"

echo -e "\n${CYAN}Method 3 - Using kubectl edit (interactive)${NC}"
echo -e "${GRAY}  kubectl edit deployment feastflow-backend -n feastflow${NC}"

echo -e "\n${CYAN}Method 4 - Updating YAML file and applying${NC}"
echo -e "${GRAY}  kubectl apply -f 06-backend-deployment.yaml${NC}"

# Show ReplicaSet history
echo -e "\n${GREEN}[Step 7] ReplicaSet Management${NC}"
echo -e "${YELLOW}Kubernetes uses ReplicaSets to manage pod replicas:${NC}"
kubectl get replicasets -n feastflow -l component=backend

# Restore original state
echo -e "\n${GREEN}[Step 8] Restoring Original Configuration (2 replicas)${NC}"
kubectl scale deployment feastflow-backend --replicas=2 -n feastflow
wait_for_rollout "feastflow-backend"
show_deployment_status "feastflow-backend"

echo -e "\n${CYAN}================================================${NC}"
echo -e "${CYAN}  Manual Scaling Demo Complete!${NC}"
echo -e "${CYAN}================================================${NC}"
echo -e "\n${YELLOW}Key Takeaways:${NC}"
echo -e "${GREEN}✓ Manual scaling is instant and seamless${NC}"
echo -e "${GREEN}✓ No downtime during scaling operations${NC}"
echo -e "${GREEN}✓ Service automatically load-balances across all replicas${NC}"
echo -e "${GREEN}✓ Scaling can be done through multiple methods${NC}"
echo -e "\n${CYAN}Next: Try HPA for automatic scaling based on metrics!${NC}"
echo -e "${GRAY}Run: kubectl apply -f 12-backend-hpa.yaml${NC}"
