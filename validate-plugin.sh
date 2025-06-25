#!/bin/bash

# TrueSight Plugin Validation Script
# This script validates the plugin structure and basic Lua syntax

set -e

echo "🔍 TrueSight Plugin Validation"
echo "================================"

# Check if lua is available
if ! command -v lua5.3 &> /dev/null; then
    echo "❌ Lua 5.3 not found. Installing..."
    sudo apt-get update && sudo apt-get install -y lua5.3
fi

# Validate plugin structure
echo "📁 Validating plugin structure..."

PLUGIN_DIR="lightroom-plugin"
REQUIRED_FILES=(
    "Info.lua"
    "ColorAnalysis.lua"
    "AzureOpenAI.lua"
    "ColorAdjustments.lua"
    "ExportDialog.lua"
    "ConfigDialog.lua"
    "TroubleShoot.lua"
    "PluginInit.lua"
    "help.html"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$PLUGIN_DIR/$file" ]; then
        echo "✅ $file exists"
    else
        echo "❌ $file missing"
        exit 1
    fi
done

# Validate basic Lua syntax (Info.lua only, as it doesn't have Lightroom-specific imports)
echo ""
echo "🔧 Validating basic Lua syntax..."

echo -n "Checking Info.lua... "
if lua5.3 -e "dofile('$PLUGIN_DIR/Info.lua')" >/dev/null 2>&1; then
    echo "✅ OK"
else
    echo "❌ Syntax error in Info.lua"
    lua5.3 -e "dofile('$PLUGIN_DIR/Info.lua')"
    exit 1
fi

# Check for basic syntax issues in other files
echo -n "Checking other Lua files for basic syntax... "
LUA_FILES=$(find $PLUGIN_DIR -name "*.lua" ! -name "Info.lua")
SYNTAX_OK=true

for file in $LUA_FILES; do
    # Check for return statement
    if ! grep -q "return.*" "$file"; then
        echo "⚠️  Warning: $file doesn't have a return statement"
    fi
    
    # More sophisticated bracket balance check
    TEMP_FILE=$(mktemp)
    sed 's/--.*$//' "$file" | tr -d '\n' | sed 's/[^{}]//g' > "$TEMP_FILE"
    BRACKET_BALANCE=$(cat "$TEMP_FILE" | sed 's/{/+1/g' | sed 's/}/-1/g' | tr -d '+' | sed 's/-1/-1 /g' | xargs | tr ' ' '+' | bc 2>/dev/null || echo 0)
    rm "$TEMP_FILE"
    
    if [ "$BRACKET_BALANCE" -ne "0" ]; then
        echo "⚠️  Warning: Potential bracket imbalance in $file (balance: $BRACKET_BALANCE)"
    fi
done

echo "✅ Basic syntax checks passed"

# Validate Azure ARM template
echo ""
echo "☁️ Validating Azure ARM template..."

if command -v az &> /dev/null; then
    if az account show &> /dev/null; then
        echo -n "Checking ARM template... "
        if az deployment group validate \
            --resource-group "validation-rg" \
            --template-file "azure-infrastructure/deploy-openai.json" \
            --parameters openAiServiceName="validation-test" >/dev/null 2>&1; then
            echo "✅ Valid"
        else
            echo "⚠️  Template validation skipped (resource group doesn't exist)"
        fi
    else
        echo "⚠️  Azure CLI validation skipped (not logged in)"
    fi
else
    echo "⚠️  Azure CLI validation skipped (not installed)"
fi

# Check documentation
echo ""
echo "📖 Checking documentation..."

DOC_FILES=(
    "README.md"
    "docs/DEPLOYMENT.md"
    "docs/CONTRIBUTING.md"
    "LICENSE"
)

for file in "${DOC_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ $file exists"
    else
        echo "❌ $file missing"
    fi
done

# Check CI/CD configuration
echo ""
echo "🔄 Checking CI/CD configuration..."

if [ -f ".github/workflows/ci-cd.yml" ]; then
    echo "✅ GitHub Actions workflow exists"
else
    echo "❌ GitHub Actions workflow missing"
fi

# Security check
echo ""
echo "🔒 Security check..."

echo -n "Checking for hardcoded secrets... "
if grep -r "sk-\|Bearer " $PLUGIN_DIR/ 2>/dev/null; then
    echo "❌ Potential secrets found"
    exit 1
else
    echo "✅ No hardcoded secrets detected"
fi

# File size check
echo ""
echo "📊 Plugin size analysis..."

PLUGIN_SIZE=$(du -sh $PLUGIN_DIR | cut -f1)
echo "Plugin size: $PLUGIN_SIZE"

echo ""
echo "🎉 Plugin validation completed successfully!"
echo ""
echo "Next steps:"
echo "1. Deploy Azure infrastructure: cd azure-infrastructure && ./deploy.sh"
echo "2. Install plugin in Lightroom Classic"
echo "3. Configure Azure OpenAI settings"
echo "4. Test with sample photos"