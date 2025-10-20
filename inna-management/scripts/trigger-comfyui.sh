#!/bin/bash

# Trigger ComfyUI workflow for existing personas
# Manually runs the ComfyUI workflow for personas that were created without ComfyUI running

set -e

# Configuration
PROJECT_DIR="$1"
COMFY_URL="http://127.0.0.1:8188"
WORKFLOW_PATH="/Users/287096/ai/ComfyUI/workflows/line-art.json"
STYLE_PRESET="single_line_bw"
SEED_BASE=123456789

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

echo -e "${BLUE}🎨 Triggering ComfyUI workflow for personas in: $PROJECT_DIR${NC}"

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

# Find all persona files
PERSONA_FILES=$(find "$PROJECT_DIR" -name "proto-persona-*.json" | sort)
if [ -z "$PERSONA_FILES" ]; then
    echo -e "${RED}❌ No persona files found in $PROJECT_DIR${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Found $(echo "$PERSONA_FILES" | wc -l) persona files${NC}"

# Process each persona
for persona_file in $PERSONA_FILES; do
    echo -e "\n${YELLOW}📝 Processing: $(basename "$persona_file")${NC}"
    
    # Extract persona ID
    PERSONA_ID=$(jq -r '.persona.id' "$persona_file")
    PERSONA_NAME=$(jq -r '.persona.name' "$persona_file")
    JOB_TITLE=$(jq -r '.persona.job_title' "$persona_file")
    
    echo "  Persona: $PERSONA_NAME ($JOB_TITLE)"
    
    # Create image prompt based on persona data
    QUOTATION=$(jq -r '.persona.quotation' "$persona_file")
    DEMOGRAPHICS=$(jq -r '.persona.demographics | join(", ")' "$persona_file")
    BEHAVIORS=$(jq -r '.persona.behaviors | join(", ")' "$persona_file")
    NEEDS_WANTS=$(jq -r '.persona.needs_wants | join(", ")' "$persona_file")
    
    # Create the image prompt
    IMAGE_PROMPT="IMPORTANT: varied line weight—bold outer contours, delicate details, crisp black line drawing on pure white. subtle line-weight variation: slightly thicker outer contour, finer internal accents; confident, clean stroke; flat lines only, no shading. eye-level, slightly angled view. $PERSONA_NAME, $JOB_TITLE, seated at a desk; professional posture; focused expression; $DEMOGRAPHICS; business attire. composition center-left, person dominant, abundant negative space. minimal environment with the same line style: simple desk and ergonomic chair, work tools; wall hints (professional certificates, whiteboard); personal touches (coffee mug, plant). environment strictly secondary, fewer lines than the person; no text."
    
    # Create a modified workflow with the persona-specific prompt
    TEMP_WORKFLOW="/tmp/workflow_${PERSONA_ID}.json"
    jq --arg prompt "$IMAGE_PROMPT" --arg seed $((SEED_BASE + $(echo "$PERSONA_ID" | wc -c))) \
       '.10.inputs.text = $prompt | .12.inputs.seed = ($seed | tonumber)' \
       "$WORKFLOW_PATH" > "$TEMP_WORKFLOW"
    
    # Submit to ComfyUI
    echo "  Submitting to ComfyUI..."
    
    # Create the queue payload
    QUEUE_PAYLOAD=$(cat << EOF
{
    "prompt": $(cat "$TEMP_WORKFLOW"),
    "client_id": "inna-trigger-$(date +%s)"
}
EOF
)
    
    # Submit the job
    RESPONSE=$(curl -s -X POST "$COMFY_URL/prompt" \
        -H "Content-Type: application/json" \
        -d "$QUEUE_PAYLOAD")
    
    # Check if submission was successful
    if echo "$RESPONSE" | jq -e '.prompt_id' > /dev/null 2>&1; then
        PROMPT_ID=$(echo "$RESPONSE" | jq -r '.prompt_id')
        echo -e "  ${GREEN}✅ Job submitted successfully (ID: $PROMPT_ID)${NC}"
        
        # Save the prompt ID for reference
        echo "$PROMPT_ID" > "$PROJECT_DIR/prompts/${PERSONA_ID}_prompt_id.txt"
    else
        echo -e "  ${RED}❌ Failed to submit job${NC}"
        echo "  Response: $RESPONSE"
    fi
    
    # Clean up temp file
    rm -f "$TEMP_WORKFLOW"
done

echo -e "\n${GREEN}🎉 ComfyUI workflow triggered for all personas!${NC}"
echo -e "${BLUE}💡 Check ComfyUI output directory for generated images${NC}"
echo -e "${BLUE}📁 Output directory: /Users/287096/ai/ComfyUI/output${NC}"

# Show current queue status
echo -e "\n${YELLOW}📊 Current ComfyUI queue status:${NC}"
curl -s "$COMFY_URL/queue" | jq -r '.queue_pending[] | "  \(.prompt_id): \(.status)"' 2>/dev/null || echo "  No pending jobs"
