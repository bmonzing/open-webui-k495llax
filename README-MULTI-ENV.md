# Multi-Environment Open WebUI with Inna

This repository contains a multi-environment setup for Open WebUI with the Inna management system.

## 🏗️ **Architecture**

### **Repository Structure**
```
bmonzing/open-webui-k495llax/
├── main/                        # 🔄 Upstream Open WebUI (synced)
├── inna-dev/                    # 🎯 Development environment
├── inna-test/                   # 🧪 Testing environment
├── inna-prod/                   # 🚀 Production environment
├── inna-management/             # 📁 Inna management system
├── environments/                # 🔧 Environment configurations
└── .github/workflows/           # 🤖 GitHub Actions
```

### **Local Directory Structure**
```
/Users/287096/ai/
├── open-webui-shared/           # 🔄 Shared codebase (Git repo)
├── open-webui-dev/              # 🎯 Dev environment (symlinked)
├── open-webui-test/             # 🧪 Test environment (symlinked)
├── open-webui-prod/             # 🚀 Prod environment (symlinked)
└── inna-management/             # 📁 Inna management system
```

## 🚀 **Quick Start**

### **1. Set Up Environments**
```bash
cd /Users/287096/open-webui
./inna-management/scripts/setup-environments.sh
```

### **2. Start an Environment**
```bash
# Development
./start-open-webui-dev.sh

# Testing
./start-open-webui-test.sh

# Production
./start-open-webui-prod.sh
```

### **3. Switch Environments**
```bash
./switch-env.sh dev    # Switch to development
./switch-env.sh test   # Switch to testing
./switch-env.sh prod   # Switch to production
```

## 🔧 **Environment Configuration**

### **Development (dev)**
- **Port**: 8080
- **Data**: `/Users/287096/ai/open-webui-dev/data`
- **Logging**: DEBUG
- **Signup**: Enabled
- **Purpose**: Active development and testing

### **Testing (test)**
- **Port**: 8081
- **Data**: `/Users/287096/ai/open-webui-test/data`
- **Logging**: INFO
- **Signup**: Disabled
- **Purpose**: Pre-production testing

### **Production (prod)**
- **Port**: 8082
- **Data**: `/Users/287096/ai/open-webui-prod/data`
- **Logging**: WARNING
- **Signup**: Disabled
- **Purpose**: Live production use

## 🔄 **GitHub Workflows**

### **Automatic Sync**
- **Schedule**: Weekly (Monday 2 AM)
- **Action**: Syncs with upstream Open WebUI
- **Branches**: Updates main and all environment branches

### **Environment Deployment**
- **Trigger**: Push to environment branch
- **Action**: Deploys to respective environment
- **Branches**: `inna-dev`, `inna-test`, `inna-prod`

## 📁 **Inna Management**

### **Configuration Files**
```
inna-management/
├── configs/
│   ├── dev/                     # Development configs
│   ├── test/                    # Testing configs
│   └── prod/                    # Production configs
├── scripts/
│   ├── auto-sync.sh             # Sync management
│   ├── setup-environments.sh    # Environment setup
│   └── deploy-env.sh            # Environment deployment
└── backups/                     # Automatic backups
```

### **Management Commands**
```bash
# Sync management files with database
inna-sync

# Push changes to database
inna-push

# Pull changes from database
inna-pull

# Verify sync status
inna-verify

# Show status
inna-status
```

## 🔄 **Update Process**

### **1. Update Shared Codebase**
```bash
cd /Users/287096/open-webui
git checkout main
git pull upstream main
git push origin main
```

### **2. Update Environment Branches**
```bash
git checkout inna-dev
git merge main
git push origin inna-dev
```

### **3. Deploy to Environment**
```bash
# GitHub Actions will automatically deploy
# Or manually:
./start-open-webui-dev.sh
```

## 🛠️ **Development Workflow**

### **Making Changes**
1. **Edit** files in development environment
2. **Test** changes locally
3. **Commit** to `inna-dev` branch
4. **Push** to trigger deployment
5. **Promote** to test/prod when ready

### **Environment Promotion**
```bash
# Dev → Test
git checkout inna-test
git merge inna-dev
git push origin inna-test

# Test → Prod
git checkout inna-prod
git merge inna-test
git push origin inna-prod
```

## 🔍 **Troubleshooting**

### **Common Issues**
1. **Port conflicts**: Check if ports 8080/8081/8082 are in use
2. **Database issues**: Check data directory permissions
3. **Symlink issues**: Re-run setup script
4. **Git sync issues**: Check upstream remote configuration

### **Reset Environment**
```bash
# Reset to clean state
rm -rf /Users/287096/ai/open-webui-*
./inna-management/scripts/setup-environments.sh
```

## 📊 **Storage Optimization**

- **Shared Codebase**: ~1GB (single copy)
- **Per Environment**: ~10-50MB (data only)
- **Total for 3 environments**: ~1.1GB (vs 3GB for full duplication)
- **Savings**: ~70% compared to full duplication

## 🤝 **Contributing**

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test in development environment
5. Submit a pull request

## 📄 **License**

This project is licensed under the Open WebUI License.
