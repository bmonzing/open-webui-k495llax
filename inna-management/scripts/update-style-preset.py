#!/usr/bin/env python3

"""
Update the style preset in the step3_finalize_and_pipeline tool
Replaces the stylistic elements while keeping Inna's content generation methods
"""

import sqlite3
import json
import re

# Database path
DB_PATH = "/Users/287096/open-webui/backend/data/webui.db"
TOOL_ID = "step3_finalize_and_pipeline"

# New style preset
NEW_STYLE_PRESET = {
    "single_line_bw": {
        "positive_prefix": "A minimalist, clean-line black and white illustration with a simple, uncluttered background. The style is characterized by its hand-drawn, slightly imperfect linework and a focus on characters with a relaxed and contemplative mood. There is a deliberate use of negative space to create a sense of calm and focus on the subject. To add visual weight and balance to the composition, incorporate one or two solid black shapes. These filled-in areas should be used thoughtfully to ground the character and anchor the scene. Typically, the largest clothing items, like pants or a jacket, or significant objects in the foreground are filled in solid black. This technique adds contrast and depth without sacrificing the overall minimalist aesthetic. The decision of what to make solid black should be based on creating a clear focal point and providing a sense of stability to the otherwise light and airy drawing.",
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

def update_tool_style_preset():
    """Update the style preset in the tool"""
    
    # Connect to database
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    
    # Get current tool content
    cursor.execute("SELECT content FROM tool WHERE id = ?", (TOOL_ID,))
    result = cursor.fetchone()
    
    if not result:
        print(f"❌ Tool {TOOL_ID} not found")
        return False
    
    content = result[0]
    
    # Find and replace the STYLE_PRESETS section
    # Look for the pattern: STYLE_PRESETS = { ... }
    pattern = r'STYLE_PRESETS = \{[^}]*"single_line_bw": \{[^}]*\}[^}]*\}'
    
    # Create the new STYLE_PRESETS string
    new_style_presets = "STYLE_PRESETS = " + json.dumps(NEW_STYLE_PRESET, indent=4)
    
    # Replace the old style preset with the new one
    new_content = re.sub(pattern, new_style_presets, content, flags=re.DOTALL)
    
    if new_content == content:
        print("❌ No changes made - pattern not found")
        return False
    
    # Update the tool in the database
    cursor.execute("UPDATE tool SET content = ? WHERE id = ?", (new_content, TOOL_ID))
    conn.commit()
    
    print("✅ Style preset updated successfully!")
    print("📝 New positive_prefix:")
    print(f"   {NEW_STYLE_PRESET['single_line_bw']['positive_prefix'][:100]}...")
    
    conn.close()
    return True

if __name__ == "__main__":
    print("🎨 Updating Inna's style preset...")
    print("📋 Replacing stylistic elements while keeping content generation methods")
    
    if update_tool_style_preset():
        print("\n🎉 Style preset updated!")
        print("💡 The next time Inna generates personas, they'll use the new style")
        print("🔄 You may need to restart Open WebUI for changes to take effect")
    else:
        print("\n❌ Failed to update style preset")
