#!/bin/bash

# Fixed version: Correctly updates the workflow prompts

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

echo -e "${BLUE}🎨 Running ComfyUI for existing personas (FIXED VERSION)...${NC}"

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

# Find all persona files
PERSONA_FILES=$(find "$PROJECT_DIR" -name "proto-persona-*.json" | sort)
if [ -z "$PERSONA_FILES" ]; then
    echo -e "${RED}❌ No persona files found in $PROJECT_DIR${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Found $(echo "$PERSONA_FILES" | wc -l) persona files${NC}"

# Create Python script with FIXED workflow update logic
cat > /tmp/fixed_comfyui.py << 'EOF'
import json
import os
import sys
import requests
import hashlib
import copy
from pathlib import Path

# Configuration
COMFY_URL = "http://127.0.0.1:8188"
WORKFLOW_PATH = "/Users/287096/ai/ComfyUI/workflows/line-art.json"

# Style presets (copied from the tool)
STYLE_PRESETS = {
    "single_line_bw": {
        "positive_prefix": "IMPORTANT: varied line weight—bold outer contours, delicate details, crisp black line drawing on pure white. subtle line-weight variation: slightly thicker outer contour, finer internal accents; confident, clean stroke; flat lines only, no shading. eye-level, slightly angled view.",
        "negative": "color, gradients, shading, shadows, cross-hatching, texture, lighting, 3D, blur, noise, text, words, logos, watermarks, signatures, clutter, busy background, complex scene, photorealism, painterly, hatching, stippling, tone, drop shadows",
        "sampler": {
            "steps": 24,
            "cfg": 5.0,
            "sampler_name": "dpmpp_2m",
            "scheduler": "karras",
            "seed_mode": "per_persona",
        },
        "resolution": {"width": 1024, "height": 1024},
        "checkpoint": "sd_xl_base_1.0.safetensors",
        "loras": [
            {
                "path": "Line_Art_SDXL.safetensors",
                "strength_model": 0.5,
                "strength_clip": 0.5,
            }
        ],
    }
}

def persona_hash_seed(pid, seed_base):
    h = int(hashlib.sha256(pid.encode("utf-8")).hexdigest(), 16)
    return (seed_base + (h % (2**31 - 1))) & 0x7FFFFFFF

def infer_appearance(demographics):
    hints = []
    for d in demographics:
        dl = d.lower()
        if any(x in dl for x in ["20s", "25-34", "30s", "young"]):
            hints.append("younger professional")
        elif any(x in dl for x in ["40s", "35-44", "45-54", "mid-career"]):
            hints.append("mid-career professional")
        elif any(x in dl for x in ["50s", "55+", "senior"]):
            hints.append("experienced professional")
    return "; ".join(hints) if hints else "professional appearance"

def infer_posture_gesture(behaviors, quote):
    if any("collaborat" in b.lower() for b in behaviors):
        return "leaning forward, engaged posture"
    elif any("focus" in b.lower() or "concentrat" in b.lower() for b in behaviors):
        return "upright, focused posture"
    else:
        return "professional seated posture"

def infer_expression(quote):
    if any(word in quote.lower() for word in ["excited", "love", "passion", "amazing"]):
        return "enthusiastic expression"
    elif any(word in quote.lower() for word in ["challenge", "problem", "difficult"]):
        return "thoughtful expression"
    else:
        return "confident, professional expression"

def infer_clothing(job_title, demographics):
    title = job_title.lower()
    if any(x in title for x in ["manager", "director", "lead", "executive"]):
        return "business formal attire"
    elif any(x in title for x in ["developer", "engineer", "technical"]):
        return "business casual attire"
    else:
        return "professional attire"

def infer_work_tools(job_title, behaviors):
    title = job_title.lower()
    tools = ["laptop"]
    if any(x in title for x in ["designer", "creative", "product manager", "ux", "ui"]):
        tools.append("tablet with stylus")
    elif any(x in title for x in ["developer", "engineer", "programmer"]):
        tools.append("dual monitors")
    elif any(x in title for x in ["manager", "director", "lead"]):
        tools.append("notebook and pen")
    return ", ".join(tools)

def infer_wall_artifacts(job_title):
    title = job_title.lower()
    if any(x in title for x in ["manager", "director", "lead"]):
        return "whiteboard with diagrams, certificates"
    elif any(x in title for x in ["developer", "engineer", "technical"]):
        return "code snippets, technical diagrams"
    else:
        return "professional certificates, calendar"

def infer_personal_touches(behaviors, needs_wants):
    touches = []
    if any("collaborat" in b.lower() for b in behaviors):
        touches.append("team photo")
    if any("coffee" in n.lower() for n in needs_wants):
        touches.append("coffee mug")
    if any("plant" in n.lower() or "nature" in n.lower() for n in needs_wants):
        touches.append("small plant")
    return ", ".join(touches) if touches else "personal items"

def make_persona_specific_prompt(persona):
    name = persona["name"]
    job_title = persona["job_title"]
    quote = persona["quotation"]
    demographics = persona["demographics"]
    behaviors = persona["behaviors"]
    needs_wants = persona["needs_wants"]
    
    appearance = infer_appearance(demographics)
    posture_gesture = infer_posture_gesture(behaviors, quote)
    expression = infer_expression(quote)
    clothing = infer_clothing(job_title, demographics)
    work_tools = infer_work_tools(job_title, behaviors)
    wall_artifacts = infer_wall_artifacts(job_title)
    personal_touches = infer_personal_touches(behaviors, needs_wants)
    
    return (
        f"{name}, {job_title}, seated at a desk; {posture_gesture}; {expression}; {appearance}; {clothing}. "
        f"composition center-left, person dominant, abundant negative space. "
        f"minimal environment with the same line style: simple desk and ergonomic chair, {work_tools}; "
        f"wall hints ({wall_artifacts}); {personal_touches}. "
        f"environment strictly secondary, fewer lines than the person; no text."
    )

def load_workflow(path):
    with open(path, 'r') as f:
        return json.load(f)

def update_workflow_prompts_and_params(workflow, positive, negative, filename_prefix, resolution=None, sampler=None, checkpoint=None, loras=None, seed=None):
    # FIXED: Update the workflow with the new parameters
    updated = copy.deepcopy(workflow)
    
    # FIXED: Update text prompts - check the actual content to identify positive vs negative
    for node_id, node in updated.items():
        if node.get("class_type") == "CLIPTextEncode":
            current_text = node.get("inputs", {}).get("text", "")
            # Check if this is the positive prompt (contains the line art instructions)
            if "varied line weight" in current_text or "bold outer contours" in current_text:
                print(f"  -> Updating POSITIVE prompt in node {node_id}")
                node["inputs"]["text"] = positive
            # Check if this is the negative prompt (contains color, gradients, etc.)
            elif "color, gradients" in current_text or "shading, shadows" in current_text:
                print(f"  -> Updating NEGATIVE prompt in node {node_id}")
                node["inputs"]["text"] = negative
    
    # Update sampler parameters
    for node_id, node in updated.items():
        if node.get("class_type") == "KSampler":
            if seed is not None:
                node["inputs"]["seed"] = seed
            if sampler:
                for key, value in sampler.items():
                    if key in node["inputs"]:
                        node["inputs"][key] = value
    
    # Update resolution
    for node_id, node in updated.items():
        if node.get("class_type") == "EmptyLatentImage":
            if resolution:
                node["inputs"]["width"] = resolution["width"]
                node["inputs"]["height"] = resolution["height"]
    
    # Update filename
    for node_id, node in updated.items():
        if node.get("class_type") == "SaveImage":
            node["inputs"]["filename_prefix"] = filename_prefix
    
    return updated

def submit_to_comfy(comfy_url, workflow):
    payload = {
        "prompt": workflow,
        "client_id": f"inna-fixed-{hash(str(workflow)) % 10000}"
    }
    
    response = requests.post(f"{comfy_url}/prompt", json=payload)
    response.raise_for_status()
    return response.json()

def main():
    if len(sys.argv) != 4:
        print("Usage: python fixed_comfyui.py <project_dir> <project> <batch_id>")
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
    
    # Load workflow
    workflow_template = load_workflow(WORKFLOW_PATH)
    
    # Get style preset
    style = copy.deepcopy(STYLE_PRESETS["single_line_bw"])
    
    # Process each persona
    jobs = []
    for persona_file in sorted(persona_files):
        with open(persona_file, 'r') as f:
            data = json.load(f)
        
        persona = data['persona']
        pid = persona["id"]
        name = persona["name"]
        job_title = persona["job_title"]
        
        print(f"Processing {name} ({job_title})...")
        
        # Generate persona-specific prompt
        persona_prompt = make_persona_specific_prompt(persona)
        positive_full = f"[{pid}] {style['positive_prefix']} {persona_prompt}"
        negative_full = style["negative"]
        
        # Clean up quotes
        positive_full = positive_full.replace("\u2011", "-").replace("\u2019", "'").replace('\\"', '"')
        negative_full = negative_full.replace("\u2011", "-").replace("\u2019", "'").replace('\\"', '"')
        
        # Generate seed
        seed = persona_hash_seed(pid, 123456789)
        
        # Update workflow
        workflow = update_workflow_prompts_and_params(
            workflow_template,
            positive_full,
            negative_full,
            filename_prefix=pid,
            resolution=style.get("resolution"),
            sampler=style.get("sampler"),
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
        "style": "single_line_bw"
    }
    
    summary_file = Path(project_dir) / "fixed_comfyui_jobs.json"
    with open(summary_file, 'w') as f:
        json.dump(summary, f, indent=2)
    
    print(f"\nJob summary saved to: {summary_file}")
    print(f"Successfully submitted: {sum(1 for j in jobs if j['submit'] == 'ok')}/{len(jobs)} jobs")

if __name__ == "__main__":
    main()
EOF

# Run the FIXED Python script
echo -e "${YELLOW}🔄 Processing personas and submitting to ComfyUI (FIXED VERSION)...${NC}"
python3 /tmp/fixed_comfyui.py "$PROJECT_DIR" "$PROJECT" "$BATCH_ID"

if [ $? -eq 0 ]; then
    echo -e "\n${GREEN}🎉 ComfyUI workflow triggered successfully (FIXED VERSION)!${NC}"
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
rm -f /tmp/fixed_comfyui.py
