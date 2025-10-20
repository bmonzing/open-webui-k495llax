#!/bin/bash

# setup-environments.sh - Set up multi-environment Open WebUI with Inna
# This script creates the complete multi-environment setup

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
BASE_DIR="/Users/287096/ai"
SHARED_DIR="$BASE_DIR/open-webui-shared"
ENVIRONMENTS=("dev" "test" "prod")
PORTS=(8080 8081 8082)

echo -e "${BLUE}🚀 Setting up Multi-Environment Open WebUI with Inna${NC}"

# Create shared directory structure
echo -e "${YELLOW}📁 Creating shared directory structure...${NC}"
mkdir -p "$SHARED_DIR"/{backend,src,build,static,node_modules,venv}
mkdir -p "$SHARED_DIR"/inna-management/{configs,scripts,backups}

# Create environment-specific directories
for env in "${ENVIRONMENTS[@]}"; do
    echo -e "${YELLOW}📁 Creating $env environment...${NC}"
    mkdir -p "$BASE_DIR/open-webui-$env/data"
    mkdir -p "$BASE_DIR/inna-management/configs/$env"
done

# Copy shared files (this would be done from the git repository)
echo -e "${YELLOW}📋 Setting up shared files...${NC}"
# Note: In real implementation, these would be copied from the git repo

# Create environment-specific symlinks
echo -e "${YELLOW}🔗 Creating environment symlinks...${NC}"
for env in "${ENVIRONMENTS[@]}"; do
    ENV_DIR="$BASE_DIR/open-webui-$env"
    
    # Create symlinks to shared directories
    ln -sf "$SHARED_DIR/backend" "$ENV_DIR/backend"
    ln -sf "$SHARED_DIR/src" "$ENV_DIR/src"
    ln -sf "$SHARED_DIR/build" "$ENV_DIR/build"
    ln -sf "$SHARED_DIR/static" "$ENV_DIR/static"
    ln -sf "$SHARED_DIR/node_modules" "$ENV_DIR/node_modules"
    ln -sf "$SHARED_DIR/venv" "$ENV_DIR/venv"
    
    echo -e "${GREEN}✅ Created symlinks for $env environment${NC}"
done

# Create environment startup scripts
echo -e "${YELLOW}📝 Creating environment startup scripts...${NC}"
for i in "${!ENVIRONMENTS[@]}"; do
    env="${ENVIRONMENTS[$i]}"
    port="${PORTS[$i]}"
    
    cat > "$BASE_DIR/start-open-webui-$env.sh" << EOF
#!/bin/bash
# Start Open WebUI $env environment

export ENV="$env"
export PORT="$port"
export DATA_DIR="$BASE_DIR/open-webui-$env/data"
export WEBUI_NAME="Open WebUI ($env)"

cd "$BASE_DIR/open-webui-shared/backend"
python -m uvicorn open_webui.main:app --host 0.0.0.0 --port $port
EOF
    
    chmod +x "$BASE_DIR/start-open-webui-$env.sh"
    echo -e "${GREEN}✅ Created startup script for $env environment${NC}"
done

# Create environment switching script
cat > "$BASE_DIR/switch-env.sh" << 'EOF'
#!/bin/bash
# Switch between Open WebUI environments

ENV=${1:-dev}

case $ENV in
    dev|test|prod)
        echo "🔄 Switching to $ENV environment..."
        export INNA_ENV="$ENV"
        export OPENWEBUI_ENV="$ENV"
        echo "✅ Switched to $ENV environment"
        echo "💡 Use 'start-open-webui-$ENV.sh' to start the environment"
        ;;
    *)
        echo "❌ Invalid environment. Use: dev, test, or prod"
        exit 1
        ;;
esac
EOF

chmod +x "$BASE_DIR/switch-env.sh"

echo -e "${GREEN}🎉 Multi-environment setup complete!${NC}"
echo -e "${BLUE}📋 Available commands:${NC}"
echo "  start-open-webui-dev.sh   - Start development environment"
echo "  start-open-webui-test.sh  - Start testing environment"
echo "  start-open-webui-prod.sh  - Start production environment"
echo "  switch-env.sh <env>        - Switch to environment (dev/test/prod)"
echo ""
echo -e "${YELLOW}💡 Next steps:${NC}"
echo "1. Copy your Open WebUI files to $SHARED_DIR"
echo "2. Set up your Inna configurations in each environment"
echo "3. Test each environment"
