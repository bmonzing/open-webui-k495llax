#!/bin/bash

# Run ComfyUI for existing personas using Inna's actual tool
# Reconstructs the original data and calls step3_finalize_and_pipeline

set -e

# Configuration
PROJECT_DIR="$1"
COMFY_URL="http://127.0.0.1:8188"
WORKFLOW_PATH="/Users/287096/ai/ComfyUI/workflows/line-art.json"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

if [ -z "$PROJECT_DIR" ]; then
    echo -e "${RED}❌ Usage: $0 <project_directory>${NC}"
    echo "Example: $0 /Users/287096/ai/persona_system/projects/telecom-service-now/step3/approved/batch-1"
    exit 1
fi

if [ ! -d "$PROJECT_DIR" ]; then
    echo -e "${RED}❌ Directory not found: $PROJECT_DIR${NC}"
    exit 1
fi

echo -e "${BLUE}🎨 Running ComfyUI for existing personas using Inna's tool...${NC}"

# Check if ComfyUI is running
if ! curl -s "$COMFY_URL/system_stats" > /dev/null 2>&1; then
    echo -e "${RED}❌ ComfyUI is not running at $COMFY_URL${NC}"
    echo "Please start ComfyUI first:"
    echo "cd /Users/287096/ai/ComfyUI && python main.py"
    exit 1
fi

# Check if workflow exists
if [ ! -f "$WORKFLOW_PATH" ]; then
    echo -e "${RED}❌ Workflow not found: $WORKFLOW_PATH${NC}"
    exit 1
fi

# Extract project and batch from directory path
PROJECT=$(basename $(dirname $(dirname $(dirname "$PROJECT_DIR"))))
BATCH_ID=$(basename "$PROJECT_DIR")

echo -e "${YELLOW}📋 Project: $PROJECT${NC}"
echo -e "${YELLOW}📋 Batch: $BATCH_ID${NC}"

# Find all persona files
PERSONA_FILES=$(find "$PROJECT_DIR" -name "proto-persona-*.json" | sort)
if [ -z "$PERSONA_FILES" ]; then
    echo -e "${RED}❌ No persona files found in $PROJECT_DIR${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Found $(echo "$PERSONA_FILES" | wc -l) persona files${NC}"

# Create Python script to call Inna's tool
cat > /tmp/run_comfyui_tool.py << 'EOF'
import sys
import json
import os
import sqlite3
from pathlib import Path

# Add Open WebUI to path
sys.path.append('/Users/287096/open-webui/backend')

def load_tool_module():
    """Load the step3_finalize_and_pipeline tool module"""
    try:
        from open_webui.utils.plugin import load_tool_module_by_id
        module, _ = load_tool_module_by_id("step3_finalize_and_pipeline")
        return module
    except Exception as e:
        print(f"Error loading tool module: {e}")
        return None

def reconstruct_persona_data(persona_file):
    """Reconstruct the original persona data from the saved file"""
    with open(persona_file, 'r') as f:
        data = json.load(f)
    
    # Extract the persona data
    persona = data['persona']
    
    # Reconstruct the original format
    return {
        "id": persona["id"],
        "name": persona["name"],
        "job_title": persona["job_title"],
        "quotation": persona["quotation"],
        "demographics": persona["demographics"],
        "behaviors": persona["behaviors"],
        "needs_wants": persona["needs_wants"]
    }

def main():
    if len(sys.argv) != 4:
        print("Usage: python run_comfyui_tool.py <project_dir> <project> <batch_id>")
        sys.exit(1)
    
    project_dir = sys.argv[1]
    project = sys.argv[2]
    batch_id = sys.argv[3]
    
    # Find persona files
    persona_files = list(Path(project_dir).glob("proto-persona-*.json"))
    
    if not persona_files:
        print("No persona files found")
        sys.exit(1)
    
    print(f"Found {len(persona_files)} persona files")
    
    # Reconstruct the original data structure
    approved_personas = []
    for persona_file in sorted(persona_files):
        persona_data = reconstruct_persona_data(persona_file)
        approved_personas.append(persona_data)
        print(f"  - {persona_data['name']} ({persona_data['job_title']})")
    
    # Create the data structure that Inna's tool expects
    data = {
        "final": True,
        "project": project,
        "batch_id": batch_id,
        "approved_personas": approved_personas
    }
    
    print(f"\nReconstructed data for project '{project}', batch '{batch_id}'")
    print(f"Personas: {len(approved_personas)}")
    
    # Load the tool module
    tool_module = load_tool_module()
    if not tool_module:
        print("Failed to load tool module")
        sys.exit(1)
    
    # Call the tool
    print("\nCalling step3_finalize_and_pipeline tool...")
    try:
        result = tool_module.step3_finalize_and_pipeline(
            data=data,
            workflow_path="/Users/287096/ai/ComfyUI/workflows/line-art.json"
        )
        
        print("✅ Tool executed successfully!")
        print(f"Result: {json.dumps(result, indent=2)}")
        
    except Exception as e:
        print(f"❌ Tool execution failed: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)

if __name__ == "__main__":
    main()
EOF

# Run the Python script
echo -e "${YELLOW}🔄 Reconstructing data and calling Inna's tool...${NC}"
python3 /tmp/run_comfyui_tool.py "$PROJECT_DIR" "$PROJECT" "$BATCH_ID"

if [ $? -eq 0 ]; then
    echo -e "\n${GREEN}🎉 ComfyUI workflow triggered successfully!${NC}"
    echo -e "${BLUE}💡 Check ComfyUI output directory for generated images${NC}"
    echo -e "${BLUE}📁 Output directory: /Users/287096/ai/ComfyUI/output${NC}"
    
    # Show current queue status
    echo -e "\n${YELLOW}📊 Current ComfyUI queue status:${NC}"
    curl -s "$COMFY_URL/queue" | jq -r '.queue_pending[] | "  \(.prompt_id): \(.status)"' 2>/dev/null || echo "  No pending jobs"
else
    echo -e "\n${RED}❌ Failed to trigger ComfyUI workflow${NC}"
    exit 1
fi

# Clean up
rm -f /tmp/run_comfyui_tool.py
