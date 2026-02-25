#!/bin/bash
# Service Discovery Verification Script
# This script demonstrates Kubernetes DNS-based service discovery
# Run this inside a pod to verify network connectivity

set -e

NAMESPACE="${NAMESPACE:-feastflow}"
BOLD='\033[1m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BOLD}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}║     Kubernetes Service Discovery Verification             ║${NC}"
echo -e "${BOLD}║     FeastFlow Network Testing - Sprint #3                 ║${NC}"
echo -e "${BOLD}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Display pod information
echo -e "${BOLD}[Pod Information]${NC}"
echo "  Pod Name:      ${HOSTNAME}"
echo "  Pod IP:        $(hostname -i 2>/dev/null || echo 'N/A')"
echo "  Namespace:     ${NAMESPACE}"
echo ""

# Test DNS resolution
test_dns() {
    local service=$1
    local fqdn="${service}.${NAMESPACE}.svc.cluster.local"
    
    echo -e "${BOLD}[Test] DNS Resolution: ${service}${NC}"
    
    # Test short form (within same namespace)
    if nslookup ${service} >/dev/null 2>&1; then
        local ip=$(nslookup ${service} | grep -A1 "Name:" | tail -n1 | awk '{print $2}')
        echo -e "  ${GREEN}✓${NC} Short-form DNS:  ${service} → ${ip}"
    else
        echo -e "  ${RED}✗${NC} Short-form DNS:  ${service} (failed)"
    fi
    
    # Test FQDN
    if nslookup ${fqdn} >/dev/null 2>&1; then
        local ip=$(nslookup ${fqdn} | grep -A1 "Name:" | tail -n1 | awk '{print $2}')
        echo -e "  ${GREEN}✓${NC} FQDN resolution: ${fqdn} → ${ip}"
    else
        echo -e "  ${RED}✗${NC} FQDN resolution: ${fqdn} (failed)"
    fi
    
    echo ""
}

# Test connectivity
test_connectivity() {
    local service=$1
    local port=$2
    local path=${3:-"/"}
    
    echo -e "${BOLD}[Test] HTTP Connectivity: ${service}:${port}${NC}"
    
    if timeout 5 curl -s -o /dev/null -w "%{http_code}" http://${service}:${port}${path} >/dev/null 2>&1; then
        local status=$(timeout 5 curl -s -o /dev/null -w "%{http_code}" http://${service}:${port}${path})
        echo -e "  ${GREEN}✓${NC} Service reachable - HTTP ${status}"
    else
        echo -e "  ${RED}✗${NC} Service not reachable"
    fi
    
    # Test with FQDN
    local fqdn="${service}.${NAMESPACE}.svc.cluster.local"
    if timeout 5 curl -s -o /dev/null -w "%{http_code}" http://${fqdn}:${port}${path} >/dev/null 2>&1; then
        local status=$(timeout 5 curl -s -o /dev/null -w "%{http_code}" http://${fqdn}:${port}${path})
        echo -e "  ${GREEN}✓${NC} FQDN reachable    - HTTP ${status}"
    else
        echo -e "  ${RED}✗${NC} FQDN not reachable"
    fi
    
    echo ""
}

# Test PostgreSQL connectivity
test_postgres() {
    local service="postgres"
    local port=5432
    
    echo -e "${BOLD}[Test] PostgreSQL Connectivity${NC}"
    
    if command -v pg_isready >/dev/null 2>&1; then
        if pg_isready -h ${service} -p ${port} >/dev/null 2>&1; then
            echo -e "  ${GREEN}✓${NC} PostgreSQL is ready (pg_isready)"
        else
            echo -e "  ${RED}✗${NC} PostgreSQL not ready"
        fi
    else
        # Fallback to netcat
        if timeout 2 nc -zv ${service} ${port} 2>&1 | grep -q succeeded; then
            echo -e "  ${GREEN}✓${NC} PostgreSQL port ${port} is open"
        else
            echo -e "  ${YELLOW}⚠${NC} PostgreSQL test skipped (nc/pg_isready not available)"
        fi
    fi
    
    echo ""
}

# Main test execution
echo -e "${BOLD}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BOLD} Part 1: DNS Service Discovery${NC}"
echo -e "${BOLD}═══════════════════════════════════════════════════════════${NC}"
echo ""

test_dns "postgres"
test_dns "feastflow-backend"
test_dns "feastflow-frontend"

echo -e "${BOLD}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BOLD} Part 2: Service Connectivity Tests${NC}"
echo -e "${BOLD}═══════════════════════════════════════════════════════════${NC}"
echo ""

test_postgres
test_connectivity "feastflow-backend" "5000" "/api/health"
test_connectivity "feastflow-frontend" "3000"

echo -e "${BOLD}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BOLD} Part 3: Key Concepts Demonstrated${NC}"
echo -e "${BOLD}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo "1. ${GREEN}DNS-based Service Discovery${NC}"
echo "   • Services are accessible by name (e.g., 'postgres')"
echo "   • No hardcoded IP addresses needed"
echo "   • FQDN format: <service>.<namespace>.svc.cluster.local"
echo ""
echo "2. ${GREEN}Pod-to-Service Communication${NC}"
echo "   • Pods communicate with services via DNS names"
echo "   • Kubernetes automatically load balances across pods"
echo "   • Services provide stable endpoints"
echo ""
echo "3. ${GREEN}Internal Cluster Networking${NC}"
echo "   • ClusterIP services are internal-only"
echo "   • All pods can reach services within the cluster"
echo "   • Network isolation via namespaces"
echo ""
echo -e "${BOLD}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✓ Service Discovery Verification Complete${NC}"
echo -e "${BOLD}═══════════════════════════════════════════════════════════${NC}"
