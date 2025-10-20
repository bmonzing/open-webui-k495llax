#!/bin/bash

# Debug script to see what workflow was actually submitted

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🔍 Debugging ComfyUI workflow submission...${NC}"

# Create a test script to see what workflow was actually sent
cat > /tmp/debug_workflow.py << 'EOF'
import json
import sys
from pathlib import Path

def load_workflow(path):
    with open(path, 'r') as f:
        return json.load(f)

def update_workflow_prompts_and_params(workflow, positive, negative, filename_prefix, resolution=None, sampler=None, checkpoint=None, loras=None, seed=None):
    import copy
    # Update the workflow with the new parameters
    updated = copy.deepcopy(workflow)
    
    print(f"Original workflow nodes: {list(updated.keys())}")
    
    # Update text prompts
    for node_id, node in updated.items():
        if node.get("class_type") == "CLIPTextEncode":
            print(f"Found CLIPTextEncode node {node_id}: {node.get('inputs', {}).get('text', '')[:100]}...")
            if "text" in node.get("inputs", {}):
                if "positive" in str(node.get("inputs", {}).get("text", "")):
                    print(f"  -> Updating positive prompt")
                    node["inputs"]["text"] = positive
                elif "negative" in str(node.get("inputs", {}).get("text", "")):
                    print(f"  -> Updating negative prompt")
                    node["inputs"]["text"] = negative
    
    # Update sampler parameters
    for node_id, node in updated.items():
        if node.get("class_type") == "KSampler":
            print(f"Found KSampler node {node_id}")
            if seed is not None:
                print(f"  -> Updating seed to {seed}")
                node["inputs"]["seed"] = seed
            if sampler:
                for key, value in sampler.items():
                    if key in node["inputs"]:
                        print(f"  -> Updating {key} to {value}")
                        node["inputs"][key] = value
    
    # Update resolution
    for node_id, node in updated.items():
        if node.get("class_type") == "EmptyLatentImage":
            print(f"Found EmptyLatentImage node {node_id}")
            if resolution:
                print(f"  -> Updating resolution to {resolution}")
                node["inputs"]["width"] = resolution["width"]
                node["inputs"]["height"] = resolution["height"]
    
    # Update filename
    for node_id, node in updated.items():
        if node.get("class_type") == "SaveImage":
            print(f"Found SaveImage node {node_id}")
            print(f"  -> Updating filename prefix to {filename_prefix}")
            node["inputs"]["filename_prefix"] = filename_prefix
    
    return updated

def main():
    # Load the original workflow
    workflow_path = "/Users/287096/ai/ComfyUI/workflows/line-art.json"
    workflow_template = load_workflow(workflow_path)
    
    print("=== ORIGINAL WORKFLOW ===")
    print(f"Nodes: {list(workflow_template.keys())}")
    
    # Check the original prompts
    for node_id, node in workflow_template.items():
        if node.get("class_type") == "CLIPTextEncode":
            text = node.get("inputs", {}).get("text", "")
            print(f"Node {node_id} text: {text[:200]}...")
    
    # Test updating with a sample prompt
    positive = "[pp-test] IMPORTANT: varied line weight—bold outer contours, delicate details, crisp black line drawing on pure white. subtle line-weight variation: slightly thicker outer contour, finer internal accents; confident, clean stroke; flat lines only, no shading. eye-level, slightly angled view. Test Person, Test Job, seated at a desk; professional posture; confident expression; professional appearance; business attire. composition center-left, person dominant, abundant negative space. minimal environment with the same line style: simple desk and ergonomic chair, laptop; wall hints (certificates); coffee mug. environment strictly secondary, fewer lines than the person; no text."
    
    negative = "color, gradients, shading, shadows, cross-hatching, texture, lighting, 3D, blur, noise, text, words, logos, watermarks, signatures, clutter, busy background, complex scene, photorealism, painterly, hatching, stippling, tone, drop shadows"
    
    print("\n=== UPDATED WORKFLOW ===")
    updated = update_workflow_prompts_and_params(
        workflow_template,
        positive,
        negative,
        filename_prefix="pp-test",
        resolution={"width": 1024, "height": 1024},
        sampler={"steps": 24, "cfg": 5.0, "sampler_name": "dpmpp_2m", "scheduler": "karras"},
        seed=123456789
    )
    
    # Check the updated prompts
    for node_id, node in updated.items():
        if node.get("class_type") == "CLIPTextEncode":
            text = node.get("inputs", {}).get("text", "")
            print(f"Node {node_id} text: {text[:200]}...")
    
    # Check sampler settings
    for node_id, node in updated.items():
        if node.get("class_type") == "KSampler":
            print(f"Node {node_id} sampler settings: {node.get('inputs', {})}")

if __name__ == "__main__":
    main()
EOF

python3 /tmp/debug_workflow.py
rm -f /tmp/debug_workflow.py
