#!/bin/bash

# Inna Model Update Script
# Safely updates the Inna (Persona-Test) model configuration with backup

set -e

# Configuration
DB_PATH="/Users/287096/open-webui/backend/data/webui.db"
MODEL_ID="inna-persona-test"
SCRIPT_DIR="$(dirname "$0")"
CONFIG_DIR="$(dirname "$SCRIPT_DIR")/configs"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔄 Updating Inna model configuration...${NC}"

# Check if database exists
if [ ! -f "$DB_PATH" ]; then
    echo -e "${RED}❌ Database not found at: $DB_PATH${NC}"
    exit 1
fi

# Check if model exists
if ! sqlite3 "$DB_PATH" "SELECT id FROM model WHERE id = '$MODEL_ID';" | grep -q "$MODEL_ID"; then
    echo -e "${RED}❌ Model '$MODEL_ID' not found in database${NC}"
    exit 1
fi

# Create backup before making changes
echo -e "${YELLOW}📦 Creating backup before update...${NC}"
"$SCRIPT_DIR/backup-inna.sh"

# Update system prompt if file exists and is different
if [ -f "$CONFIG_DIR/system-prompt.json" ]; then
    echo -e "${YELLOW}📝 Updating system prompt...${NC}"
    
    # Extract the system prompt from the JSON file
    SYSTEM_PROMPT=$(cat "$CONFIG_DIR/system-prompt.json" | jq -r '.system')
    
    if [ "$SYSTEM_PROMPT" != "null" ] && [ -n "$SYSTEM_PROMPT" ]; then
        sqlite3 "$DB_PATH" "UPDATE model SET params = json_set(params, '$.system', '$SYSTEM_PROMPT') WHERE id = '$MODEL_ID';"
        echo -e "${GREEN}✅ System prompt updated${NC}"
    else
        echo -e "${YELLOW}⚠️  System prompt file exists but no valid system prompt found${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  No system-prompt.json file found, skipping system prompt update${NC}"
fi

# Update metadata if file exists
if [ -f "$CONFIG_DIR/metadata.json" ]; then
    echo -e "${YELLOW}📝 Updating metadata...${NC}"
    
    # Read the metadata JSON and update the database
    METADATA_JSON=$(cat "$CONFIG_DIR/metadata.json")
    
    if [ -n "$METADATA_JSON" ]; then
        sqlite3 "$DB_PATH" "UPDATE model SET meta = '$METADATA_JSON' WHERE id = '$MODEL_ID';"
        echo -e "${GREEN}✅ Metadata updated${NC}"
    else
        echo -e "${YELLOW}⚠️  Metadata file exists but is empty${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  No metadata.json file found, skipping metadata update${NC}"
fi

# Update the updated_at timestamp
CURRENT_TIME=$(date +%s)
sqlite3 "$DB_PATH" "UPDATE model SET updated_at = $CURRENT_TIME WHERE id = '$MODEL_ID';"

echo -e "${GREEN}✅ Inna model configuration updated successfully!${NC}"
echo -e "${BLUE}💡 Restart Open WebUI to see the changes${NC}"

# Show current configuration summary
echo -e "\n${BLUE}📋 Current Configuration Summary:${NC}"
echo "Model ID: $MODEL_ID"
echo "Name: $(sqlite3 "$DB_PATH" "SELECT name FROM model WHERE id = '$MODEL_ID';")"
echo "Description: $(sqlite3 "$DB_PATH" "SELECT json_extract(meta, '$.description') FROM model WHERE id = '$MODEL_ID';")"
echo "Capabilities:"
sqlite3 "$DB_PATH" "SELECT json_extract(meta, '$.capabilities') FROM model WHERE id = '$MODEL_ID';" | jq -r 'to_entries[] | "  \(.key): \(.value)"'
