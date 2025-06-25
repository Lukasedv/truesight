#!/bin/bash

# TrueSight Azure Infrastructure Cleanup Script
# This script safely removes Azure OpenAI resources deployed for the TrueSight plugin

set -euo pipefail

# Configuration - can be overridden via environment variables
RESOURCE_GROUP_NAME="${RESOURCE_GROUP_NAME:-truesight-rg}"
CONFIRM_DELETION="${CONFIRM_DELETION:-false}"

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

Cleanup Azure OpenAI infrastructure for TrueSight Lightroom plugin.

Environment Variables:
  RESOURCE_GROUP_NAME    Name of the resource group to cleanup (default: truesight-rg)
  CONFIRM_DELETION       Skip confirmation prompt (default: false)

Options:
  -h, --help           Show this help message
  -y, --yes            Skip confirmation prompts
  -r, --resource-group NAME  Override resource group name
  --list-only          List resources that would be deleted without deleting them

Examples:
  $0                           # Interactive cleanup with confirmation
  $0 --yes                     # Automatic cleanup without confirmation
  $0 --list-only              # List resources without deleting
  $0 -r my-rg                 # Cleanup specific resource group
EOF
}

check_prerequisites() {
    # Check if Azure CLI is installed
    if ! command -v az &> /dev/null; then
        log_error "Azure CLI is not installed. Please install it first:"
        log_error "https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
        return 1
    fi
    
    # Check if user is logged in to Azure
    if ! az account show &> /dev/null; then
        log_error "You are not logged in to Azure CLI. Please run 'az login' first."
        return 1
    fi
    
    return 0
}

list_resources() {
    local resource_group="$1"
    
    if ! az group show --name "$resource_group" &> /dev/null; then
        log_warn "Resource group '$resource_group' does not exist."
        return 1
    fi
    
    log_info "Resources in resource group '$resource_group':"
    
    # List all resources in the resource group
    local resources
    resources=$(az resource list --resource-group "$resource_group" --output table 2>/dev/null)
    
    if [ -z "$resources" ] || [ "$(echo "$resources" | wc -l)" -le 2 ]; then
        log_info "No resources found in resource group."
        return 1
    else
        echo "$resources"
        return 0
    fi
}

confirm_deletion() {
    if [ "$CONFIRM_DELETION" = "true" ]; then
        return 0
    fi
    
    echo ""
    log_warn "This will permanently delete all resources in the resource group: $RESOURCE_GROUP_NAME"
    log_warn "This action cannot be undone!"
    echo ""
    read -p "Are you sure you want to continue? (type 'yes' to confirm): " -r
    echo ""
    
    if [[ $REPLY = "yes" ]]; then
        return 0
    else
        log_info "Cleanup cancelled."
        return 1
    fi
}

cleanup_resources() {
    local resource_group="$1"
    
    log_info "Starting cleanup of resource group: $resource_group"
    
    # Check if resource group exists
    if ! az group show --name "$resource_group" &> /dev/null; then
        log_warn "Resource group '$resource_group' does not exist. Nothing to cleanup."
        return 0
    fi
    
    # List resources before deletion
    if ! list_resources "$resource_group"; then
        log_info "Resource group exists but contains no resources."
        
        # Ask if user wants to delete the empty resource group
        if [ "$CONFIRM_DELETION" != "true" ]; then
            read -p "Delete empty resource group? (y/N): " -r
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                log_info "Keeping empty resource group."
                return 0
            fi
        fi
    else
        # Confirm deletion
        if ! confirm_deletion; then
            return 1
        fi
    fi
    
    # Delete the resource group and all its resources
    log_info "Deleting resource group and all resources..."
    if az group delete --name "$resource_group" --yes --no-wait; then
        log_info "Deletion initiated. This may take several minutes to complete."
        log_info "You can check the status with: az group show --name $resource_group"
    else
        log_error "Failed to initiate resource group deletion."
        return 1
    fi
}

# Parse command line arguments
LIST_ONLY=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_usage
            exit 0
            ;;
        -y|--yes)
            CONFIRM_DELETION="true"
            shift
            ;;
        -r|--resource-group)
            RESOURCE_GROUP_NAME="$2"
            shift 2
            ;;
        --list-only)
            LIST_ONLY=true
            shift
            ;;
        *)
            log_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Main execution
main() {
    log_info "TrueSight infrastructure cleanup"
    log_info "Resource Group: $RESOURCE_GROUP_NAME"
    
    # Check prerequisites
    if ! check_prerequisites; then
        exit 1
    fi
    
    if [ "$LIST_ONLY" = "true" ]; then
        if list_resources "$RESOURCE_GROUP_NAME"; then
            log_info "Use '$0 -r $RESOURCE_GROUP_NAME --yes' to delete these resources."
        fi
        exit 0
    fi
    
    # Perform cleanup
    if cleanup_resources "$RESOURCE_GROUP_NAME"; then
        log_info "Cleanup completed successfully!"
    else
        log_error "Cleanup failed or was cancelled."
        exit 1
    fi
}

# Run main function
main "$@"
