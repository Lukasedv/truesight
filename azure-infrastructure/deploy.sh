#!/bin/bash

# TrueSight Azure Infrastructure Deployment Script
# This script deploys the required Azure OpenAI resources for the TrueSight plugin

set -e

# Configuration
RESOURCE_GROUP_NAME="truesight-rg"
LOCATION="eastus"
TEMPLATE_FILE="deploy-openai.json"
DEPLOYMENT_NAME="truesight-deployment-$(date +%Y%m%d-%H%M%S)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    log_error "Azure CLI is not installed. Please install it first:"
    log_error "https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
    exit 1
fi

# Check if user is logged in
if ! az account show &> /dev/null; then
    log_error "You are not logged in to Azure CLI. Please run 'az login' first."
    exit 1
fi

log_info "Starting TrueSight infrastructure deployment..."

# Create resource group if it doesn't exist
log_info "Creating resource group: $RESOURCE_GROUP_NAME"
az group create \
    --name "$RESOURCE_GROUP_NAME" \
    --location "$LOCATION" \
    --output table

# Deploy the ARM template
log_info "Deploying Azure OpenAI resources..."
DEPLOYMENT_OUTPUT=$(az deployment group create \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --template-file "$TEMPLATE_FILE" \
    --name "$DEPLOYMENT_NAME" \
    --output json)

if [ $? -eq 0 ]; then
    log_info "Deployment completed successfully!"
    
    # Extract outputs
    OPENAI_ENDPOINT=$(echo "$DEPLOYMENT_OUTPUT" | jq -r '.properties.outputs.openAiEndpoint.value')
    OPENAI_SERVICE_NAME=$(echo "$DEPLOYMENT_OUTPUT" | jq -r '.properties.outputs.openAiServiceName.value')
    DEPLOYMENT_NAME_OUTPUT=$(echo "$DEPLOYMENT_OUTPUT" | jq -r '.properties.outputs.deploymentName.value')
    
    # Get the API key
    log_info "Retrieving API key..."
    API_KEY=$(az cognitiveservices account keys list \
        --name "$OPENAI_SERVICE_NAME" \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --query "key1" \
        --output tsv)
    
    # Display configuration information
    echo ""
    log_info "=== TrueSight Configuration ==="
    echo "Resource Group: $RESOURCE_GROUP_NAME"
    echo "OpenAI Service Name: $OPENAI_SERVICE_NAME"
    echo "Endpoint: $OPENAI_ENDPOINT"
    echo "Deployment Name: $DEPLOYMENT_NAME_OUTPUT"
    echo "API Key: $API_KEY"
    echo ""
    log_info "Use these values to configure the TrueSight Lightroom plugin."
    echo ""
    log_warn "Keep your API key secure and do not share it publicly!"
    
    # Save configuration to file
    cat > truesight-config.txt << EOF
TrueSight Configuration
=======================
Resource Group: $RESOURCE_GROUP_NAME
OpenAI Service Name: $OPENAI_SERVICE_NAME
Endpoint: $OPENAI_ENDPOINT
Deployment Name: $DEPLOYMENT_NAME_OUTPUT
API Key: $API_KEY

Instructions:
1. Open Lightroom Classic
2. Go to Help > TrueSight Help
3. Click the configuration button
4. Enter the Endpoint and API Key values above
5. Set the Deployment Name to: $DEPLOYMENT_NAME_OUTPUT
EOF
    
    log_info "Configuration saved to truesight-config.txt"
    
else
    log_error "Deployment failed. Please check the error messages above."
    exit 1
fi

log_info "TrueSight infrastructure deployment complete!"