# TrueSight Azure Infrastructure

This directory contains the Azure infrastructure deployment scripts for the TrueSight Lightroom plugin. The infrastructure includes Azure OpenAI services required for the plugin's AI-powered image analysis capabilities.

## Overview

The infrastructure consists of:
- **Azure OpenAI Service**: Provides GPT-4o model for image analysis
- **Model Deployment**: Configured deployment of the GPT-4o model
- **Resource Group**: Container for all TrueSight resources

## Prerequisites

Before deploying the infrastructure, ensure you have:

1. **Azure CLI** installed and configured
   ```bash
   # Install Azure CLI (Ubuntu/Debian)
   curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
   
   # Or using package manager
   sudo apt-get install azure-cli
   ```

2. **jq** for JSON processing
   ```bash
   sudo apt-get install jq
   ```

3. **Azure subscription** with sufficient quotas for OpenAI services

4. **Azure CLI login**
   ```bash
   az login
   ```

## Quick Start

### 1. Deploy Infrastructure

```bash
# Deploy with default settings
./deploy.sh

# Deploy with custom resource group and location
./deploy.sh -r my-truesight-rg -l westus2

# Force redeploy existing resources
./deploy.sh --force
```

### 2. Validate Deployment

```bash
# Basic validation
./validate.sh

# Detailed validation with API testing
./validate.sh --test-api --detailed
```

### 3. Configure TrueSight Plugin

After successful deployment, use the configuration values from `truesight-config.txt` to configure the TrueSight Lightroom plugin.

## Scripts

### deploy.sh

Main deployment script that creates all required Azure resources.

**Features:**
- ✅ Idempotent operations (safe to run multiple times)
- ✅ Detects existing resources and avoids conflicts
- ✅ Comprehensive error handling and validation
- ✅ Configurable via environment variables or command-line options
- ✅ Retry logic for API key retrieval
- ✅ Saves configuration to file for easy plugin setup

**Usage:**
```bash
./deploy.sh [OPTIONS]

Options:
  -h, --help                   Show help message
  -f, --force                  Force redeployment of existing resources
  -c, --check                  Check if resources exist without deploying
  -r, --resource-group NAME    Override resource group name
  -l, --location LOCATION      Override deployment location

Environment Variables:
  RESOURCE_GROUP_NAME         Name of the resource group (default: truesight-rg)
  LOCATION                    Azure region (default: eastus)
  TEMPLATE_FILE              ARM template file (default: deploy-openai.json)
  CONFIG_FILE                Output configuration file (default: truesight-config.txt)
  FORCE_REDEPLOY             Force redeployment (default: false)
```

### validate.sh

Validation script to verify the deployment is working correctly.

**Features:**
- ✅ Validates resource group and OpenAI service
- ✅ Checks model deployments
- ✅ Tests API endpoint functionality
- ✅ Verifies configuration file
- ✅ Detailed resource information display

**Usage:**
```bash
./validate.sh [OPTIONS]

Options:
  -h, --help                   Show help message
  -r, --resource-group NAME    Override resource group name
  -c, --config-file FILE       Override configuration file path
  --test-api                   Test the OpenAI API endpoint
  --detailed                   Show detailed resource information
```

### cleanup.sh

Safe cleanup script to remove deployed resources.

**Features:**
- ✅ Lists resources before deletion
- ✅ Confirmation prompts for safety
- ✅ Handles non-existent resources gracefully
- ✅ Option to delete empty resource groups

**Usage:**
```bash
./cleanup.sh [OPTIONS]

Options:
  -h, --help                   Show help message
  -y, --yes                    Skip confirmation prompts
  -r, --resource-group NAME    Override resource group name
  --list-only                  List resources without deleting them
```

## Configuration

### Environment Variables

You can override default settings using environment variables:

```bash
# Override resource group name
export RESOURCE_GROUP_NAME="my-truesight-rg"

# Override location
export LOCATION="westus2"

# Override configuration file
export CONFIG_FILE="my-config.txt"

# Force redeployment
export FORCE_REDEPLOY="true"

./deploy.sh
```

### ARM Template Parameters

The `deploy-openai.json` ARM template supports the following parameters:

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `openAiServiceName` | string | `truesight-openai-{unique}` | Name of the Azure OpenAI service |
| `location` | string | Resource group location | Azure region for deployment |
| `sku` | string | `S0` | Pricing tier of the Azure OpenAI service |
| `deploymentName` | string | `gpt-4o-deployment` | Name of the model deployment |
| `modelName` | string | `gpt-4o` | The model to deploy |
| `modelVersion` | string | `2024-08-06` | Version of the model |
| `deploymentCapacity` | int | `20` | Capacity in thousands of tokens per minute |
| `publicNetworkAccess` | string | `Enabled` | Public network access setting |
| `tags` | object | Standard tags | Tags to apply to resources |

## Supported Azure Regions

The following Azure regions support OpenAI services:

- East US (`eastus`)
- East US 2 (`eastus2`)
- West US (`westus`)
- West US 2 (`westus2`)
- West US 3 (`westus3`)
- Central US (`centralus`)
- North Central US (`northcentralus`)
- South Central US (`southcentralus`)
- West Central US (`westcentralus`)
- Canada East (`canadaeast`)
- Canada Central (`canadacentral`)
- North Europe (`northeurope`)
- West Europe (`westeurope`)
- UK South (`uksouth`)
- UK West (`ukwest`)
- France Central (`francecentral`)
- Switzerland North (`switzerlandnorth`)
- Germany West Central (`germanywestcentral`)
- Norway East (`norwayeast`)
- Japan East (`japaneast`)
- Japan West (`japanwest`)
- Southeast Asia (`southeastasia`)
- East Asia (`eastasia`)
- Australia East (`australiaeast`)
- Australia Southeast (`australiasoutheast`)
- Korea Central (`koreacentral`)
- Central India (`centralindia`)
- South Africa North (`southafricanorth`)
- UAE North (`uaenorth`)
- Brazil South (`brazilsouth`)

## Error Handling and Recovery

### Common Issues and Solutions

1. **Resource Already Exists**
   - The scripts detect existing resources and can reuse them
   - Use `--force` flag to redeploy existing resources
   - Use `--check` flag to view existing configuration

2. **Insufficient Quota**
   - Check your Azure subscription quotas for Cognitive Services
   - Request quota increases if needed
   - Try a different Azure region

3. **Authentication Issues**
   - Ensure you're logged in: `az login`
   - Check subscription access: `az account show`
   - Verify permissions for resource creation

4. **API Key Retrieval Failures**
   - The script includes retry logic for API key retrieval
   - Wait for the service to be fully provisioned
   - Check service status in Azure portal

### Recovery Procedures

1. **Partial Deployment Failure**
   ```bash
   # Check current state
   ./validate.sh --detailed
   
   # Clean up if needed
   ./cleanup.sh --list-only
   
   # Redeploy
   ./deploy.sh --force
   ```

2. **Configuration File Lost**
   ```bash
   # Check existing deployment
   ./deploy.sh --check
   
   # This will regenerate the configuration file
   ```

## Security Considerations

- **API Keys**: Store API keys securely and rotate them regularly
- **Network Access**: Consider using private endpoints for production deployments
- **Resource Tags**: All resources are tagged for proper governance
- **Managed Identity**: The OpenAI service uses system-assigned managed identity

## Cost Management

- **Pricing**: Azure OpenAI uses a consumption-based pricing model
- **Capacity**: Default deployment capacity is 20K tokens per minute
- **Monitoring**: Use Azure Cost Management to monitor spending
- **Cleanup**: Use the cleanup script to remove resources when not needed

## Support and Troubleshooting

### Debugging

Enable verbose logging:
```bash
# For Azure CLI debugging
export AZURE_CLI_ENABLE_TELEMETRY=false
export AZURE_CORE_COLLECT_TELEMETRY=false

# Run with verbose output
./deploy.sh --force 2>&1 | tee deployment.log
```

### Validation

Always validate your deployment:
```bash
# Comprehensive validation
./validate.sh --test-api --detailed
```

### Getting Help

1. Check the validation output for specific error messages
2. Review the Azure portal for resource status
3. Use Azure CLI diagnostic commands:
   ```bash
   az cognitiveservices account show --name <service-name> --resource-group <rg-name>
   az deployment group list --resource-group <rg-name>
   ```

## Contributing

When modifying the infrastructure scripts:

1. Test thoroughly in a development environment
2. Update this README with any new features or changes
3. Ensure backward compatibility where possible
4. Add appropriate error handling and validation
5. Update the validation script to test new features
