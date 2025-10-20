#!/usr/bin/env python3

"""
Test script to show how the new style preset will work
"""

# Simulate the new style preset
NEW_STYLE_PRESET = {
    "single_line_bw": {
        "positive_prefix": "A minimalist, clean-line black and white illustration with a simple, uncluttered background. The style is characterized by its hand-drawn, slightly imperfect linework and a focus on characters with a relaxed and contemplative mood. There is a deliberate use of negative space to create a sense of calm and focus on the subject. To add visual weight and balance to the composition, incorporate one or two solid black shapes. These filled-in areas should be used thoughtfully to ground the character and anchor the scene. Typically, the largest clothing items, like pants or a jacket, or significant objects in the foreground are filled in solid black. This technique adds contrast and depth without sacrificing the overall minimalist aesthetic. The decision of what to make solid black should be based on creating a clear focal point and providing a sense of stability to the otherwise light and airy drawing.",
        "negative": "color, gradients, shading, shadows, cross-hatching, texture, lighting, 3D, blur, noise, text, words, logos, watermarks, signatures, clutter, busy background, complex scene, photorealism, painterly, hatching, stippling, tone, drop shadows"
    }
}

def simulate_persona_prompt(persona):
    """Simulate Inna's persona-specific prompt generation"""
    return f"{persona['name']}, {persona['job_title']}, seated at a desk; {persona['posture']}, {persona['expression']}; {persona['appearance']}; {persona['clothing']}. composition center-left, person dominant, abundant negative space. minimal environment with the same line style: simple desk and ergonomic chair, {persona['work_tools']}; wall hints ({persona['wall_artifacts']}); {persona['personal_touches']}. environment strictly secondary, fewer lines than the person; no text."

# Example persona data
example_persona = {
    "id": "pp-jsmith",
    "name": "John Smith",
    "job_title": "Product Manager",
    "posture": "upright posture, one hand on chin in thought",
    "expression": "focused expression with slight smile",
    "appearance": "professional appearance",
    "clothing": "dark blazer, white shirt",
    "work_tools": "laptop, notebook, coffee mug",
    "wall_artifacts": "whiteboard with sticky notes",
    "personal_touches": "family photo, small plant"
}

# Generate the full prompt
style = NEW_STYLE_PRESET["single_line_bw"]
persona_prompt = simulate_persona_prompt(example_persona)
full_prompt = f"[{example_persona['id']}] {style['positive_prefix']} {persona_prompt}"

print("🎨 NEW STYLE PRESET PREVIEW")
print("=" * 50)
print("\n📝 Style Description:")
print(style['positive_prefix'])
print("\n👤 Persona Content (Inna's method):")
print(persona_prompt)
print("\n🎯 FULL PROMPT:")
print(full_prompt)
print("\n🚫 Negative Prompt:")
print(style['negative'])
print("\n✨ Key Changes:")
print("• Hand-drawn, slightly imperfect linework")
print("• Relaxed and contemplative mood")
print("• Deliberate use of negative space")
print("• Strategic solid black shapes for visual weight")
print("• Focus on creating calm and focus")
