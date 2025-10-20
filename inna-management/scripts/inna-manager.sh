#!/bin/bash

# Inna Model Manager - Quick Access Script
# Provides easy access to common Inna model operations

set -e

# Configuration
DB_PATH="/Users/287096/open-webui/backend/data/webui.db"
MODEL_ID="inna-persona-test"
SCRIPT_DIR="$(dirname "$0")"
CONFIG_DIR="$(dirname "$SCRIPT_DIR")/configs"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

show_help() {
    echo -e "${BLUE}Inna Model Manager${NC}"
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  backup     - Create a backup of current configuration"
    echo "  update     - Update model from config files"
    echo "  view       - View current configuration"
    echo "  edit       - Open config files in Cursor"
    echo "  status     - Show model status and capabilities"
    echo "  restore    - Restore from latest backup"
    echo "  help       - Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 backup"
    echo "  $0 edit"
    echo "  $0 update"
}

backup_model() {
    echo -e "${YELLOW}📦 Creating backup...${NC}"
    "$SCRIPT_DIR/backup-inna.sh"
}

update_model() {
    echo -e "${YELLOW}🔄 Updating model...${NC}"
    "$SCRIPT_DIR/update-inna.sh"
}

view_config() {
    echo -e "${BLUE}📋 Current Inna Model Configuration:${NC}"
    echo ""
    
    # Basic info
    echo -e "${PURPLE}Basic Information:${NC}"
    sqlite3 "$DB_PATH" "SELECT 'ID: ' || id, 'Name: ' || name, 'Active: ' || is_active FROM model WHERE id = '$MODEL_ID';"
    echo ""
    
    # Description
    echo -e "${PURPLE}Description:${NC}"
    sqlite3 "$DB_PATH" "SELECT json_extract(meta, '$.description') FROM model WHERE id = '$MODEL_ID';"
    echo ""
    
    # Capabilities
    echo -e "${PURPLE}Capabilities:${NC}"
    sqlite3 "$DB_PATH" "SELECT json_extract(meta, '$.capabilities') FROM model WHERE id = '$MODEL_ID';" | jq -r 'to_entries[] | "  \(.key): \(.value)"'
    echo ""
    
    # Suggestion prompts
    echo -e "${PURPLE}Suggestion Prompts:${NC}"
    sqlite3 "$DB_PATH" "SELECT json_extract(meta, '$.suggestion_prompts') FROM model WHERE id = '$MODEL_ID';" | jq -r '.[].content' | sed 's/^/  - /'
    echo ""
    
    # Tools
    echo -e "${PURPLE}Tools:${NC}"
    sqlite3 "$DB_PATH" "SELECT json_extract(meta, '$.toolIds') FROM model WHERE id = '$MODEL_ID';" | jq -r '.[]' | sed 's/^/  - /'
    echo ""
    
    # System prompt preview (first 200 chars)
    echo -e "${PURPLE}System Prompt Preview:${NC}"
    sqlite3 "$DB_PATH" "SELECT json_extract(params, '$.system') FROM model WHERE id = '$MODEL_ID';" | head -c 200
    echo "..."
    echo ""
}

edit_config() {
    echo -e "${YELLOW}📝 Opening config files in Cursor...${NC}"
    
    # Open the config directory in Cursor
    if command -v cursor &> /dev/null; then
        cursor "$CONFIG_DIR"
    else
        echo -e "${YELLOW}⚠️  Cursor command not found. Opening directory in Finder...${NC}"
        open "$CONFIG_DIR"
    fi
    
    echo -e "${GREEN}✅ Config files opened. Edit them and run '$0 update' to apply changes.${NC}"
}

show_status() {
    echo -e "${BLUE}📊 Inna Model Status:${NC}"
    echo ""
    
    # Check if model exists
    if sqlite3 "$DB_PATH" "SELECT id FROM model WHERE id = '$MODEL_ID';" | grep -q "$MODEL_ID"; then
        echo -e "${GREEN}✅ Model exists and is active${NC}"
    else
        echo -e "${RED}❌ Model not found${NC}"
        return 1
    fi
    
    # Show last updated
    LAST_UPDATED=$(sqlite3 "$DB_PATH" "SELECT datetime(updated_at, 'unixepoch') FROM model WHERE id = '$MODEL_ID';")
    echo "Last updated: $LAST_UPDATED"
    
    # Show config file status
    echo ""
    echo -e "${PURPLE}Config Files:${NC}"
    if [ -f "$CONFIG_DIR/system-prompt.json" ]; then
        echo -e "  ${GREEN}✅${NC} system-prompt.json"
    else
        echo -e "  ${RED}❌${NC} system-prompt.json"
    fi
    
    if [ -f "$CONFIG_DIR/metadata.json" ]; then
        echo -e "  ${GREEN}✅${NC} metadata.json"
    else
        echo -e "  ${RED}❌${NC} metadata.json"
    fi
    
    # Show backup status
    echo ""
    echo -e "${PURPLE}Recent Backups:${NC}"
    BACKUP_DIR="$(dirname "$SCRIPT_DIR")/backups"
    if [ -d "$BACKUP_DIR" ]; then
        ls -lt "$BACKUP_DIR"/inna-complete-config-*.json 2>/dev/null | head -3 | while read line; do
            echo "  $line"
        done
    else
        echo "  No backups found"
    fi
}

restore_model() {
    echo -e "${YELLOW}🔄 Restoring from latest backup...${NC}"
    
    BACKUP_DIR="$(dirname "$SCRIPT_DIR")/backups"
    LATEST_BACKUP=$(ls -t "$BACKUP_DIR"/inna-complete-config-*.json 2>/dev/null | head -1)
    
    if [ -z "$LATEST_BACKUP" ]; then
        echo -e "${RED}❌ No backups found${NC}"
        return 1
    fi
    
    echo "Using backup: $LATEST_BACKUP"
    
    # Create a backup before restoring
    backup_model
    
    # Extract and restore the configuration
    SYSTEM_PROMPT=$(jq -r '.system_prompt.system' "$LATEST_BACKUP")
    METADATA=$(jq -r '.metadata' "$LATEST_BACKUP")
    
    sqlite3 "$DB_PATH" "UPDATE model SET params = '$SYSTEM_PROMPT' WHERE id = '$MODEL_ID';"
    sqlite3 "$DB_PATH" "UPDATE model SET meta = '$METADATA' WHERE id = '$MODEL_ID';"
    
    echo -e "${GREEN}✅ Model restored from backup${NC}"
}

# Main command handling
case "${1:-help}" in
    backup)
        backup_model
        ;;
    update)
        update_model
        ;;
    view)
        view_config
        ;;
    edit)
        edit_config
        ;;
    status)
        show_status
        ;;
    restore)
        restore_model
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo -e "${RED}❌ Unknown command: $1${NC}"
        echo ""
        show_help
        exit 1
        ;;
esac
