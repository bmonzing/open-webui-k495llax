#!/bin/bash

# Inna Debugging Script
# Comprehensive debugging for Inna's tool calling behavior

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
DB_PATH="/Users/287096/open-webui/backend/data/webui.db"
MODEL_ID="inna-persona-test"
PERSONA_DIR="/Users/287096/ai/persona_system"
DEBUG_DIR="/Users/287096/ai/inna-management/debug"
LOG_FILE="$DEBUG_DIR/inna-debug.log"

# Create debug directory
mkdir -p "$DEBUG_DIR"

# Logging function
log_debug() {
    echo -e "${BLUE}[DEBUG]${NC} $1" | tee -a "$LOG_FILE"
}

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1" | tee -a "$LOG_FILE"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
}

# Function to check model configuration
check_model_config() {
    log_info "🔍 Checking Inna model configuration..."
    
    # Basic model info
    echo -e "\n${PURPLE}📋 Model Information:${NC}"
    sqlite3 "$DB_PATH" "SELECT 'ID: ' || id, 'Name: ' || name, 'Base Model: ' || base_model_id, 'Active: ' || is_active FROM model WHERE id = '$MODEL_ID';"
    
    # Function calling configuration
    echo -e "\n${PURPLE}🔧 Function Calling Configuration:${NC}"
    FUNCTION_CALLING=$(sqlite3 "$DB_PATH" "SELECT json_extract(params, '$.function_calling') FROM model WHERE id = '$MODEL_ID';")
    if [ -z "$FUNCTION_CALLING" ] || [ "$FUNCTION_CALLING" = "null" ]; then
        log_warn "No function_calling parameter set in model params"
    else
        log_info "Function calling mode: $FUNCTION_CALLING"
    fi
    
    # Check metadata for function calling
    META_FUNCTION_CALLING=$(sqlite3 "$DB_PATH" "SELECT json_extract(meta, '$.function_calling') FROM model WHERE id = '$MODEL_ID';")
    if [ -z "$META_FUNCTION_CALLING" ] || [ "$META_FUNCTION_CALLING" = "null" ]; then
        log_warn "No function_calling parameter set in model metadata"
    else
        log_info "Metadata function calling mode: $META_FUNCTION_CALLING"
    fi
    
    # Tool configuration
    echo -e "\n${PURPLE}🛠️ Tool Configuration:${NC}"
    TOOL_IDS=$(sqlite3 "$DB_PATH" "SELECT json_extract(meta, '$.toolIds') FROM model WHERE id = '$MODEL_ID';")
    log_info "Configured tools: $TOOL_IDS"
    
    # Check if tools exist
    echo "$TOOL_IDS" | jq -r '.[]' 2>/dev/null | while read tool_id; do
        if sqlite3 "$DB_PATH" "SELECT id FROM tool WHERE id = '$tool_id';" | grep -q "$tool_id"; then
            log_info "✅ Tool '$tool_id' exists in database"
        else
            log_error "❌ Tool '$tool_id' NOT found in database"
        fi
    done
}

# Function to check system prompt for tool calling instructions
check_system_prompt() {
    log_info "📝 Analyzing system prompt for tool calling instructions..."
    
    SYSTEM_PROMPT=$(sqlite3 "$DB_PATH" "SELECT json_extract(params, '$.system') FROM model WHERE id = '$MODEL_ID';")
    
    # Check for reasoning model references
    if echo "$SYSTEM_PROMPT" | grep -q "Reasoning Models"; then
        log_warn "⚠️  System prompt contains 'Reasoning Models' reference - may confuse non-reasoning models"
    fi
    
    # Check for tool calling instructions
    if echo "$SYSTEM_PROMPT" | grep -q "step3_finalize_and_pipeline"; then
        log_info "✅ System prompt contains tool calling instructions"
    else
        log_error "❌ System prompt missing tool calling instructions"
    fi
    
    # Check for JSON format instructions
    if echo "$SYSTEM_PROMPT" | grep -q "JSON code block"; then
        log_info "✅ System prompt contains JSON format instructions"
    else
        log_warn "⚠️  System prompt missing JSON format instructions"
    fi
    
    # Check for iteration vs finalization phases
    if echo "$SYSTEM_PROMPT" | grep -q "Iteration Phase"; then
        log_info "✅ System prompt defines iteration phase"
    else
        log_warn "⚠️  System prompt missing iteration phase definition"
    fi
    
    if echo "$SYSTEM_PROMPT" | grep -q "Finalization Phase"; then
        log_info "✅ System prompt defines finalization phase"
    else
        log_warn "⚠️  System prompt missing finalization phase definition"
    fi
}

# Function to check recent tool usage and errors
check_recent_activity() {
    log_info "📊 Checking recent tool usage and errors..."
    
    # Check for tool error logs
    ERROR_LOG="$PERSONA_DIR/tool_errors.log"
    if [ -f "$ERROR_LOG" ]; then
        echo -e "\n${PURPLE}🚨 Recent Tool Errors:${NC}"
        tail -10 "$ERROR_LOG" | while read line; do
            log_error "$line"
        done
    else
        log_info "No tool error log found at $ERROR_LOG"
    fi
    
    # Check recent persona files
    echo -e "\n${PURPLE}📁 Recent Persona Files:${NC}"
    find "$PERSONA_DIR" -name "*.json" -type f -mtime -1 | head -5 | while read file; do
        log_info "Recent file: $file"
    done
    
    # Check for incomplete or failed runs
    echo -e "\n${PURPLE}🔍 Checking for incomplete runs:${NC}"
    find "$PERSONA_DIR" -name "roster_v*.json" -type f | while read roster; do
        BATCH_DIR=$(dirname "$roster")
        PERSONA_COUNT=$(find "$BATCH_DIR" -name "proto-persona-*.json" | wc -l)
        ROSTER_PERSONAS=$(jq '.personas | length' "$roster" 2>/dev/null || echo "0")
        
        if [ "$PERSONA_COUNT" -ne "$ROSTER_PERSONAS" ]; then
            log_warn "Mismatch in $roster: $PERSONA_COUNT persona files vs $ROSTER_PERSONAS in roster"
        fi
    done
}

# Function to test basic tool calling
test_basic_tool_calling() {
    log_info "🧪 Testing basic tool calling functionality..."
    
    # Create a simple test payload
    TEST_PAYLOAD='{
        "final": true,
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
    }'
    
    # Test the tool directly
    log_info "Testing step3_finalize_and_pipeline tool with test payload..."
    
    # This would require running the tool directly - we'll create a test script
    cat > "$DEBUG_DIR/test-tool.py" << 'EOF'
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
EOF

    log_info "Created test script at $DEBUG_DIR/test-tool.py"
    log_info "To run the test: python3 $DEBUG_DIR/test-tool.py"
}

# Function to check ComfyUI workflow
check_comfyui_workflow() {
    log_info "🎨 Checking ComfyUI workflow configuration..."
    
    WORKFLOW_PATH="/Users/287096/ai/ComfyUI/workflows/line-art.json"
    
    if [ -f "$WORKFLOW_PATH" ]; then
        log_info "✅ ComfyUI workflow exists at $WORKFLOW_PATH"
        
        # Check if workflow is valid JSON
        if jq empty "$WORKFLOW_PATH" 2>/dev/null; then
            log_info "✅ ComfyUI workflow is valid JSON"
        else
            log_error "❌ ComfyUI workflow is not valid JSON"
        fi
    else
        log_error "❌ ComfyUI workflow not found at $WORKFLOW_PATH"
    fi
    
    # Check ComfyUI server
    COMFY_URL="http://127.0.0.1:8188"
    if curl -s "$COMFY_URL/system_stats" > /dev/null 2>&1; then
        log_info "✅ ComfyUI server is running at $COMFY_URL"
    else
        log_warn "⚠️  ComfyUI server not responding at $COMFY_URL"
    fi
}

# Function to generate debug report
generate_debug_report() {
    log_info "📋 Generating comprehensive debug report..."
    
    REPORT_FILE="$DEBUG_DIR/inna-debug-report-$(date +%Y%m%d_%H%M%S).md"
    
    cat > "$REPORT_FILE" << EOF
# Inna Debug Report - $(date)

## Model Configuration
- **Model ID:** $MODEL_ID
- **Base Model:** $(sqlite3 "$DB_PATH" "SELECT base_model_id FROM model WHERE id = '$MODEL_ID';")
- **Function Calling:** $(sqlite3 "$DB_PATH" "SELECT json_extract(params, '$.function_calling') FROM model WHERE id = '$MODEL_ID';")
- **Tools:** $(sqlite3 "$DB_PATH" "SELECT json_extract(meta, '$.toolIds') FROM model WHERE id = '$MODEL_ID';")

## System Prompt Analysis
$(sqlite3 "$DB_PATH" "SELECT json_extract(params, '$.system') FROM model WHERE id = '$MODEL_ID';" | head -20)

## Recent Activity
$(find "$PERSONA_DIR" -name "*.json" -type f -mtime -1 | head -10)

## Recommendations
1. Check function calling configuration
2. Simplify system prompt for non-reasoning models
3. Add explicit tool calling instructions
4. Test with simpler tool calls first
EOF

    log_info "Debug report saved to: $REPORT_FILE"
}

# Main execution
main() {
    echo -e "${CYAN}🔍 Inna Debugging System${NC}"
    echo "================================"
    
    check_model_config
    check_system_prompt
    check_recent_activity
    check_comfyui_workflow
    test_basic_tool_calling
    generate_debug_report
    
    echo -e "\n${GREEN}✅ Debugging complete!${NC}"
    echo -e "Check the debug directory: $DEBUG_DIR"
    echo -e "View the log: $LOG_FILE"
}

# Run main function
main "$@"
