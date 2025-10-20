#!/bin/bash

# Inna Model Backup Script
# Creates timestamped backups of the Inna (Persona-Test) model configuration

set -e

# Configuration
DB_PATH="/Users/287096/open-webui/backend/data/webui.db"
BACKUP_DIR="$(dirname "$0")/../backups"
MODEL_ID="inna-persona-test"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

echo "🔄 Creating backup for Inna model..."

# Create full model backup
sqlite3 "$DB_PATH" "SELECT * FROM model WHERE id = '$MODEL_ID';" > "$BACKUP_DIR/inna-model-full-$TIMESTAMP.sql"

# Create JSON-formatted backups for easy editing
sqlite3 "$DB_PATH" "SELECT json_pretty(params) FROM model WHERE id = '$MODEL_ID';" > "$BACKUP_DIR/inna-system-prompt-$TIMESTAMP.json"
sqlite3 "$DB_PATH" "SELECT json_pretty(meta) FROM model WHERE id = '$MODEL_ID';" > "$BACKUP_DIR/inna-metadata-$TIMESTAMP.json"

# Create a complete configuration backup
cat > "$BACKUP_DIR/inna-complete-config-$TIMESTAMP.json" << EOF
{
  "model_id": "$MODEL_ID",
  "timestamp": "$TIMESTAMP",
  "system_prompt": $(sqlite3 "$DB_PATH" "SELECT params FROM model WHERE id = '$MODEL_ID';"),
  "metadata": $(sqlite3 "$DB_PATH" "SELECT meta FROM model WHERE id = '$MODEL_ID';"),
  "access_control": $(sqlite3 "$DB_PATH" "SELECT access_control FROM model WHERE id = '$MODEL_ID';"),
  "is_active": $(sqlite3 "$DB_PATH" "SELECT is_active FROM model WHERE id = '$MODEL_ID';"),
  "created_at": $(sqlite3 "$DB_PATH" "SELECT created_at FROM model WHERE id = '$MODEL_ID';"),
  "updated_at": $(sqlite3 "$DB_PATH" "SELECT updated_at FROM model WHERE id = '$MODEL_ID';")
}
EOF

echo "✅ Backup created successfully!"
echo "📁 Backup files:"
echo "   - Full model: $BACKUP_DIR/inna-model-full-$TIMESTAMP.sql"
echo "   - System prompt: $BACKUP_DIR/inna-system-prompt-$TIMESTAMP.json"
echo "   - Metadata: $BACKUP_DIR/inna-metadata-$TIMESTAMP.json"
echo "   - Complete config: $BACKUP_DIR/inna-complete-config-$TIMESTAMP.json"

# Keep only the last 10 backups
cd "$BACKUP_DIR"
ls -t inna-model-full-*.sql | tail -n +11 | xargs -r rm
ls -t inna-system-prompt-*.json | tail -n +11 | xargs -r rm
ls -t inna-metadata-*.json | tail -n +11 | xargs -r rm
ls -t inna-complete-config-*.json | tail -n +11 | xargs -r rm

echo "🧹 Cleaned up old backups (keeping last 10)"
