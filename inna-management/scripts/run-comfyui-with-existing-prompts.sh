#!/bin/bash

# Run ComfyUI using the existing detailed prompts that Inna already generated
# This uses the sophisticated prompts from the prompt files, not simplified ones

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

echo -e "${BLUE}🎨 Running ComfyUI with Inna's existing detailed prompts...${NC}"

# Check if ComfyUI is running
if ! curl -s "$COMFY_URL/system_stats" > /dev/null 2>&1; then
    echo -e "${RED}❌ ComfyUI is not running at $COMFY_URL${NC}"
    echo "Please start ComfyUI first:"
    echo "cd /Users/287096/ai/ComfyUI && python main.py"
    exit 1
fi

# Extract project and batch from directory path
PROJECT=$(basename $(dirname $(dirname $(dirname "$PROJECT_DIR"))))
BATCH_ID=$(basename "$PROJECT_DIR")

echo -e "${YELLOW}📋 Project: $PROJECT${NC}"
echo -e "${YELLOW}📋 Batch: $BATCH_ID${NC}"

# Find all prompt files (these contain Inna's detailed prompts)
PROMPT_FILES=$(find "$PROJECT_DIR/prompts" -name "*.json" 2>/dev/null | sort)
if [ -z "$PROMPT_FILES" ]; then
    echo -e "${RED}❌ No prompt files found in $PROJECT_DIR/prompts${NC}"
    echo "These should contain Inna's detailed prompts. Let me check what's available..."
    find "$PROJECT_DIR" -name "*.json" | head -5
    exit 1
fi

echo -e "${GREEN}✅ Found $(echo "$PROMPT_FILES" | wc -l) detailed prompt files${NC}"

# Create Python script that uses the existing detailed prompts
cat > /tmp/use_existing_prompts.py << 'EOF'
import json
import os
import sys
import requests
import copy
from pathlib import Path

# Configuration
COMFY_URL = "http://127.0.0.1:8188"
WORKFLOW_PATH = "/Users/287096/ai/ComfyUI/workflows/line-art.json"

def load_workflow(path):
    with open(path, 'r') as f:
        return json.load(f)

def update_workflow_prompts_and_params(workflow, positive, negative, filename_prefix, resolution=None, sampler=None, checkpoint=None, loras=None, seed=None):
    # Update the workflow with the new parameters
    updated = copy.deepcopy(workflow)
    
    print(f"  Using detailed positive prompt: {positive[:100]}...")
    print(f"  Using negative prompt: {negative[:100]}...")
    
    # Update text prompts
    for node_id, node in updated.items():
        if node.get("class_type") == "CLIPTextEncode":
            current_text = node.get("inputs", {}).get("text", "")
            
            if "varied line weight" in current_text or "bold outer contours" in current_text:
                print(f"  -> Updating POSITIVE prompt in node {node_id}")
                node["inputs"]["text"] = positive
            elif "color, gradients" in current_text or "shading, shadows" in current_text:
                print(f"  -> Updating NEGATIVE prompt in node {node_id}")
                node["inputs"]["text"] = negative
    
    # Update other parameters
    for node_id, node in updated.items():
        if node.get("class_type") == "KSampler":
            if seed is not None:
                node["inputs"]["seed"] = seed
            if sampler:
                for key, value in sampler.items():
                    if key in node["inputs"]:
                        node["inputs"][key] = value
    
    for node_id, node in updated.items():
        if node.get("class_type") == "EmptyLatentImage":
            if resolution:
                node["inputs"]["width"] = resolution["width"]
                node["inputs"]["height"] = resolution["height"]
    
    for node_id, node in updated.items():
        if node.get("class_type") == "SaveImage":
            node["inputs"]["filename_prefix"] = filename_prefix
    
    return updated

def submit_to_comfy(comfy_url, workflow):
    payload = {
        "prompt": workflow,
        "client_id": f"inna-detailed-{hash(str(workflow)) % 10000}"
    }
    
    response = requests.post(f"{comfy_url}/prompt", json=payload)
    response.raise_for_status()
    return response.json()

def main():
    if len(sys.argv) != 4:
        print("Usage: python use_existing_prompts.py <project_dir> <project> <batch_id>")
        sys.exit(1)
    
    project_dir = sys.argv[1]
    project = sys.argv[2]
    batch_id = sys.argv[3]
    
    # Find prompt files
    prompt_files = list(Path(project_dir).glob("prompts/*.json"))
    
    if not prompt_files:
        print("No prompt files found in prompts/ directory")
        sys.exit(1)
    
    print(f"Found {len(prompt_files)} detailed prompt files")
    
    # Load workflow
    workflow_template = load_workflow(WORKFLOW_PATH)
    
    # Process each prompt file
    jobs = []
    for prompt_file in sorted(prompt_files):
        with open(prompt_file, 'r') as f:
            prompt_data = json.load(f)
        
        pid = prompt_data["id"]
        composed = prompt_data["composed"]
        spec = prompt_data["spec"]
        
        print(f"Processing {pid}...")
        print(f"  Persona prompt: {spec['persona_prompt'][:100]}...")
        
        # Use the detailed prompts that Inna generated
        positive_full = composed["positive"]
        negative_full = composed["negative"]
        
        # Get render settings from the spec
        render = spec["render"]
        seed = render["seed"]
        
        # Update workflow
        workflow = update_workflow_prompts_and_params(
            workflow_template,
            positive_full,
            negative_full,
            filename_prefix=pid,
            resolution={"width": render["width"], "height": render["height"]},
            sampler={
                "steps": render["steps"],
                "cfg": render["cfg"],
                "sampler_name": "dpmpp_2m",
                "scheduler": "karras"
            },
            seed=seed
        )
        
        # Submit to ComfyUI
        try:
            response = submit_to_comfy(COMFY_URL, workflow)
            jobs.append({"id": pid, "submit": "ok", "response": response})
            print(f"  ✅ Submitted successfully (ID: {response.get('prompt_id', 'unknown')})")
        except Exception as e:
            jobs.append({"id": pid, "submit": "error", "error": str(e)})
            print(f"  ❌ Failed to submit: {e}")
    
    # Save job summary
    summary = {
        "project": project,
        "batch_id": batch_id,
        "jobs": jobs,
        "style": "single_line_bw",
        "note": "Used existing detailed prompts from Inna's tool"
    }
    
    summary_file = Path(project_dir) / "detailed_prompts_comfyui_jobs.json"
    with open(summary_file, 'w') as f:
        json.dump(summary, f, indent=2)
    
    print(f"\nJob summary saved to: {summary_file}")
    print(f"Successfully submitted: {sum(1 for j in jobs if j['submit'] == 'ok')}/{len(jobs)} jobs")

if __name__ == "__main__":
    main()
EOF

# Run the Python script
echo -e "${YELLOW}🔄 Using Inna's detailed prompts and submitting to ComfyUI...${NC}"
python3 /tmp/use_existing_prompts.py "$PROJECT_DIR" "$PROJECT" "$BATCH_ID"

if [ $? -eq 0 ]; then
    echo -e "\n${GREEN}🎉 ComfyUI workflow triggered with detailed prompts!${NC}"
    echo -e "${BLUE}💡 These should now be proper line art images with detailed descriptions${NC}"
    echo -e "${BLUE}📁 Output directory: /Users/287096/ai/ComfyUI/output${NC}"
    
    # Show current queue status
    echo -e "\n${YELLOW}📊 Current ComfyUI queue status:${NC}"
    curl -s "$COMFY_URL/queue" | jq -r '.queue_pending[] | "  \(.prompt_id): \(.status)"' 2>/dev/null || echo "  No pending jobs"
else
    echo -e "\n${RED}❌ Failed to trigger ComfyUI workflow${NC}"
    exit 1
fi

# Clean up
rm -f /tmp/use_existing_prompts.py
