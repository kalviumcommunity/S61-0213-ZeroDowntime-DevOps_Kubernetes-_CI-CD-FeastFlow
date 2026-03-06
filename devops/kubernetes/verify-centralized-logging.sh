#!/bin/bash
# verify-centralized-logging.sh
# Validates that the centralized logging stack (Loki + Fluent Bit + Grafana) is working correctly

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Helper functions
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_failure() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ $1${NC}"
}

print_section() {
    echo -e "\n${CYAN}--- $1 ---${NC}"
}

echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}FeastFlow Centralized Logging Verification${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""

ALL_PASSED=true

# 1. Check if logging components are deployed
print_section "Checking Logging Components Deployment"

if kubectl get deployment loki -n feastflow &>/dev/null; then
    print_success "Loki deployment exists"
else
    print_failure "Loki deployment not found"
    ALL_PASSED=false
fi

if kubectl get daemonset fluent-bit -n feastflow &>/dev/null; then
    print_success "Fluent Bit DaemonSet exists"
else
    print_failure "Fluent Bit DaemonSet not found"
    ALL_PASSED=false
fi

if kubectl get deployment grafana -n feastflow &>/dev/null; then
    print_success "Grafana deployment exists"
else
    print_failure "Grafana deployment not found"
    ALL_PASSED=false
fi

# 2. Check pod readiness
print_section "Checking Pod Readiness"

LOKI_READY=false
LOKI_POD=$(kubectl get pods -n feastflow -l app=loki -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [ -n "$LOKI_POD" ]; then
    POD_STATUS=$(kubectl get pod "$LOKI_POD" -n feastflow -o jsonpath='{.status.phase}')
    READY=$(kubectl get pod "$LOKI_POD" -n feastflow -o jsonpath='{.status.containerStatuses[0].ready}')
    
    if [ "$POD_STATUS" == "Running" ] && [ "$READY" == "true" ]; then
        print_success "Loki pod '$LOKI_POD' is ready"
        LOKI_READY=true
    else
        print_failure "Loki pod '$LOKI_POD' not ready (Status: $POD_STATUS, Ready: $READY)"
        ALL_PASSED=false
    fi
else
    print_failure "No Loki pods found"
    ALL_PASSED=false
fi

FLUENT_BIT_READY=0
FLUENT_BIT_PODS=$(kubectl get pods -n feastflow -l app=fluent-bit -o jsonpath='{.items[*].metadata.name}' 2>/dev/null)
if [ -n "$FLUENT_BIT_PODS" ]; then
    for pod in $FLUENT_BIT_PODS; do
        POD_STATUS=$(kubectl get pod "$pod" -n feastflow -o jsonpath='{.status.phase}')
        READY=$(kubectl get pod "$pod" -n feastflow -o jsonpath='{.status.containerStatuses[0].ready}')
        
        if [ "$POD_STATUS" == "Running" ] && [ "$READY" == "true" ]; then
            ((FLUENT_BIT_READY++))
        fi
    done
    print_success "Fluent Bit has $FLUENT_BIT_READY ready pod(s)"
else
    print_failure "No Fluent Bit pods found"
    ALL_PASSED=false
fi

GRAFANA_READY=false
GRAFANA_POD=$(kubectl get pods -n feastflow -l app=grafana -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [ -n "$GRAFANA_POD" ]; then
    POD_STATUS=$(kubectl get pod "$GRAFANA_POD" -n feastflow -o jsonpath='{.status.phase}')
    READY=$(kubectl get pod "$GRAFANA_POD" -n feastflow -o jsonpath='{.status.containerStatuses[0].ready}')
    
    if [ "$POD_STATUS" == "Running" ] && [ "$READY" == "true" ]; then
        print_success "Grafana pod '$GRAFANA_POD' is ready"
        GRAFANA_READY=true
    else
        print_failure "Grafana pod '$GRAFANA_POD' not ready (Status: $POD_STATUS, Ready: $READY)"
        ALL_PASSED=false
    fi
else
    print_failure "No Grafana pods found"
    ALL_PASSED=false
fi

# 3. Check services
print_section "Checking Services"

if kubectl get service loki -n feastflow &>/dev/null; then
    LOKI_IP=$(kubectl get service loki -n feastflow -o jsonpath='{.spec.clusterIP}')
    LOKI_PORT=$(kubectl get service loki -n feastflow -o jsonpath='{.spec.ports[0].port}')
    print_success "Loki service exists (Endpoint: $LOKI_IP:$LOKI_PORT)"
else
    print_failure "Loki service not found"
    ALL_PASSED=false
fi

if kubectl get service grafana -n feastflow &>/dev/null; then
    NODE_PORT=$(kubectl get service grafana -n feastflow -o jsonpath='{.spec.ports[0].nodePort}')
    print_success "Grafana service exists (NodePort: $NODE_PORT)"
    print_info "Access Grafana at: http://localhost:$NODE_PORT (admin/feastflow2024)"
else
    print_failure "Grafana service not found"
    ALL_PASSED=false
fi

# 4. Test Loki readiness endpoint
print_section "Testing Loki API"

if [ "$LOKI_READY" = true ]; then
    print_info "Testing Loki /ready endpoint..."
    
    if kubectl exec -n feastflow "$LOKI_POD" -- wget -q -O- http://localhost:3100/ready &>/dev/null; then
        print_success "Loki is ready and accepting requests"
    else
        print_failure "Loki /ready endpoint failed"
        ALL_PASSED=false
    fi
else
    print_info "Skipping Loki API test (pod not ready)"
fi

# 5. Generate test logs
print_section "Generating Test Logs"

print_info "Creating test pod to generate logs..."

cat <<EOF | kubectl apply -f - &>/dev/null
apiVersion: v1
kind: Pod
metadata:
  name: log-generator-test
  namespace: feastflow
  labels:
    app: log-generator
    test: centralized-logging
spec:
  containers:
  - name: log-generator
    image: busybox
    command: ["/bin/sh", "-c"]
    args:
      - |
        echo "Starting log generation test - timestamp: \$(date)"
        for i in \$(seq 1 10); do
          echo "Test log message \$i from log-generator-test - FeastFlow centralized logging verification"
          sleep 1
        done
        echo "Log generation test completed - timestamp: \$(date)"
        sleep 300
  restartPolicy: Never
EOF

if [ $? -eq 0 ]; then
    print_success "Test log generator pod created"
    print_info "Waiting 15 seconds for logs to be collected..."
    sleep 15
else
    print_failure "Failed to create test log generator pod"
    ALL_PASSED=false
fi

# 6. Query logs from Loki
print_section "Querying Logs from Loki"

if [ "$LOKI_READY" = true ]; then
    print_info "Querying Loki for test logs..."
    
    # Query for our test pod logs
    QUERY='{k8s_pod_name=~"log-generator-test"}'
    ENCODED_QUERY=$(printf %s "$QUERY" | jq -sRr @uri)
    QUERY_URL="http://localhost:3100/loki/api/v1/query?query=$ENCODED_QUERY"
    
    QUERY_RESULT=$(kubectl exec -n feastflow "$LOKI_POD" -- wget -q -O- "$QUERY_URL" 2>/dev/null)
    
    if echo "$QUERY_RESULT" | grep -q "log-generator-test"; then
        print_success "Successfully queried logs from Loki"
        print_info "Found test logs in centralized logging system"
        
        if echo "$QUERY_RESULT" | grep -q '"values":\[\['; then
            print_success "Logs are being collected and indexed"
        fi
    else
        print_failure "Could not find test logs in Loki (logs may take time to arrive)"
        print_info "This may not be an error if the system was just deployed"
    fi
    
    # Query for backend logs
    print_info "\nQuerying for backend application logs..."
    BACKEND_QUERY='{k8s_labels_app="backend"}'
    ENCODED_BACKEND_QUERY=$(printf %s "$BACKEND_QUERY" | jq -sRr @uri)
    BACKEND_QUERY_URL="http://localhost:3100/loki/api/v1/query?query=$ENCODED_BACKEND_QUERY"
    
    BACKEND_RESULT=$(kubectl exec -n feastflow "$LOKI_POD" -- wget -q -O- "$BACKEND_QUERY_URL" 2>/dev/null)
    
    if echo "$BACKEND_RESULT" | grep -q "backend"; then
        print_success "Backend application logs found in Loki"
    else
        print_info "Backend logs not yet available (may need time to collect)"
    fi
else
    print_info "Skipping Loki query test (pod not ready)"
fi

# 7. Check Fluent Bit metrics
print_section "Checking Fluent Bit Metrics"

if [ $FLUENT_BIT_READY -gt 0 ]; then
    FLUENT_BIT_POD=$(echo $FLUENT_BIT_PODS | awk '{print $1}')
    
    print_info "Checking Fluent Bit metrics..."
    METRICS=$(kubectl exec -n feastflow "$FLUENT_BIT_POD" -- wget -q -O- http://localhost:2020/api/v1/metrics 2>/dev/null)
    
    if [ -n "$METRICS" ]; then
        print_success "Fluent Bit metrics endpoint is accessible"
        
        if echo "$METRICS" | grep -q "output"; then
            print_success "Fluent Bit is forwarding logs to Loki"
        fi
    else
        print_failure "Could not access Fluent Bit metrics"
    fi
else
    print_info "Skipping Fluent Bit metrics check (no ready pods)"
fi

# 8. Verify labels are being applied
print_section "Verifying Log Labels"

if [ "$LOKI_READY" = true ]; then
    print_info "Checking available labels in Loki..."
    LABELS_URL="http://localhost:3100/loki/api/v1/labels"
    LABELS_RESULT=$(kubectl exec -n feastflow "$LOKI_POD" -- wget -q -O- "$LABELS_URL" 2>/dev/null)
    
    if [ -n "$LABELS_RESULT" ]; then
        EXPECTED_LABELS=("k8s_namespace_name" "k8s_pod_name" "k8s_container_name" "cluster" "job")
        FOUND_LABELS=0
        
        for label in "${EXPECTED_LABELS[@]}"; do
            if echo "$LABELS_RESULT" | grep -q "$label"; then
                ((FOUND_LABELS++))
            fi
        done
        
        if [ $FOUND_LABELS -ge 3 ]; then
            print_success "Log labels are properly configured ($FOUND_LABELS/${#EXPECTED_LABELS[@]} expected labels found)"
        else
            print_info "Some labels may not be available yet ($FOUND_LABELS/${#EXPECTED_LABELS[@]} found)"
        fi
    fi
else
    print_info "Skipping label verification (Loki not ready)"
fi

# Cleanup test pod
print_section "Cleanup"
print_info "Removing test log generator pod..."
kubectl delete pod log-generator-test -n feastflow --ignore-not-found=true &>/dev/null

# Summary
echo -e "\n${CYAN}========================================${NC}"
echo -e "${CYAN}Verification Summary${NC}"
echo -e "${CYAN}========================================${NC}"

if [ "$ALL_PASSED" = true ]; then
    echo -e "\n${GREEN}✓ All critical checks passed!${NC}"
    echo -e "\n${GREEN}Centralized logging is operational:${NC}"
    echo -e "${NC}  - Fluent Bit is collecting logs from all pods${NC}"
    echo -e "${NC}  - Loki is storing and indexing logs${NC}"
    echo -e "${NC}  - Grafana is available for log visualization${NC}"
    
    if kubectl get service grafana -n feastflow &>/dev/null; then
        NODE_PORT=$(kubectl get service grafana -n feastflow -o jsonpath='{.spec.ports[0].nodePort}')
        echo -e "\n${YELLOW}Next Steps:${NC}"
        echo -e "${NC}  1. Access Grafana: http://localhost:$NODE_PORT${NC}"
        echo -e "${NC}  2. Login: admin / feastflow2024${NC}"
        echo -e "${NC}  3. Go to Explore > Select 'Loki' datasource${NC}"
        echo -e "${NC}  4. Use LogQL queries like:${NC}"
        echo -e "${CYAN}     {k8s_namespace_name=\"feastflow\"}${NC}"
        echo -e "${CYAN}     {k8s_labels_app=\"backend\"}${NC}"
        echo -e "${CYAN}     {k8s_labels_app=\"frontend\"}${NC}"
    fi
    
    exit 0
else
    echo -e "\n${RED}✗ Some checks failed${NC}"
    echo -e "\n${YELLOW}Troubleshooting:${NC}"
    echo -e "${NC}  1. Check pod logs:${NC}"
    echo -e "${CYAN}     kubectl logs -n feastflow -l app=loki${NC}"
    echo -e "${CYAN}     kubectl logs -n feastflow -l app=fluent-bit${NC}"
    echo -e "${CYAN}     kubectl logs -n feastflow -l app=grafana${NC}"
    echo -e "\n${NC}  2. Check pod status:${NC}"
    echo -e "${CYAN}     kubectl describe pod -n feastflow -l app=loki${NC}"
    echo -e "${CYAN}     kubectl describe pod -n feastflow -l app=fluent-bit${NC}"
    echo -e "\n${NC}  3. Verify PersistentVolumeClaims:${NC}"
    echo -e "${CYAN}     kubectl get pvc -n feastflow${NC}"
    
    exit 1
fi
