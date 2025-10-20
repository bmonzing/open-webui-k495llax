# Inna Model Management System

A streamlined system for managing the "Inna (Persona-Test)" model configuration directly in Cursor, with automated backups and safe update procedures.

## 🚀 Quick Start

### One-Command Operations

```bash
# View current configuration
./scripts/inna-manager.sh view

# Edit configuration files in Cursor
./scripts/inna-manager.sh edit

# Update model with changes
./scripts/inna-manager.sh update

# Create backup
./scripts/inna-manager.sh backup

# Check status
./scripts/inna-manager.sh status
```

## 📁 Directory Structure

```
inna-management/
├── README.md                    # This file
├── configs/                     # Editable configuration files
│   ├── system-prompt.json      # System prompt (editable)
│   └── metadata.json           # Model metadata (editable)
├── scripts/                     # Management scripts
│   ├── inna-manager.sh         # Main management script
│   ├── backup-inna.sh          # Backup creation script
│   └── update-inna.sh          # Database update script
└── backups/                     # Automatic backups (timestamped)
    ├── inna-complete-config-*.json
    ├── inna-system-prompt-*.json
    ├── inna-metadata-*.json
    └── inna-model-full-*.sql
```

## 🔧 Configuration Files

### `configs/system-prompt.json`
Contains the system prompt that defines Inna's behavior. Edit this file to modify:
- Inna's personality and expertise
- The innovation workshop process
- Step-by-step instructions
- Tool integration logic

### `configs/metadata.json`
Contains model metadata including:
- Capabilities (vision, file_upload, web_search, etc.)
- Suggestion prompts
- Tool IDs
- Description
- Profile image URL

## 🛠️ Workflow

### 1. Edit Configuration
```bash
./scripts/inna-manager.sh edit
```
This opens the `configs/` directory in Cursor where you can edit the JSON files.

### 2. Update Model
```bash
./scripts/inna-manager.sh update
```
This automatically:
- Creates a backup of the current configuration
- Applies your changes to the database
- Updates the timestamp
- Shows a summary of changes

### 3. Verify Changes
```bash
./scripts/inna-manager.sh view
```
Shows the current configuration to verify your changes.

## 🔒 Safety Features

### Automatic Backups
- Every update creates a timestamped backup
- Backups are stored in the `backups/` directory
- Only the last 10 backups are kept to save space
- Backups include both SQL and JSON formats

### Validation
- Scripts validate database connectivity before making changes
- JSON syntax is validated before applying updates
- Model existence is checked before operations

### Rollback
```bash
./scripts/inna-manager.sh restore
```
Restores the model from the most recent backup.

## 📋 Common Tasks

### Enable/Disable Capabilities
Edit `configs/metadata.json`:
```json
{
  "capabilities": {
    "vision": true,
    "file_upload": true,
    "web_search": false,
    "image_generation": true,
    "code_interpreter": true,
    "citations": false,
    "status_updates": false
  }
}
```

### Update Suggestion Prompts
Edit `configs/metadata.json`:
```json
{
  "suggestion_prompts": [
    {"content": "I have an idea!"},
    {"content": "I have a problem."},
    {"content": "I want to make something better."},
    {"content": "I want to make something new."},
    {"content": "Can you help me with something?"}
  ]
}
```

### Modify System Prompt
Edit `configs/system-prompt.json`:
```json
{
  "system": "Your new system prompt here..."
}
```

## 🚨 Troubleshooting

### Model Not Found
If you get "Model not found" errors:
1. Check that Open WebUI is running
2. Verify the database path in the scripts
3. Ensure the model ID is correct

### JSON Syntax Errors
If you get JSON validation errors:
1. Use a JSON validator to check your files
2. Check for missing commas or quotes
3. Ensure proper escaping of special characters

### Permission Denied
If scripts won't run:
```bash
chmod +x scripts/*.sh
```

## 🔄 Integration with Open WebUI

After making changes:
1. Restart Open WebUI to see the changes
2. The model will appear in the workspace with updated configuration
3. All capabilities and tools will be available immediately

## 📝 Notes

- Always run `backup` before making changes (automatic with `update`)
- The system prompt is the core of Inna's behavior
- Metadata controls what features are available
- Tools are defined in the metadata's `toolIds` array
- Changes take effect immediately after Open WebUI restart

## 🆘 Support

If you encounter issues:
1. Check the backup files to see what changed
2. Use `./scripts/inna-manager.sh status` to verify configuration
3. Restore from backup if needed: `./scripts/inna-manager.sh restore`
