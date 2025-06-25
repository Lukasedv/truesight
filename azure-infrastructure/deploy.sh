#!/bin/bash

# TrueSight Azure Infrastructure Deployment Script
# This script deploys the required Azure OpenAI resources for the Missing Opsin plugin
# with robust error handling and idempotent operations

# Exit on error, but handle errors gracefully
set -euo pipefail

# Configuration - can be overridden via environment variables
RESOURCE_GROUP_NAME="${RESOURCE_GROUP_NAME:-truesight-rg}"
LOCATION="${LOCATION:-eastus}"
TEMPLATE_FILE="${TEMPLATE_FILE:-deploy-openai.json}"
DEPLOYMENT_NAME="${DEPLOYMENT_NAME:-truesight-deployment-$(date +%Y%m%d-%H%M%S)}"
CONFIG_FILE="${CONFIG_FILE:-truesight-config.txt}"
FORCE_REDEPLOY="${FORCE_REDEPLOY:-false}"

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

show_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Deploy Azure OpenAI infrastructure for Missing Opsin Lightroom plugin.

Environment Variables:
  RESOURCE_GROUP_NAME    Name of the resource group (default: truesight-rg)
  LOCATION              Azure region (default: eastus)
  TEMPLATE_FILE         ARM template file (default: deploy-openai.json)
  CONFIG_FILE           Output configuration file (default: truesight-config.txt)
  FORCE_REDEPLOY        Force redeployment even if resources exist (default: false)

Options:
  -h, --help           Show this help message
  -f, --force          Force redeployment of existing resources
  -c, --check          Check if resources exist without deploying
  -r, --resource-group NAME  Override resource group name
  -l, --location LOCATION    Override deployment location

Examples:
  $0                           # Deploy with defaults
  $0 --force                   # Force redeploy existing resources
  $0 --check                   # Check resource status only
  $0 -r my-rg -l westus2      # Deploy to specific resource group and location
EOF
}

check_prerequisites() {
    local missing_deps=()
    
    # Check if Azure CLI is installed
    if ! command -v az &> /dev/null; then
        missing_deps+=("Azure CLI")
    fi
    
    # Check if jq is installed
    if ! command -v jq &> /dev/null; then
        missing_deps+=("jq")
    fi
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        log_error "Missing required dependencies: ${missing_deps[*]}"
        log_error "Please install the missing dependencies:"
        for dep in "${missing_deps[@]}"; do
            case $dep in
                "Azure CLI")
                    log_error "  Azure CLI: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
                    ;;
                "jq")
                    log_error "  jq: sudo apt-get install jq (Ubuntu/Debian) or brew install jq (macOS)"
                    ;;
            esac
        done
        return 1
    fi
    
    # Check if user is logged in to Azure
    if ! az account show &> /dev/null; then
        log_error "You are not logged in to Azure CLI. Please run 'az login' first."
        return 1
    fi
    
    # Check if template file exists
    if [ ! -f "$TEMPLATE_FILE" ]; then
        log_error "ARM template file '$TEMPLATE_FILE' not found."
        return 1
    fi
    
    return 0
}

check_resource_exists() {
    local resource_type="$1"
    local resource_name="$2"
    local resource_group="$3"
    
    case $resource_type in
        "resourcegroup")
            az group show --name "$resource_name" &> /dev/null
            ;;
        "cognitiveservices")
            az cognitiveservices account show --name "$resource_name" --resource-group "$resource_group" &> /dev/null
            ;;
        *)
            log_error "Unknown resource type: $resource_type"
            return 1
            ;;
    esac
}

get_existing_deployment_info() {
    local rg_name="$1"
    
    # Get the OpenAI service in the resource group
    local openai_services
    openai_services=$(az cognitiveservices account list --resource-group "$rg_name" --query "[?kind=='OpenAI'].name" --output tsv 2>/dev/null || echo "")
    
    if [ -z "$openai_services" ]; then
        return 1
    fi
    
    local service_name
    service_name=$(echo "$openai_services" | head -n1)
    
    # Get service details
    local endpoint
    endpoint=$(az cognitiveservices account show --name "$service_name" --resource-group "$rg_name" --query "properties.endpoint" --output tsv 2>/dev/null || echo "")
    
    # Get deployments
    local deployments
    deployments=$(az cognitiveservices account deployment list --name "$service_name" --resource-group "$rg_name" --query "[].name" --output tsv 2>/dev/null || echo "")
    
    if [ -n "$endpoint" ] && [ -n "$deployments" ]; then
        local deployment_name
        deployment_name=$(echo "$deployments" | head -n1)
        
        echo "SERVICE_NAME:$service_name"
        echo "ENDPOINT:$endpoint"
        echo "DEPLOYMENT_NAME:$deployment_name"
        return 0
    fi
    
    return 1
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_usage
            exit 0
            ;;
        -f|--force)
            FORCE_REDEPLOY="true"
            shift
            ;;
        -c|--check)
            CHECK_ONLY="true"
            shift
            ;;
        -r|--resource-group)
            RESOURCE_GROUP_NAME="$2"
            shift 2
            ;;
        -l|--location)
            LOCATION="$2"
            shift 2
            ;;
        *)
            log_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Main deployment logic
main() {
    log_info "Starting TrueSight infrastructure deployment..."
    log_info "Resource Group: $RESOURCE_GROUP_NAME"
    log_info "Location: $LOCATION"
    log_info "Template: $TEMPLATE_FILE"
    
    # Check prerequisites
    if ! check_prerequisites; then
        exit 1
    fi
    
    # Check if resource group exists
    if check_resource_exists "resourcegroup" "$RESOURCE_GROUP_NAME" ""; then
        log_info "Resource group '$RESOURCE_GROUP_NAME' already exists."
        
        # Check for existing deployment
        if existing_info=$(get_existing_deployment_info "$RESOURCE_GROUP_NAME"); then
            log_info "Found existing OpenAI deployment in resource group."
            
            # Parse existing deployment info
            local service_name endpoint deployment_name
            while IFS=':' read -r key value; do
                case $key in
                    "SERVICE_NAME") service_name="$value" ;;
                    "ENDPOINT") endpoint="$value" ;;
                    "DEPLOYMENT_NAME") deployment_name="$value" ;;
                esac
            done <<< "$existing_info"
            
            if [ "${CHECK_ONLY:-false}" = "true" ]; then
                log_info "=== Existing TrueSight Configuration ==="
                echo "Resource Group: $RESOURCE_GROUP_NAME"
                echo "OpenAI Service Name: $service_name"
                echo "Endpoint: $endpoint"
                echo "Deployment Name: $deployment_name"
                echo ""
                log_info "Resources are already deployed. Use --force to redeploy."
                exit 0
            fi
            
            if [ "$FORCE_REDEPLOY" != "true" ]; then
                log_warn "OpenAI resources already exist. Use --force to redeploy or --check to view current configuration."
                
                # Get API key for existing deployment
                local api_key
                if api_key=$(az cognitiveservices account keys list \
                    --name "$service_name" \
                    --resource-group "$RESOURCE_GROUP_NAME" \
                    --query "key1" \
                    --output tsv 2>/dev/null); then
                    
                    # Display existing configuration
                    display_configuration "$RESOURCE_GROUP_NAME" "$service_name" "$endpoint" "$deployment_name" "$api_key"
                    save_configuration "$RESOURCE_GROUP_NAME" "$service_name" "$endpoint" "$deployment_name" "$api_key"
                    
                    log_info "Using existing deployment. Configuration saved to $CONFIG_FILE"
                    exit 0
                else
                    log_error "Failed to retrieve API key for existing deployment."
                    exit 1
                fi
            else
                log_warn "Force redeploy requested. Existing resources will be updated."
            fi
        fi
    else
        log_info "Creating resource group: $RESOURCE_GROUP_NAME"
        if ! az group create \
            --name "$RESOURCE_GROUP_NAME" \
            --location "$LOCATION" \
            --output table; then
            log_error "Failed to create resource group."
            exit 1
        fi
    fi
    
    # Deploy the ARM template
    log_info "Deploying Azure OpenAI resources..."
    local deployment_output
    if deployment_output=$(az deployment group create \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --template-file "$TEMPLATE_FILE" \
        --name "$DEPLOYMENT_NAME" \
        --output json 2>&1); then
        
        log_info "Deployment completed successfully!"
        
        # Extract outputs with error handling
        local openai_endpoint openai_service_name deployment_name_output
        if ! openai_endpoint=$(echo "$deployment_output" | jq -r '.properties.outputs.openAiEndpoint.value' 2>/dev/null); then
            log_error "Failed to extract OpenAI endpoint from deployment output."
            exit 1
        fi
        
        if ! openai_service_name=$(echo "$deployment_output" | jq -r '.properties.outputs.openAiServiceName.value' 2>/dev/null); then
            log_error "Failed to extract OpenAI service name from deployment output."
            exit 1
        fi
        
        if ! deployment_name_output=$(echo "$deployment_output" | jq -r '.properties.outputs.deploymentName.value' 2>/dev/null); then
            log_error "Failed to extract deployment name from deployment output."
            exit 1
        fi
        
        # Get the API key with retry logic
        log_info "Retrieving API key..."
        local api_key
        local retry_count=0
        local max_retries=5
        
        while [ $retry_count -lt $max_retries ]; do
            if api_key=$(az cognitiveservices account keys list \
                --name "$openai_service_name" \
                --resource-group "$RESOURCE_GROUP_NAME" \
                --query "key1" \
                --output tsv 2>/dev/null); then
                break
            else
                retry_count=$((retry_count + 1))
                log_warn "Failed to retrieve API key (attempt $retry_count/$max_retries). Retrying in 10 seconds..."
                sleep 10
            fi
        done
        
        if [ $retry_count -eq $max_retries ]; then
            log_error "Failed to retrieve API key after $max_retries attempts."
            exit 1
        fi
        
        # Display and save configuration
        display_configuration "$RESOURCE_GROUP_NAME" "$openai_service_name" "$openai_endpoint" "$deployment_name_output" "$api_key"
        save_configuration "$RESOURCE_GROUP_NAME" "$openai_service_name" "$openai_endpoint" "$deployment_name_output" "$api_key"
        
    else
        log_error "Deployment failed. Error output:"
        echo "$deployment_output" | jq -r '.error.message // .message // .' 2>/dev/null || echo "$deployment_output"
        exit 1
    fi
    
    log_info "TrueSight infrastructure deployment complete!"
}

display_configuration() {
    local rg_name="$1"
    local service_name="$2"
    local endpoint="$3"
    local deployment_name="$4"
    local api_key="$5"
    
    # Mask API key for display (show only first 8 and last 4 characters)
    local masked_key="********"
    if [ ${#api_key} -gt 12 ]; then
        masked_key="${api_key:0:8}...${api_key: -4}"
    fi
    
    echo ""
    log_info "=== TrueSight Configuration ==="
    echo "Resource Group: $rg_name"
    echo "OpenAI Service Name: $service_name"
    echo "Endpoint: $endpoint"
    echo "Deployment Name: $deployment_name"
    echo "API Key: $masked_key (masked for security)"
    echo ""
    log_info "Complete configuration (including full API key) saved to $CONFIG_FILE"
    echo ""
    log_warn "Keep your API key secure and do not share it publicly!"
}

save_configuration() {
    local rg_name="$1"
    local service_name="$2"
    local endpoint="$3"
    local deployment_name="$4"
    local api_key="$5"
    
    # SECURITY WARNING: This file contains sensitive API keys
    # Make sure it's in .gitignore and never committed to version control
    cat > "$CONFIG_FILE" << EOF
TrueSight Configuration
======================
Resource Group: $rg_name
OpenAI Service Name: $service_name
Endpoint: $endpoint
Deployment Name: $deployment_name
API Key: $api_key

SECURITY WARNING: This file contains sensitive API keys. 
Do not commit this file to version control or share it publicly.

Instructions:
1. Open Lightroom Classic
2. Go to Help > Missing Opsin Help
3. Click the configuration button
4. Enter the Endpoint and API Key values above
5. Set the Deployment Name to: $deployment_name
EOF
    
    # Set restrictive permissions on the config file
    chmod 600 "$CONFIG_FILE" 2>/dev/null || true
    
    log_info "Configuration saved to $CONFIG_FILE (with restricted permissions)"
}

# Run main function
main "$@"