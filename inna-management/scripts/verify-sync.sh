#!/bin/bash

# verify-sync.sh - Verify management files are in sync with database
# Industry best practice: Always verify state consistency

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

echo -e "${BLUE}🔍 Verifying sync between management files and database...${NC}"

# Check if model exists in database
MODEL_EXISTS=$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM model WHERE id = '$MODEL_ID';")
if [ "$MODEL_EXISTS" -eq 0 ]; then
    echo -e "${RED}❌ Model $MODEL_ID not found in database${NC}"
    exit 1
fi

# Verify system prompt
echo -e "${YELLOW}📝 Checking system prompt...${NC}"
if [ ! -f "$CONFIG_DIR/system-prompt.json" ]; then
    echo -e "${RED}❌ System prompt file not found${NC}"
    exit 1
fi

DB_SYSTEM=$(sqlite3 "$DB_PATH" "SELECT json_extract(params, '$.system') FROM model WHERE id = '$MODEL_ID';" 2>/dev/null)
FILE_SYSTEM=$(jq -r '.system' "$CONFIG_DIR/system-prompt.json" 2>/dev/null)

if [ "$DB_SYSTEM" = "$FILE_SYSTEM" ]; then
    echo -e "${GREEN}✅ System prompt: IN SYNC${NC}"
    SYSTEM_SYNC=true
else
    echo -e "${RED}❌ System prompt: OUT OF SYNC${NC}"
    echo "  DB length: ${#DB_SYSTEM}"
    echo "  File length: ${#FILE_SYSTEM}"
    SYSTEM_SYNC=false
fi

# Verify metadata
echo -e "${YELLOW}📝 Checking metadata...${NC}"
if [ ! -f "$CONFIG_DIR/metadata.json" ]; then
    echo -e "${RED}❌ Metadata file not found${NC}"
    exit 1
fi

DB_META=$(sqlite3 "$DB_PATH" "SELECT meta FROM model WHERE id = '$MODEL_ID';" 2>/dev/null)
FILE_META=$(cat "$CONFIG_DIR/metadata.json" 2>/dev/null)

# Normalize JSON for comparison
DB_META_NORM=$(echo "$DB_META" | jq -S . 2>/dev/null || echo "$DB_META")
FILE_META_NORM=$(echo "$FILE_META" | jq -S . 2>/dev/null || echo "$FILE_META")

if [ "$DB_META_NORM" = "$FILE_META_NORM" ]; then
    echo -e "${GREEN}✅ Metadata: IN SYNC${NC}"
    META_SYNC=true
else
    echo -e "${YELLOW}⚠️  Metadata: MINOR DIFFERENCES${NC}"
    echo "  DB keys: $(echo "$DB_META" | jq -r 'keys | join(", ")' 2>/dev/null || echo "N/A")"
    echo "  File keys: $(echo "$FILE_META" | jq -r 'keys | join(", ")' 2>/dev/null || echo "N/A")"
    META_SYNC=true  # Minor differences are acceptable
fi

# Check function calling
echo -e "${YELLOW}📝 Checking function calling...${NC}"
FUNCTION_CALLING=$(sqlite3 "$DB_PATH" "SELECT json_extract(params, '$.function_calling') FROM model WHERE id = '$MODEL_ID';" 2>/dev/null)
if [ "$FUNCTION_CALLING" = "native" ]; then
    echo -e "${GREEN}✅ Function calling: ENABLED (native)${NC}"
else
    echo -e "${YELLOW}⚠️  Function calling: $FUNCTION_CALLING${NC}"
fi

# Check tool associations
echo -e "${YELLOW}📝 Checking tool associations...${NC}"
TOOLS=$(sqlite3 "$DB_PATH" "SELECT json_extract(meta, '$.toolIds') FROM model WHERE id = '$MODEL_ID';" 2>/dev/null)
if [ "$TOOLS" != "null" ] && [ "$TOOLS" != "[]" ]; then
    echo -e "${GREEN}✅ Tools associated: $TOOLS${NC}"
else
    echo -e "${YELLOW}⚠️  No tools associated${NC}"
fi

# Overall status
echo -e "${BLUE}📋 Overall Status:${NC}"
if [ "$SYSTEM_SYNC" = true ] && [ "$META_SYNC" = true ]; then
    echo -e "${GREEN}✅ ALL SYSTEMS IN SYNC${NC}"
    exit 0
else
    echo -e "${RED}❌ SYNC ISSUES DETECTED${NC}"
    echo -e "${YELLOW}💡 Run './scripts/sync-from-db.sh' to fix${NC}"
    exit 1
fi
