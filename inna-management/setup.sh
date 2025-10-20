#!/bin/bash

# Inna Management Setup Script
# Initializes the Inna model management system

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}🚀 Setting up Inna Model Management System${NC}"
echo ""

# Check if we're in the right directory
if [ ! -f "scripts/inna-manager.sh" ]; then
    echo -e "${YELLOW}⚠️  Please run this script from the inna-management directory${NC}"
    exit 1
fi

# Make all scripts executable
echo -e "${YELLOW}📝 Making scripts executable...${NC}"
chmod +x scripts/*.sh
chmod +x aliases.sh

# Create initial backup
echo -e "${YELLOW}📦 Creating initial backup...${NC}"
./scripts/inna-manager.sh backup

# Test the system
echo -e "${YELLOW}🧪 Testing the system...${NC}"
./scripts/inna-manager.sh status

echo ""
echo -e "${GREEN}✅ Setup complete!${NC}"
echo ""
echo -e "${BLUE}🎯 Quick Start:${NC}"
echo "  1. Open this workspace in Cursor:"
echo "     cursor inna-management.code-workspace"
echo ""
echo "  2. Edit configuration files:"
echo "     ./scripts/inna-manager.sh edit"
echo ""
echo "  3. Update the model:"
echo "     ./scripts/inna-manager.sh update"
echo ""
echo -e "${BLUE}📚 Available Commands:${NC}"
echo "  ./scripts/inna-manager.sh help    - Show all commands"
echo "  ./scripts/inna-manager.sh view    - View current config"
echo "  ./scripts/inna-manager.sh edit    - Edit config files"
echo "  ./scripts/inna-manager.sh update  - Apply changes"
echo "  ./scripts/inna-manager.sh backup  - Create backup"
echo "  ./scripts/inna-manager.sh status  - Show status"
echo ""
echo -e "${BLUE}🔗 Add to your shell profile:${NC}"
echo "  echo 'source $(pwd)/aliases.sh' >> ~/.zshrc"
echo "  source ~/.zshrc"
echo ""
echo -e "${GREEN}🎉 Ready to manage Inna!${NC}"
