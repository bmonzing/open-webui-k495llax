#!/bin/bash

# sync-from-db.sh - Pull database state to management files
# Industry best practice: Always sync from source of truth

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
CONFIG_DIR="$PROJECT_DIR/configs"
DB_PATH="/Users/287096/open-webui/backend/data/webui.db"
MODEL_ID="inna-persona-test"

# Validation
if [ ! -f "$DB_PATH" ]; then
    echo -e "${RED}❌ Database not found at $DB_PATH${NC}"
    exit 1
fi

if [ ! -d "$CONFIG_DIR" ]; then
    echo -e "${RED}❌ Config directory not found at $CONFIG_DIR${NC}"
    exit 1
fi

echo -e "${BLUE}🔄 Syncing database state to management files...${NC}"

# Create backup before sync
BACKUP_DIR="$PROJECT_DIR/backups/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"
echo -e "${YELLOW}📦 Creating backup before sync...${NC}"

# Backup current management files
cp "$CONFIG_DIR/system-prompt.json" "$BACKUP_DIR/system-prompt-backup.json" 2>/dev/null || true
cp "$CONFIG_DIR/metadata.json" "$BACKUP_DIR/metadata-backup.json" 2>/dev/null || true

# Extract system prompt from database
echo -e "${YELLOW}📝 Extracting system prompt from database...${NC}"
SYSTEM_PROMPT=$(sqlite3 "$DB_PATH" "SELECT json_extract(params, '$.system') FROM model WHERE id = '$MODEL_ID';" 2>/dev/null)

if [ -z "$SYSTEM_PROMPT" ] || [ "$SYSTEM_PROMPT" = "null" ]; then
    echo -e "${RED}❌ No system prompt found in database for model $MODEL_ID${NC}"
    exit 1
fi

# Create system-prompt.json
cat > "$CONFIG_DIR/system-prompt.json" << EOF
{
    "system": $(echo "$SYSTEM_PROMPT" | jq -R .)
}
EOF

# Extract metadata from database
echo -e "${YELLOW}📝 Extracting metadata from database...${NC}"
METADATA=$(sqlite3 "$DB_PATH" "SELECT meta FROM model WHERE id = '$MODEL_ID';" 2>/dev/null)

if [ -z "$METADATA" ] || [ "$METADATA" = "null" ]; then
    echo -e "${YELLOW}⚠️  No metadata found in database for model $MODEL_ID${NC}"
    # Create minimal metadata
    cat > "$CONFIG_DIR/metadata.json" << EOF
{
    "profile_image_url": "/static/favicon.png",
    "description": "Product innovation specialist",
    "capabilities": {
        "vision": true,
        "file_upload": true,
        "web_search": false,
        "image_generation": false,
        "code_interpreter": true,
        "citations": false,
        "status_updates": false
    },
    "suggestion_prompts": [
        {"content": "I have an idea!"},
        {"content": "I have a problem."},
        {"content": "I want to make something better."},
        {"content": "I want to make something new."},
        {"content": "Can you help me with something?"}
    ],
    "tags": [],
    "toolIds": []
}
EOF
else
    # Create metadata.json from database
    echo "$METADATA" > "$CONFIG_DIR/metadata.json"
fi

# Verify sync
echo -e "${YELLOW}🔍 Verifying sync...${NC}"

# Check system prompt
DB_SYSTEM=$(sqlite3 "$DB_PATH" "SELECT json_extract(params, '$.system') FROM model WHERE id = '$MODEL_ID';")
FILE_SYSTEM=$(jq -r '.system' "$CONFIG_DIR/system-prompt.json")

if [ "$DB_SYSTEM" = "$FILE_SYSTEM" ]; then
    echo -e "${GREEN}✅ System prompt synced successfully${NC}"
else
    echo -e "${RED}❌ System prompt sync failed${NC}"
    echo "DB length: ${#DB_SYSTEM}"
    echo "File length: ${#FILE_SYSTEM}"
    exit 1
fi

# Check metadata
DB_META=$(sqlite3 "$DB_PATH" "SELECT meta FROM model WHERE id = '$MODEL_ID';")
FILE_META=$(cat "$CONFIG_DIR/metadata.json")

if [ "$DB_META" = "$FILE_META" ]; then
    echo -e "${GREEN}✅ Metadata synced successfully${NC}"
else
    echo -e "${YELLOW}⚠️  Metadata sync had minor differences (this may be normal)${NC}"
fi

echo -e "${GREEN}✅ Database state synced to management files successfully!${NC}"
echo -e "${BLUE}📁 Backup created at: $BACKUP_DIR${NC}"

# Show current state summary
echo -e "${BLUE}📋 Current State Summary:${NC}"
echo "Model ID: $MODEL_ID"
echo "System prompt length: ${#SYSTEM_PROMPT} characters"
echo "Metadata keys: $(echo "$METADATA" | jq -r 'keys | join(", ")' 2>/dev/null || echo "N/A")"
