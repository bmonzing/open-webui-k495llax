#!/bin/bash

# Inna Model Update Script - Safe Version
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
    
    # Create a temporary Python script to safely update the JSON
    cat > /tmp/update_system_prompt.py << 'EOF'
import sqlite3
import json
import sys

db_path = sys.argv[1]
model_id = sys.argv[2]
config_file = sys.argv[3]

# Read the new system prompt
with open(config_file, 'r') as f:
    config = json.load(f)
    new_system_prompt = config['system']

# Connect to database
conn = sqlite3.connect(db_path)
cursor = conn.cursor()

# Get current params
cursor.execute("SELECT params FROM model WHERE id = ?", (model_id,))
result = cursor.fetchone()

if result:
    current_params = json.loads(result[0])
    current_params['system'] = new_system_prompt
    
    # Update with new params
    cursor.execute("UPDATE model SET params = ? WHERE id = ?", 
                   (json.dumps(current_params), model_id))
    conn.commit()
    print("SUCCESS: System prompt updated")
else:
    print("ERROR: Model not found")
    sys.exit(1)

conn.close()
EOF

    # Run the Python script
    python3 /tmp/update_system_prompt.py "$DB_PATH" "$MODEL_ID" "$CONFIG_DIR/system-prompt.json"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ System prompt updated${NC}"
    else
        echo -e "${RED}❌ Failed to update system prompt${NC}"
        exit 1
    fi
    
    # Clean up
    rm -f /tmp/update_system_prompt.py
else
    echo -e "${YELLOW}⚠️  No system-prompt.json file found, skipping system prompt update${NC}"
fi

# Update metadata if file exists
if [ -f "$CONFIG_DIR/metadata.json" ]; then
    echo -e "${YELLOW}📝 Updating metadata...${NC}"
    
    # Create a temporary Python script to safely update the metadata
    cat > /tmp/update_metadata.py << 'EOF'
import sqlite3
import json
import sys

db_path = sys.argv[1]
model_id = sys.argv[2]
config_file = sys.argv[3]

# Read the new metadata
with open(config_file, 'r') as f:
    new_metadata = json.load(f)

# Connect to database
conn = sqlite3.connect(db_path)
cursor = conn.cursor()

# Update metadata
cursor.execute("UPDATE model SET meta = ? WHERE id = ?", 
               (json.dumps(new_metadata), model_id))
conn.commit()

print("SUCCESS: Metadata updated")
conn.close()
EOF

    # Run the Python script
    python3 /tmp/update_metadata.py "$DB_PATH" "$MODEL_ID" "$CONFIG_DIR/metadata.json"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Metadata updated${NC}"
    else
        echo -e "${RED}❌ Failed to update metadata${NC}"
        exit 1
    fi
    
    # Clean up
    rm -f /tmp/update_metadata.py
else
    echo -e "${YELLOW}⚠️  No metadata.json file found, skipping metadata update${NC}"
fi

# Update the updated_at timestamp
CURRENT_TIME=$(date +%s)
sqlite3 "$DB_PATH" "UPDATE model SET updated_at = $CURRENT_TIME WHERE id = '$MODEL_ID';"

echo -e "${GREEN}✅ Inna model configuration updated successfully!${NC}"

# Auto-verify sync
echo -e "${YELLOW}🔍 Auto-verifying sync...${NC}"
if "$SCRIPT_DIR/verify-sync.sh"; then
    echo -e "${GREEN}✅ Sync verification passed${NC}"
else
    echo -e "${RED}❌ Sync verification failed${NC}"
    exit 1
fi

echo -e "${BLUE}💡 Changes are live in Open WebUI (no restart needed)${NC}"

# Show current configuration summary
echo -e "\n${BLUE}📋 Current Configuration Summary:${NC}"
echo "Model ID: $MODEL_ID"
echo "Name: $(sqlite3 "$DB_PATH" "SELECT name FROM model WHERE id = '$MODEL_ID';")"
echo "Description: $(sqlite3 "$DB_PATH" "SELECT json_extract(meta, '$.description') FROM model WHERE id = '$MODEL_ID';")"
echo "Function Calling: $(sqlite3 "$DB_PATH" "SELECT json_extract(params, '$.function_calling') FROM model WHERE id = '$MODEL_ID';")"
echo "Capabilities:"
sqlite3 "$DB_PATH" "SELECT json_extract(meta, '$.capabilities') FROM model WHERE id = '$MODEL_ID';" | jq -r 'to_entries[] | "  \(.key): \(.value)"'
