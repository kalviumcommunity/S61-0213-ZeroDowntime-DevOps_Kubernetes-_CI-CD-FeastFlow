#!/bin/bash

################################################################################
# FeastFlow Permissions Demo Script
# Purpose: Demonstrate Linux file permissions and ownership for DevOps
# Safe to run: Uses /tmp directory only, no system-wide changes
################################################################################

set -e  # Exit on error

# Colors for output (POSIX-compatible)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Demo directory
DEMO_DIR="/tmp/feastflow-permissions-demo"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}FeastFlow Permissions Demo${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Cleanup previous demo if exists
if [ -d "$DEMO_DIR" ]; then
    echo -e "${YELLOW}[Cleanup] Removing existing demo directory...${NC}"
    rm -rf "$DEMO_DIR"
fi

# Step 1: Create demo directory structure
echo -e "${GREEN}[Step 1] Creating demo directory structure${NC}"
mkdir -p "$DEMO_DIR/etc/feastflow"
mkdir -p "$DEMO_DIR/var/log/feastflow"
mkdir -p "$DEMO_DIR/var/lib/feastflow"
echo "Created: $DEMO_DIR/etc/feastflow"
echo "Created: $DEMO_DIR/var/log/feastflow"
echo "Created: $DEMO_DIR/var/lib/feastflow"
echo ""

# Step 2: Create configuration file with sensitive data
echo -e "${GREEN}[Step 2] Creating configuration file with sensitive data${NC}"
CONFIG_FILE="$DEMO_DIR/etc/feastflow/database.conf"
cat > "$CONFIG_FILE" << 'EOF'
# FeastFlow Database Configuration
DB_HOST=localhost
DB_PORT=5432
DB_NAME=feastflow_prod
DB_USER=feastflow_app
DB_PASSWORD=super_secret_password_123
API_KEY=sk_live_abc123xyz789
EOF
echo "Created: $CONFIG_FILE"
echo "Content preview:"
head -3 "$CONFIG_FILE"
echo "..."
echo ""

# Step 3: Create log file
echo -e "${GREEN}[Step 3] Creating log file${NC}"
LOG_FILE="$DEMO_DIR/var/log/feastflow/application.log"
cat > "$LOG_FILE" << 'EOF'
2026-02-19 10:00:00 [INFO] FeastFlow application started
2026-02-19 10:00:01 [INFO] Database connection established
2026-02-19 10:00:02 [INFO] Server listening on port 3000
2026-02-19 10:05:30 [WARN] High memory usage detected: 85%
2026-02-19 10:10:15 [ERROR] Failed to process order #12345
EOF
echo "Created: $LOG_FILE"
echo ""

# Step 4: Create data file
echo -e "${GREEN}[Step 4] Creating application data file${NC}"
DATA_FILE="$DEMO_DIR/var/lib/feastflow/session_data.json"
echo '{"sessions": [], "cache": {}}' > "$DATA_FILE"
echo "Created: $DATA_FILE"
echo ""

# Step 5: Show initial permissions (INSECURE!)
echo -e "${YELLOW}[Step 5] Initial permissions (INSECURE - Everyone can read!)${NC}"
echo "Command: ls -la $DEMO_DIR/etc/feastflow/"
ls -la "$DEMO_DIR/etc/feastflow/"
echo ""
echo -e "${RED}⚠️  SECURITY ISSUE: Configuration file with passwords is world-readable!${NC}"
echo -e "${RED}⚠️  Anyone on the system can read: rw-r--r--${NC}"
echo ""

# Step 6: Demonstrate reading ls -l output
echo -e "${GREEN}[Step 6] Understanding 'ls -l' Output${NC}"
echo "Let's break down what we see:"
echo ""
ls -l "$CONFIG_FILE" | while read -r line; do
    echo "$line"
done
echo ""
echo "Format: [permissions] [links] [owner] [group] [size] [date] [filename]"
echo "  - First character: file type (- = file, d = directory, l = symlink)"
echo "  - Next 9 chars: permissions in triplets (owner, group, others)"
echo "  - Each triplet: r(read) w(write) x(execute)"
echo ""

# Step 7: Secure the configuration file
echo -e "${GREEN}[Step 7] Securing configuration file (chmod 600)${NC}"
echo "Command: chmod 600 $CONFIG_FILE"
chmod 600 "$CONFIG_FILE"
echo "Result:"
ls -l "$CONFIG_FILE"
echo ""
echo -e "${GREEN}✓ Now only the owner can read/write: rw-------${NC}"
echo "  Owner: read + write"
echo "  Group: no access"
echo "  Others: no access"
echo ""

# Step 8: Set appropriate log permissions
echo -e "${GREEN}[Step 8] Setting log file permissions (chmod 644)${NC}"
echo "Command: chmod 644 $LOG_FILE"
chmod 644 "$LOG_FILE"
echo "Result:"
ls -l "$LOG_FILE"
echo ""
echo -e "${GREEN}✓ Owner can write, others can read: rw-r--r--${NC}"
echo "  Owner: read + write (application writes logs)"
echo "  Group: read only (team members can view)"
echo "  Others: read only (monitoring tools can access)"
echo ""

# Step 9: Set directory permissions
echo -e "${GREEN}[Step 9] Setting directory permissions (chmod 755)${NC}"
echo "Command: chmod 755 $DEMO_DIR/var/log/feastflow"
chmod 755 "$DEMO_DIR/var/log/feastflow"
echo "Result:"
ls -ld "$DEMO_DIR/var/log/feastflow"
echo ""
echo -e "${GREEN}✓ Directory is navigable: rwxr-xr-x${NC}"
echo "  Owner: read + write + execute (can create/delete files)"
echo "  Group: read + execute (can list and enter directory)"
echo "  Others: read + execute (can list and enter directory)"
echo ""

# Step 10: Demonstrate chmod with symbolic notation
echo -e "${GREEN}[Step 10] Using symbolic notation (Alternative to numeric)${NC}"
echo "Command: chmod u=rw,g=r,o= $DATA_FILE"
chmod u=rw,g=r,o= "$DATA_FILE"
echo "Result:"
ls -l "$DATA_FILE"
echo ""
echo "Symbolic notation:"
echo "  u=rw (user/owner: read+write)"
echo "  g=r  (group: read only)"
echo "  o=   (others: no access)"
echo ""

# Step 11: Show all permissions in tree view
echo -e "${GREEN}[Step 11] Complete permission structure${NC}"
echo "Command: ls -lR $DEMO_DIR"
ls -lR "$DEMO_DIR"
echo ""

# Step 12: Demonstrate permission denied scenario
echo -e "${YELLOW}[Step 12] Simulating permission denied scenario${NC}"
TEST_FILE="$DEMO_DIR/etc/feastflow/readonly.conf"
echo "test data" > "$TEST_FILE"
chmod 000 "$TEST_FILE"
echo "Created file with no permissions: $TEST_FILE"
ls -l "$TEST_FILE"
echo ""
echo "Attempting to read (will fail):"
if cat "$TEST_FILE" 2>/dev/null; then
    echo "Unexpected success"
else
    echo -e "${RED}cat: $TEST_FILE: Permission denied${NC}"
    echo -e "${RED}^ This is what happens when application lacks read permissions!${NC}"
fi
echo ""

# Step 13: Fix the permission issue
echo -e "${GREEN}[Step 13] Fixing permission issue${NC}"
echo "Command: chmod 644 $TEST_FILE"
chmod 644 "$TEST_FILE"
echo "Now reading works:"
cat "$TEST_FILE"
echo ""

# Summary
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Summary: When to use each permission${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "${GREEN}600 (rw-------)${NC} - Secrets, private keys, password files"
echo -e "${GREEN}644 (rw-r--r--)${NC} - Log files, public configs, documentation"
echo -e "${GREEN}755 (rwxr-xr-x)${NC} - Directories, executable scripts"
echo -e "${GREEN}700 (rwx------)${NC} - Private directories, user-only executables"
echo ""

# DevOps scenarios
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}DevOps Scenarios${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "${YELLOW}Scenario 1: CI/CD Pipeline Fails${NC}"
echo "Error: 'Permission denied writing to /var/log/app.log'"
echo "Solution: chmod 644 /var/log/app.log (or chown to app user)"
echo ""
echo -e "${YELLOW}Scenario 2: Application Can't Start${NC}"
echo "Error: 'Cannot read configuration file'"
echo "Solution: chmod 640 /etc/app/config.conf (readable by app group)"
echo ""
echo -e "${YELLOW}Scenario 3: Security Audit Failure${NC}"
echo "Issue: 'Database password found in world-readable file'"
echo "Solution: chmod 600 /etc/app/database.conf (owner-only access)"
echo ""

# Cleanup note
echo -e "${GREEN}Demo complete!${NC}"
echo "Demo files created in: $DEMO_DIR"
echo "To cleanup: rm -rf $DEMO_DIR"
echo ""

exit 0
