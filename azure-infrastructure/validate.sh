#!/bin/bash

# TrueSight Azure Infrastructure Validation Script
# This script validates that the Azure OpenAI deployment is working correctly

set -euo pipefail

# Configuration - can be overridden via environment variables
RESOURCE_GROUP_NAME="${RESOURCE_GROUP_NAME:-truesight-rg}"
CONFIG_FILE="${CONFIG_FILE:-truesight-config.txt}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

log_debug() {
    echo -e "${BLUE}[DEBUG]${NC} $1"
}

show_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Validate Azure OpenAI infrastructure for Missing Opsin Lightroom plugin.

Environment Variables:
  RESOURCE_GROUP_NAME    Name of the resource group (default: truesight-rg)
  CONFIG_FILE           Configuration file path (default: truesight-config.txt)

Options:
  -h, --help           Show this help message
  -r, --resource-group NAME  Override resource group name
  -c, --config-file FILE     Override configuration file path
  --test-api           Test the OpenAI API endpoint
  --detailed           Show detailed resource information

Examples:
  $0                           # Basic validation
  $0 --test-api               # Include API endpoint testing
  $0 --detailed               # Show detailed information
  $0 -r my-rg                 # Validate specific resource group
EOF
}

check_prerequisites() {
    local missing_deps=()
    
    # Check if Azure CLI is installed
    if ! command -v az &> /dev/null; then
        missing_deps+=("Azure CLI")
    fi
    
    # Check if curl is installed (for API testing)
    if ! command -v curl &> /dev/null; then
        missing_deps+=("curl")
    fi
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        log_error "Missing required dependencies: ${missing_deps[*]}"
        return 1
    fi
    
    # Check if user is logged in to Azure
    if ! az account show &> /dev/null; then
        log_error "You are not logged in to Azure CLI. Please run 'az login' first."
        return 1
    fi
    
    return 0
}

validate_resource_group() {
    local rg_name="$1"
    
    log_info "Validating resource group: $rg_name"
    
    if ! az group show --name "$rg_name" &> /dev/null; then
        log_error "Resource group '$rg_name' does not exist."
        return 1
    fi
    
    local location
    location=$(az group show --name "$rg_name" --query "location" --output tsv)
    log_info "✓ Resource group exists in location: $location"
    
    return 0
}

validate_openai_service() {
    local rg_name="$1"
    local detailed="$2"
    
    log_info "Validating OpenAI service..."
    
    # Get OpenAI services in the resource group
    local openai_services
    openai_services=$(az cognitiveservices account list --resource-group "$rg_name" --query "[?kind=='OpenAI']" --output json)
    
    if [ "$openai_services" = "[]" ]; then
        log_error "No OpenAI services found in resource group."
        return 1
    fi
    
    local service_count
    service_count=$(echo "$openai_services" | jq -r '. | length')
    
    if [ "$service_count" -gt 1 ]; then
        log_warn "Multiple OpenAI services found ($service_count). Using the first one."
    fi
    
    # Get service details
    local service_name endpoint location sku
    service_name=$(echo "$openai_services" | jq -r '.[0].name')
    endpoint=$(echo "$openai_services" | jq -r '.[0].properties.endpoint')
    location=$(echo "$openai_services" | jq -r '.[0].location')
    sku=$(echo "$openai_services" | jq -r '.[0].sku.name')
    
    log_info "✓ OpenAI service found: $service_name"
    log_info "  Endpoint: $endpoint"
    log_info "  Location: $location"
    log_info "  SKU: $sku"
    
    if [ "$detailed" = "true" ]; then
        local provisioning_state public_access
        provisioning_state=$(echo "$openai_services" | jq -r '.[0].properties.provisioningState')
        public_access=$(echo "$openai_services" | jq -r '.[0].properties.publicNetworkAccess')
        
        log_debug "  Provisioning State: $provisioning_state"
        log_debug "  Public Network Access: $public_access"
    fi
    
    # Validate deployments
    log_info "Validating model deployments..."
    
    local deployments
    deployments=$(az cognitiveservices account deployment list --name "$service_name" --resource-group "$rg_name" --output json)
    
    if [ "$deployments" = "[]" ]; then
        log_error "No model deployments found."
        return 1
    fi
    
    local deployment_count
    deployment_count=$(echo "$deployments" | jq -r '. | length')
    log_info "✓ Found $deployment_count model deployment(s)"
    
    # Show deployment details
    echo "$deployments" | jq -r '.[] | "  - " + .name + " (" + .properties.model.name + " " + .properties.model.version + ")"'
    
    if [ "$detailed" = "true" ]; then
        log_debug "Deployment details:"
        echo "$deployments" | jq -r '.[] | "  " + .name + ": " + (.sku.capacity | tostring) + "K TPM, Status: " + .properties.provisioningState'
    fi
    
    # Export service details for API testing
    export OPENAI_SERVICE_NAME="$service_name"
    export OPENAI_ENDPOINT="$endpoint"
    export OPENAI_DEPLOYMENT_NAME="$(echo "$deployments" | jq -r '.[0].name')"
    
    return 0
}

test_api_endpoint() {
    local rg_name="$1"
    
    if [ -z "${OPENAI_SERVICE_NAME:-}" ] || [ -z "${OPENAI_ENDPOINT:-}" ] || [ -z "${OPENAI_DEPLOYMENT_NAME:-}" ]; then
        log_error "Service details not available for API testing."
        return 1
    fi
    
    log_info "Testing OpenAI API endpoint..."
    
    # Get API key
    local api_key
    if ! api_key=$(az cognitiveservices account keys list \
        --name "$OPENAI_SERVICE_NAME" \
        --resource-group "$rg_name" \
        --query "key1" \
        --output tsv 2>/dev/null); then
        log_error "Failed to retrieve API key."
        return 1
    fi
    
    # Test API endpoint with a simple request
    local api_url="${OPENAI_ENDPOINT}openai/deployments/${OPENAI_DEPLOYMENT_NAME}/chat/completions?api-version=2024-02-01"
    
    local response
    response=$(curl -s -w "\n%{http_code}" \
        -H "Content-Type: application/json" \
        -H "api-key: $api_key" \
        -d '{
            "messages": [
                {"role": "system", "content": "You are a helpful assistant."},
                {"role": "user", "content": "Hello, this is a test message."}
            ],
            "max_tokens": 10,
            "temperature": 0.1
        }' \
        "$api_url" 2>/dev/null)
    
    local http_code
    http_code=$(echo "$response" | tail -n1)
    local response_body
    response_body=$(echo "$response" | head -n -1)
    
    if [ "$http_code" = "200" ]; then
        log_info "✓ API endpoint is working correctly"
        
        # Extract and show response
        local content
        if content=$(echo "$response_body" | jq -r '.choices[0].message.content' 2>/dev/null); then
            log_debug "API Response: $content"
        fi
    else
        log_error "API endpoint test failed (HTTP $http_code)"
        log_error "Response: $response_body"
        return 1
    fi
    
    return 0
}

check_configuration_file() {
    local config_file="$1"
    
    if [ ! -f "$config_file" ]; then
        log_warn "Configuration file '$config_file' not found."
        return 1
    fi
    
    log_info "✓ Configuration file exists: $config_file"
    
    # Check if configuration file contains required fields
    local required_fields=("Endpoint" "API Key" "Deployment Name")
    local missing_fields=()
    
    for field in "${required_fields[@]}"; do
        if ! grep -q "^$field:" "$config_file"; then
            missing_fields+=("$field")
        fi
    done
    
    if [ ${#missing_fields[@]} -gt 0 ]; then
        log_warn "Configuration file is missing required fields: ${missing_fields[*]}"
        return 1
    fi
    
    log_info "✓ Configuration file contains all required fields"
    return 0
}

# Parse command line arguments
DETAILED=false
TEST_API=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_usage
            exit 0
            ;;
        -r|--resource-group)
            RESOURCE_GROUP_NAME="$2"
            shift 2
            ;;
        -c|--config-file)
            CONFIG_FILE="$2"
            shift 2
            ;;
        --test-api)
            TEST_API=true
            shift
            ;;
        --detailed)
            DETAILED=true
            shift
            ;;
        *)
            log_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Main validation function
main() {
    log_info "TrueSight infrastructure validation"
    log_info "Resource Group: $RESOURCE_GROUP_NAME"
    log_info "Config File: $CONFIG_FILE"
    echo ""
    
    # Check prerequisites
    if ! check_prerequisites; then
        exit 1
    fi
    
    local validation_failed=false
    
    # Validate resource group
    if ! validate_resource_group "$RESOURCE_GROUP_NAME"; then
        validation_failed=true
    fi
    
    # Validate OpenAI service
    if ! validate_openai_service "$RESOURCE_GROUP_NAME" "$DETAILED"; then
        validation_failed=true
    fi
    
    # Test API endpoint if requested
    if [ "$TEST_API" = "true" ] && [ "$validation_failed" = "false" ]; then
        if ! test_api_endpoint "$RESOURCE_GROUP_NAME"; then
            validation_failed=true
        fi
    fi
    
    # Check configuration file
    if ! check_configuration_file "$CONFIG_FILE"; then
        log_warn "Configuration file validation failed, but this is not critical."
    fi
    
    echo ""
    if [ "$validation_failed" = "true" ]; then
        log_error "Validation failed. Please check the errors above."
        exit 1
    else
        log_info "✓ All validations passed! Your TrueSight infrastructure is ready."
        
        if [ "$TEST_API" != "true" ]; then
            log_info "Run with --test-api to test the OpenAI API endpoint."
        fi
    fi
}

# Run main function
main "$@"
