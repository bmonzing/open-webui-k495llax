#!/bin/bash

# Inna Management Aliases
# Source this file to add convenient aliases for Inna model management

# Get the directory where this script is located
INNA_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Main management aliases - Industry Best Practice
alias inna='$INNA_DIR/scripts/auto-sync.sh status'
alias inna-sync='$INNA_DIR/scripts/auto-sync.sh'
alias inna-push='$INNA_DIR/scripts/auto-sync.sh push'
alias inna-pull='$INNA_DIR/scripts/auto-sync.sh pull'
alias inna-verify='$INNA_DIR/scripts/auto-sync.sh verify'
alias inna-status='$INNA_DIR/scripts/auto-sync.sh status'

# Legacy aliases (deprecated - use inna-sync instead)
alias inna-view='$INNA_DIR/scripts/inna-manager.sh view'
alias inna-edit='$INNA_DIR/scripts/inna-manager.sh edit'
alias inna-update='$INNA_DIR/scripts/auto-sync.sh push'
alias inna-backup='$INNA_DIR/scripts/inna-manager.sh backup'
alias inna-restore='$INNA_DIR/scripts/inna-manager.sh restore'

# Quick access to config files
alias inna-config='cd $INNA_DIR/configs'
alias inna-scripts='cd $INNA_DIR/scripts'
alias inna-backups='cd $INNA_DIR/backups'

# Database access aliases
alias inna-db='sqlite3 /Users/287096/open-webui/backend/data/webui.db'

echo "✅ Inna management aliases loaded! (Industry Best Practice)"
echo ""
echo "🚀 Primary Commands (Recommended):"
echo "  inna           - Show current status"
echo "  inna-sync      - Show sync options"
echo "  inna-push      - Push management files → database"
echo "  inna-pull      - Pull database → management files"
echo "  inna-verify    - Verify sync status"
echo "  inna-status    - Show detailed status"
echo ""
echo "Quick navigation:"
echo "  inna-config    - Go to configs directory"
echo "  inna-scripts   - Go to scripts directory"
echo "  inna-backups   - Go to backups directory"
echo "  inna-db        - Access database directly"
