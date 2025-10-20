import sys
import os
sys.path.append('/Users/287096/open-webui/backend')

# Import the tool
from open_webui.models.tools import Tools
from open_webui.internal.db import get_db

# Test payload
test_data = {
    "final": True,
    "project": "debug-test",
    "batch_id": "test-1",
    "approved_personas": [
        {
            "id": "pp-test",
            "name": "Test Person",
            "job_title": "Test Role",
            "quotation": "This is a test.",
            "demographics": ["Test 1", "Test 2", "Test 3", "Test 4"],
            "behaviors": ["Test 1", "Test 2", "Test 3", "Test 4"],
            "needs_wants": ["Test 1", "Test 2", "Test 3", "Test 4"]
        }
    ]
}

try:
    # Get the tool
    tool = Tools.get_tool_by_id("step3_finalize_and_pipeline")
    if not tool:
        print("ERROR: Tool not found")
        sys.exit(1)
    
    # Load the tool module
    from open_webui.utils.plugin import load_tool_module_by_id
    module, _ = load_tool_module_by_id("step3_finalize_and_pipeline")
    
    # Test the function
    result = module.step3_finalize_and_pipeline(
        data=test_data,
        workflow_path="/Users/287096/ai/ComfyUI/workflows/line-art.json"
    )
    
    print("SUCCESS: Tool executed successfully")
    print("Result:", result)
    
except Exception as e:
    print(f"ERROR: {e}")
    import traceback
    traceback.print_exc()
