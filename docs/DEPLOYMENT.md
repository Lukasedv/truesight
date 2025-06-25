# Missing Opsin Deployment Guide

This guide provides detailed instructions for deploying Missing Opsin in various environments.

## Development Environment

### Prerequisites

- Adobe Lightroom Classic 6.0+
- Azure subscription with OpenAI access
- Azure CLI installed
- Git

### Step-by-Step Development Setup

1. **Clone Repository**
   ```bash
   git clone https://github.com/Lukasedv/missing-opsin.git
   cd missing-opsin
   ```

2. **Azure Login**
   ```bash
   az login
   ```

3. **Deploy Development Infrastructure**
   ```bash
   cd azure-infrastructure
   ./deploy.sh
   ```

4. **Install Plugin in Lightroom**
   - Open Lightroom Classic
   - File > Plug-in Manager
   - Add > Select `lightroom-plugin.lrplugin` folder
   - Done

5. **Configure Plugin**
   - Use the endpoint and API key from deployment output
   - Help > Missing Opsin Help > Configuration

## Production Environment

### Infrastructure Deployment

1. **Create Service Principal**
   ```bash
   az ad sp create-for-rbac \
     --name "missing-opsin-prod-sp" \
     --role "Contributor" \
     --scopes "/subscriptions/{subscription-id}/resourceGroups/missing-opsin-prod-rg"
   ```

2. **Deploy with ARM Template**
   ```bash
   az deployment group create \
     --resource-group "missing-opsin-prod-rg" \
     --template-file azure-infrastructure/deploy-openai.json \
     --parameters \
       openAiServiceName="missing-opsin-openai-prod" \
       deploymentName="gpt-4o-prod" \
       deploymentCapacity=100
   ```

3. **Configure Monitoring**
   ```bash
   # Enable diagnostic settings
   az monitor diagnostic-settings create \
     --resource "/subscriptions/{sub-id}/resourceGroups/missing-opsin-prod-rg/providers/Microsoft.CognitiveServices/accounts/missing-opsin-openai-prod" \
     --name "missing-opsin-diagnostics" \
     --logs '[{"category":"RequestResponse","enabled":true}]' \
     --metrics '[{"category":"AllMetrics","enabled":true}]' \
     --workspace "/subscriptions/{sub-id}/resourceGroups/missing-opsin-prod-rg/providers/Microsoft.OperationalInsights/workspaces/missing-opsin-workspace"
   ```

### Plugin Distribution

1. **Create Release Package**
   ```bash
   mkdir -p release
   cp -r lightroom-plugin.lrplugin release/Missing Opsin.lrplugin
   cd release
   zip -r Missing Opsin-v1.0.0.zip Missing Opsin.lrplugin/
   ```

2. **Digital Signing** (Optional)
   - Use Adobe's signing process for official distribution
   - Include certificate validation

## Multi-Environment Strategy

### Environment Configuration

```bash
# Development
RESOURCE_GROUP="missing-opsin-dev-rg"
OPENAI_SERVICE="missing-opsin-openai-dev"
DEPLOYMENT_CAPACITY=20

# Staging
RESOURCE_GROUP="missing-opsin-staging-rg"
OPENAI_SERVICE="missing-opsin-openai-staging"
DEPLOYMENT_CAPACITY=50

# Production
RESOURCE_GROUP="missing-opsin-prod-rg"
OPENAI_SERVICE="missing-opsin-openai-prod"
DEPLOYMENT_CAPACITY=100
```

### CI/CD Pipeline Configuration

1. **GitHub Secrets Setup**
   ```
   AZURE_CREDENTIALS_DEV
   AZURE_CREDENTIALS_STAGING
   AZURE_CREDENTIALS_PROD
   ```

2. **Environment Protection Rules**
   - Staging: Require pull request reviews
   - Production: Require manual approval

## Monitoring and Maintenance

### Health Checks

1. **API Endpoint Monitoring**
   ```bash
   # Test endpoint availability
   curl -H "api-key: $API_KEY" \
        -H "Content-Type: application/json" \
        "$ENDPOINT/openai/deployments/$DEPLOYMENT_NAME/chat/completions?api-version=2024-02-15-preview" \
        -d '{"messages":[{"role":"user","content":"test"}],"max_tokens":5}'
   ```

2. **Cost Monitoring**
   ```bash
   # Check current month costs
   az consumption usage list \
     --start-date $(date -d "$(date +%Y-%m-01)" +%Y-%m-%d) \
     --end-date $(date +%Y-%m-%d) \
     --query "[?contains(resourceName,'missing-opsin')]"
   ```

### Backup and Recovery

1. **Configuration Backup**
   ```bash
   # Export ARM template
   az group export \
     --resource-group "missing-opsin-prod-rg" \
     --output-path "backup-$(date +%Y%m%d).json"
   ```

2. **Key Rotation**
   ```bash
   # Regenerate API keys
   az cognitiveservices account keys regenerate \
     --name "missing-opsin-openai-prod" \
     --resource-group "missing-opsin-prod-rg" \
     --key-name "Key1"
   ```

### Performance Optimization

1. **Model Deployment Scaling**
   ```bash
   # Scale deployment capacity
   az cognitiveservices deployment update \
     --name "missing-opsin-openai-prod" \
     --resource-group "missing-opsin-prod-rg" \
     --deployment-name "gpt-4o-prod" \
     --sku-capacity 200
   ```

2. **Request Rate Limiting**
   - Implement client-side rate limiting
   - Monitor 429 (Too Many Requests) responses
   - Implement exponential backoff

## Troubleshooting

### Common Issues

1. **Authentication Errors**
   ```bash
   # Verify API key
   az cognitiveservices account keys list \
     --name "missing-opsin-openai-prod" \
     --resource-group "missing-opsin-prod-rg"
   ```

2. **Quota Exceeded**
   ```bash
   # Check quota usage
   az cognitiveservices usage list \
     --location "eastus" \
     --query "[?contains(name.value,'OpenAI')]"
   ```

3. **Plugin Loading Issues**
   - Check Lightroom error logs
   - Verify Lua syntax
   - Test with minimal configuration

### Support Escalation

1. **Azure Support**
   - Create support ticket through Azure portal
   - Include resource IDs and error messages

2. **Community Support**
   - GitHub Issues for plugin-specific problems
   - Adobe forums for Lightroom integration issues

## Security Considerations

### Network Security

1. **Private Endpoints**
   ```bash
   # Create private endpoint for OpenAI service
   az network private-endpoint create \
     --name "missing-opsin-openai-pe" \
     --resource-group "missing-opsin-prod-rg" \
     --vnet-name "missing-opsin-vnet" \
     --subnet "missing-opsin-subnet" \
     --private-connection-resource-id "/subscriptions/{sub-id}/resourceGroups/missing-opsin-prod-rg/providers/Microsoft.CognitiveServices/accounts/missing-opsin-openai-prod" \
     --connection-name "missing-opsin-openai-connection" \
     --group-ids "account"
   ```

2. **Firewall Rules**
   ```bash
   # Configure network access rules
   az cognitiveservices account network-rule add \
     --name "missing-opsin-openai-prod" \
     --resource-group "missing-opsin-prod-rg" \
     --ip-address "203.0.113.0/24"
   ```

### Data Protection

1. **Encryption at Rest**
   - Enabled by default for Azure OpenAI
   - Customer-managed keys available

2. **Encryption in Transit**
   - HTTPS enforced for all API calls
   - TLS 1.2 minimum

### Compliance

1. **Data Residency**
   - Choose appropriate Azure region
   - Review data processing locations

2. **Audit Logging**
   ```bash
   # Enable audit logs
   az monitor diagnostic-settings create \
     --resource "/subscriptions/{sub-id}/resourceGroups/missing-opsin-prod-rg/providers/Microsoft.CognitiveServices/accounts/missing-opsin-openai-prod" \
     --name "audit-logs" \
     --logs '[{"category":"Audit","enabled":true}]'
   ```

## Cost Optimization

### Usage Monitoring

1. **Set Budget Alerts**
   ```bash
   az consumption budget create \
     --budget-name "missing-opsin-monthly-budget" \
     --resource-group "missing-opsin-prod-rg" \
     --amount 500 \
     --time-grain "Monthly" \
     --notifications amount=450 contactEmails="admin@example.com"
   ```

2. **Usage Analytics**
   - Monitor token consumption
   - Track cost per analysis
   - Optimize image processing

### Efficiency Improvements

1. **Image Optimization**
   - Resize images before analysis
   - Use appropriate JPEG quality
   - Implement caching where possible

2. **Batch Processing**
   - Group similar images
   - Use async processing
   - Implement retry logic

This deployment guide provides a comprehensive approach to setting up Missing Opsin in various environments while maintaining security, performance, and cost efficiency.