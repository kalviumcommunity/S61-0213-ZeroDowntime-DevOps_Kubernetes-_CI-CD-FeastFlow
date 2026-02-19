#!/bin/bash

################################################################################
# FeastFlow Process and Network Check Script
# Purpose: Demonstrate process and network debugging for DevOps
# Safe to run: Read-only operations, no system modifications
################################################################################

set -e  # Exit on error

# Colors for output (POSIX-compatible)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}FeastFlow Process & Network Check${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Section 1: Process Inspection
echo -e "${GREEN}[Section 1] Process Inspection with 'ps'${NC}"
echo ""
echo -e "${CYAN}Why this matters for DevOps:${NC}"
echo "• Verify if your application is running"
echo "• Check how much CPU/memory it's consuming"
echo "• Find the process ID (PID) to send signals or debug"
echo "• Identify processes that shouldn't be running"
echo ""

echo -e "${YELLOW}Command: ps aux | head -15${NC}"
echo "Explanation: Shows all processes with CPU, memory, and command details"
echo ""
echo "USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND"
ps aux | head -15
echo ""

echo -e "${YELLOW}Command: ps aux | grep -E 'node|python|nginx|postgres' | grep -v grep${NC}"
echo "Explanation: Find specific application processes (Node.js, Python, Nginx, PostgreSQL)"
echo ""
ps aux | grep -E 'node|python|nginx|postgres' | grep -v grep || echo -e "${RED}No matching processes found${NC}"
echo ""

echo -e "${CYAN}Interpreting ps output:${NC}"
echo "• USER: Who owns the process"
echo "• PID: Process ID (use for kill, strace, etc.)"
echo "• %CPU: CPU usage percentage"
echo "• %MEM: Memory usage percentage"
echo "• VSZ: Virtual memory size (KB)"
echo "• RSS: Resident set size - actual RAM used (KB)"
echo "• STAT: Process state (R=running, S=sleeping, Z=zombie)"
echo "• COMMAND: The actual command/program running"
echo ""

# Section 2: Current User's Processes
echo -e "${GREEN}[Section 2] Processes Owned by Current User${NC}"
echo ""
echo -e "${YELLOW}Command: ps -u \$(whoami) -o pid,ppid,%cpu,%mem,stat,comm${NC}"
echo "Explanation: Shows only your processes with key metrics"
echo ""
ps -u "$(whoami)" -o pid,ppid,%cpu,%mem,stat,comm 2>/dev/null | head -20 || echo "Running with minimal output"
echo ""

# Section 3: Network - Listening Ports
echo -e "${GREEN}[Section 3] Network Listening Ports with 'ss'${NC}"
echo ""
echo -e "${CYAN}Why this matters for DevOps:${NC}"
echo "• Verify your service is listening on the correct port"
echo "• Debug 'address already in use' errors"
echo "• Confirm no unauthorized services are running"
echo "• Check which IP addresses services bind to (0.0.0.0 vs 127.0.0.1)"
echo ""

# Check if ss is available, fallback to netstat
if command -v ss >/dev/null 2>&1; then
    echo -e "${YELLOW}Command: ss -tulpn${NC}"
    echo "Explanation: Shows TCP/UDP listening ports with process info"
    echo "  -t = TCP sockets"
    echo "  -u = UDP sockets"
    echo "  -l = listening sockets only"
    echo "  -p = show process using the socket"
    echo "  -n = don't resolve names (show IPs/ports as numbers)"
    echo ""
    
    # Run with sudo if available, otherwise run without -p flag
    if [ "$EUID" -eq 0 ]; then
        ss -tulpn
    else
        echo -e "${YELLOW}Running without root (no process info shown):${NC}"
        ss -tuln | head -20
    fi
    echo ""
    
    echo -e "${CYAN}Interpreting ss output:${NC}"
    echo "• Netid: tcp/udp protocol"
    echo "• State: LISTEN (accepting connections) or ESTAB (established)"
    echo "• Local Address: IP:Port (0.0.0.0 = all interfaces, 127.0.0.1 = localhost only)"
    echo "• Peer Address: Remote connection details"
    echo "• Process: What program owns this socket"
    echo ""
    
elif command -v netstat >/dev/null 2>&1; then
    echo -e "${YELLOW}Command: netstat -tulpn${NC}"
    echo "Explanation: Shows TCP/UDP listening ports (netstat fallback)"
    echo ""
    if [ "$EUID" -eq 0 ]; then
        netstat -tulpn
    else
        echo -e "${YELLOW}Running without root (no process info shown):${NC}"
        netstat -tuln | head -20
    fi
    echo ""
else
    echo -e "${RED}Neither 'ss' nor 'netstat' available${NC}"
    echo ""
fi

# Section 4: Common Port Checks
echo -e "${GREEN}[Section 4] Checking Common Application Ports${NC}"
echo ""
echo -e "${CYAN}Common FeastFlow ports:${NC}"
echo "• 3000 - Next.js frontend (development)"
echo "• 3001 - Next.js frontend (production)"
echo "• 5000 - Backend API"
echo "• 5432 - PostgreSQL database"
echo "• 6379 - Redis cache"
echo "• 80   - HTTP (Nginx)"
echo "• 443  - HTTPS (Nginx)"
echo ""

COMMON_PORTS="3000 3001 5000 5432 6379 80 443"

for PORT in $COMMON_PORTS; do
    echo -e "${YELLOW}Checking port $PORT:${NC}"
    
    if command -v ss >/dev/null 2>&1; then
        if ss -tuln | grep -q ":$PORT "; then
            echo -e "${GREEN}✓ Port $PORT is LISTENING${NC}"
            if [ "$EUID" -eq 0 ]; then
                ss -tulpn | grep ":$PORT "
            fi
        else
            echo -e "${RED}✗ Port $PORT is NOT listening${NC}"
        fi
    elif command -v netstat >/dev/null 2>&1; then
        if netstat -tuln | grep -q ":$PORT "; then
            echo -e "${GREEN}✓ Port $PORT is LISTENING${NC}"
            if [ "$EUID" -eq 0 ]; then
                netstat -tulpn | grep ":$PORT "
            fi
        else
            echo -e "${RED}✗ Port $PORT is NOT listening${NC}"
        fi
    else
        echo -e "${YELLOW}Cannot check (no ss or netstat)${NC}"
    fi
    echo ""
done

# Section 5: Using lsof for port inspection
echo -e "${GREEN}[Section 5] Port Inspection with 'lsof'${NC}"
echo ""
echo -e "${CYAN}Why 'lsof' is powerful:${NC}"
echo "• 'lsof' = List Open Files (in Linux, sockets are files!)"
echo "• Shows exactly which process is using a specific port"
echo "• Helpful when getting 'port already in use' errors"
echo "• Can show all network connections for a process"
echo ""

if command -v lsof >/dev/null 2>&1; then
    echo -e "${YELLOW}Command: lsof -i :3000${NC}"
    echo "Explanation: Show what's using port 3000 (Next.js default)"
    echo ""
    
    if [ "$EUID" -eq 0 ]; then
        if lsof -i :3000 2>/dev/null; then
            echo ""
        else
            echo -e "${RED}No process listening on port 3000${NC}"
            echo ""
        fi
    else
        echo -e "${YELLOW}Need root access to see process details${NC}"
        echo "Try: sudo lsof -i :3000"
        echo ""
    fi
    
    echo -e "${YELLOW}Command: lsof -i -P -n | grep LISTEN | head -10${NC}"
    echo "Explanation: Show all listening ports (-P=no port names, -n=no host names)"
    echo ""
    if [ "$EUID" -eq 0 ]; then
        lsof -i -P -n 2>/dev/null | grep LISTEN | head -10 || echo "No listening ports found"
    else
        echo -e "${YELLOW}Run with sudo for full output: sudo lsof -i -P -n | grep LISTEN${NC}"
    fi
    echo ""
else
    echo -e "${RED}'lsof' command not available${NC}"
    echo "Install with: apt-get install lsof (Debian/Ubuntu) or yum install lsof (RHEL/CentOS)"
    echo ""
fi

# Section 6: Process Tree
echo -e "${GREEN}[Section 6] Process Tree with 'pstree'${NC}"
echo ""
echo -e "${CYAN}Why this matters:${NC}"
echo "• See parent-child relationships between processes"
echo "• Understand how your app spawns worker processes"
echo "• Identify orphaned processes"
echo ""

if command -v pstree >/dev/null 2>&1; then
    echo -e "${YELLOW}Command: pstree -p \$(whoami) | head -20${NC}"
    echo "Explanation: Show process tree for current user with PIDs"
    echo ""
    pstree -p "$(whoami)" 2>/dev/null | head -20 || pstree -p 2>/dev/null | head -20
    echo ""
else
    echo -e "${YELLOW}'pstree' not available, using 'ps' alternative${NC}"
    echo -e "${YELLOW}Command: ps auxf | head -20${NC}"
    ps auxf 2>/dev/null | head -20 || ps aux | head -20
    echo ""
fi

# Section 7: Real-World DevOps Scenarios
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Real-World DevOps Scenarios${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

echo -e "${YELLOW}Scenario 1: Service Not Starting${NC}"
echo "Error: 'Failed to start application on port 3000'"
echo ""
echo "Debug steps:"
echo "1. Check if port is already in use:"
echo "   $ ss -tuln | grep :3000"
echo "   or"
echo "   $ lsof -i :3000"
echo ""
echo "2. Find the process using it:"
echo "   $ lsof -i :3000 -t  # Get PID only"
echo ""
echo "3. Kill the conflicting process:"
echo "   $ kill \$(lsof -i :3000 -t)"
echo "   or for stubborn processes:"
echo "   $ kill -9 \$(lsof -i :3000 -t)"
echo ""

echo -e "${YELLOW}Scenario 2: High CPU Usage${NC}"
echo "Alert: 'Server CPU at 95%'"
echo ""
echo "Debug steps:"
echo "1. Find top CPU consumers:"
echo "   $ ps aux --sort=-%cpu | head -10"
echo ""
echo "2. Monitor specific process:"
echo "   $ top -p <PID>"
echo ""
echo "3. Check what the process is doing:"
echo "   $ strace -p <PID>"
echo ""

echo -e "${YELLOW}Scenario 3: Network Connection Issues${NC}"
echo "Error: 'Cannot connect to database on port 5432'"
echo ""
echo "Debug steps:"
echo "1. Check if database is listening:"
echo "   $ ss -tuln | grep :5432"
echo ""
echo "2. Check which interface it's bound to:"
echo "   $ ss -tulpn | grep :5432"
echo "   # If shows 127.0.0.1:5432 → only local connections"
echo "   # If shows 0.0.0.0:5432 → accepts external connections"
echo ""
echo "3. Test connection:"
echo "   $ telnet localhost 5432"
echo "   or"
echo "   $ nc -zv localhost 5432"
echo ""

echo -e "${YELLOW}Scenario 4: Zombie Processes${NC}"
echo "Issue: 'Many zombie processes accumulating'"
echo ""
echo "Debug steps:"
echo "1. Find zombie processes:"
echo "   $ ps aux | grep 'Z'"
echo ""
echo "2. Find parent of zombie:"
echo "   $ ps -o ppid= -p <zombie_PID>"
echo ""
echo "3. Restart or fix the parent process"
echo "   (Zombies can't be killed; fix the parent)"
echo ""

# Section 8: Useful Command Combinations
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Useful Command Combinations${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

echo "# Find all Node.js processes and their ports:"
echo "$ ps aux | grep node"
echo ""

echo "# Kill all processes on port 3000:"
echo "$ kill \$(lsof -t -i:3000)"
echo ""

echo "# Monitor network connections in real-time:"
echo "$ watch -n 1 'ss -tuln'"
echo ""

echo "# Find process by name and show open ports:"
echo "$ lsof -i -a -p \$(pgrep node)"
echo ""

echo "# Show established connections to your API:"
echo "$ ss -tn state established '( dport = :5000 or sport = :5000 )'"
echo ""

# Summary
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Key Takeaways${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "${GREEN}✓ ps aux${NC} - View all running processes"
echo -e "${GREEN}✓ ss -tulpn${NC} - Check listening ports and processes"
echo -e "${GREEN}✓ lsof -i :PORT${NC} - Find what's using a specific port"
echo -e "${GREEN}✓ netstat -tulpn${NC} - Alternative to ss (older systems)"
echo -e "${GREEN}✓ pstree${NC} - Visualize process relationships"
echo ""
echo "These commands are essential for:"
echo "• Debugging deployment failures"
echo "• Investigating performance issues"
echo "• Troubleshooting network connectivity"
echo "• Monitoring application health"
echo ""

echo -e "${GREEN}Process & network check complete!${NC}"
echo ""

exit 0
