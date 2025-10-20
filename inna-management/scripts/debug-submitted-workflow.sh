#!/bin/bash

# Debug script to see exactly what workflow was submitted to ComfyUI

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🔍 Debugging submitted ComfyUI workflow...${NC}"

# Create a script to show exactly what was submitted
cat > /tmp/debug_submitted.py << 'EOF'
import json
import sys
from pathlib import Path

def load_workflow(path):
    with open(path, 'r') as f:
        return json.load(f)

def make_persona_specific_prompt(persona):
    # Simplified version of the prompt generation
    name = persona["name"]
    job_title = persona["job_title"]
    quote = persona["quotation"]
    demographics = persona["demographics"]
    behaviors = persona["behaviors"]
    needs_wants = persona["needs_wants"]
    
    # Simple inference
    appearance = "professional appearance"
    posture_gesture = "professional seated posture"
    expression = "confident, professional expression"
    clothing = "professional attire"
    work_tools = "laptop, notebook"
    wall_artifacts = "certificates, whiteboard"
    personal_touches = "coffee mug, plant"
    
    return (
        f"{name}, {job_title}, seated at a desk; {posture_gesture}; {expression}; {appearance}; {clothing}. "
        f"composition center-left, person dominant, abundant negative space. "
        f"minimal environment with the same line style: simple desk and ergonomic chair, {work_tools}; "
        f"wall hints ({wall_artifacts}); {personal_touches}. "
        f"environment strictly secondary, fewer lines than the person; no text."
    )

def update_workflow_prompts_and_params(workflow, positive, negative, filename_prefix, resolution=None, sampler=None, checkpoint=None, loras=None, seed=None):
    import copy
    updated = copy.deepcopy(workflow)
    
    print("=== WORKFLOW UPDATE DEBUG ===")
    print(f"Positive prompt: {positive[:100]}...")
    print(f"Negative prompt: {negative[:100]}...")
    
    # Update text prompts
    for node_id, node in updated.items():
        if node.get("class_type") == "CLIPTextEncode":
            current_text = node.get("inputs", {}).get("text", "")
            print(f"Node {node_id} current text: {current_text[:100]}...")
            
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
    
    # Show final prompts
    print("\n=== FINAL WORKFLOW PROMPTS ===")
    for node_id, node in updated.items():
        if node.get("class_type") == "CLIPTextEncode":
            text = node.get("inputs", {}).get("text", "")
            print(f"Node {node_id}: {text[:200]}...")
    
    return updated

def main():
    if len(sys.argv) != 2:
        print("Usage: python debug_submitted.py <persona_file>")
        sys.exit(1)
    
    persona_file = sys.argv[1]
    
    # Load persona data
    with open(persona_file, 'r') as f:
        data = json.load(f)
    
    persona = data['persona']
    pid = persona["id"]
    name = persona["name"]
    job_title = persona["job_title"]
    
    print(f"Processing {name} ({job_title})...")
    
    # Load workflow
    workflow_template = load_workflow("/Users/287096/ai/ComfyUI/workflows/line-art.json")
    
    # Generate persona-specific prompt
    persona_prompt = make_persona_specific_prompt(persona)
    positive_prefix = "IMPORTANT: varied line weight—bold outer contours, delicate details, crisp black line drawing on pure white. subtle line-weight variation: slightly thicker outer contour, finer internal accents; confident, clean stroke; flat lines only, no shading. eye-level, slightly angled view."
    positive_full = f"[{pid}] {positive_prefix} {persona_prompt}"
    negative_full = "color, gradients, shading, shadows, cross-hatching, texture, lighting, 3D, blur, noise, text, words, logos, watermarks, signatures, clutter, busy background, complex scene, photorealism, painterly, hatching, stippling, tone, drop shadows"
    
    # Update workflow
    workflow = update_workflow_prompts_and_params(
        workflow_template,
        positive_full,
        negative_full,
        filename_prefix=pid,
        resolution={"width": 1024, "height": 1024},
        sampler={"steps": 24, "cfg": 5.0, "sampler_name": "dpmpp_2m", "scheduler": "karras"},
        seed=123456789
    )
    
    print(f"\n=== FINAL WORKFLOW STRUCTURE ===")
    print(f"KSampler positive input: {workflow['12']['inputs']['positive']}")
    print(f"KSampler negative input: {workflow['12']['inputs']['negative']}")

if __name__ == "__main__":
    main()
EOF

# Test with one of the persona files
PERSONA_FILE=$(find /Users/287096/ai/persona_system/projects/telecom-service-now/step3/approved/batch-1 -name "proto-persona-*.json" | head -1)

if [ -n "$PERSONA_FILE" ]; then
    echo -e "${YELLOW}Testing with: $(basename "$PERSONA_FILE")${NC}"
    python3 /tmp/debug_submitted.py "$PERSONA_FILE"
else
    echo -e "${RED}No persona files found${NC}"
fi

rm -f /tmp/debug_submitted.py
