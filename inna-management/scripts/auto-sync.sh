#!/bin/bash

# auto-sync.sh - Industry best practice: Automated sync with hooks
# This is the main entry point for all sync operations

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Usage
usage() {
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  push     - Push management files to database (default)"
    echo "  pull     - Pull database state to management files"
    echo "  verify   - Verify sync status"
    echo "  status   - Show current status"
    echo "  help     - Show this help"
    echo ""
    echo "Industry Best Practice: Always use 'push' for changes, 'pull' for recovery"
}

# Pre-hook: Always verify current state before any operation
pre_hook() {
    echo -e "${BLUE}🔍 Pre-hook: Verifying current state...${NC}"
    if ! "$SCRIPT_DIR/verify-sync.sh" >/dev/null 2>&1; then
        echo -e "${YELLOW}⚠️  Pre-hook: Sync issues detected, but continuing...${NC}"
    else
        echo -e "${GREEN}✅ Pre-hook: System in sync${NC}"
    fi
}

# Post-hook: Always verify after any operation
post_hook() {
    echo -e "${BLUE}🔍 Post-hook: Verifying operation success...${NC}"
    if "$SCRIPT_DIR/verify-sync.sh"; then
        echo -e "${GREEN}✅ Post-hook: Operation successful${NC}"
        return 0
    else
        echo -e "${RED}❌ Post-hook: Operation failed${NC}"
        return 1
    fi
}

# Push: Management files → Database
push() {
    echo -e "${BLUE}🚀 Pushing management files to database...${NC}"
    pre_hook
    "$SCRIPT_DIR/update-inna-safe.sh"
    post_hook
}

# Pull: Database → Management files
pull() {
    echo -e "${BLUE}📥 Pulling database state to management files...${NC}"
    pre_hook
    "$SCRIPT_DIR/sync-from-db.sh"
    post_hook
}

# Verify: Check sync status
verify() {
    echo -e "${BLUE}🔍 Verifying sync status...${NC}"
    "$SCRIPT_DIR/verify-sync.sh"
}

# Status: Show current status
status() {
    echo -e "${BLUE}📋 Current Status:${NC}"
    echo "Project: $PROJECT_DIR"
    echo "Scripts: $SCRIPT_DIR"
    echo ""
    
    # Check if Open WebUI is running
    if pgrep -f "uvicorn.*open_webui" >/dev/null; then
        echo -e "${GREEN}✅ Open WebUI: Running${NC}"
    else
        echo -e "${YELLOW}⚠️  Open WebUI: Not running${NC}"
    fi
    
    # Check database
    DB_PATH="/Users/287096/open-webui/backend/data/webui.db"
    if [ -f "$DB_PATH" ]; then
        echo -e "${GREEN}✅ Database: Available${NC}"
    else
        echo -e "${RED}❌ Database: Not found${NC}"
    fi
    
    # Check management files
    CONFIG_DIR="$PROJECT_DIR/configs"
    if [ -d "$CONFIG_DIR" ]; then
        echo -e "${GREEN}✅ Management files: Available${NC}"
    else
        echo -e "${RED}❌ Management files: Not found${NC}"
    fi
    
    echo ""
    verify
}

# Main logic
main() {
    local command="${1:-push}"
    
    case "$command" in
        push)
            push
            ;;
        pull)
            pull
            ;;
        verify)
            verify
            ;;
        status)
            status
            ;;
        help|--help|-h)
            usage
            ;;
        *)
            echo -e "${RED}❌ Unknown command: $command${NC}"
            usage
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"
