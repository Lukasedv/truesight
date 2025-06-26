# Missing Opsin - Lightroom Plugin for Color Deficiency Support

A Lightroom Classic plugin that helps photographers with color deficiency analyze and correct their photos using Azure OpenAI's GPT-4 capabilities.

## Features

- **AI-Powered Color Analysis**: Uses Azure OpenAI GPT-4 to analyze color balance, skin tones, and overall color harmony
- **Batch Processing**: Analyze multiple photos at once
- **Actionable Recommendations**: Get specific Lightroom adjustment suggestions
- **Easy Configuration**: Simple setup with Azure OpenAI credentials

## Installation

1. Copy the `missingopsin.lrplugin` folder to your Lightroom plugins directory
2. Open Lightroom Classic
3. Go to File > Plug-in Manager
4. Click "Add" and select the `missingopsin.lrplugin` folder
5. Enable the plugin

## Configuration

1. Go to **Help > Missing Opsin Help** for setup instructions
2. Click **Configuration** to open settings
3. Enter your Azure OpenAI details:
   - **Endpoint**: `https://your-resource.openai.azure.com/`
   - **API Key**: `your-api-key-here`
   - **Deployment**: `your-deployment-name`
4. Click **Test Connection** to verify setup
5. Click **Save** to store your configuration

## Usage

### Color Analysis
1. Select one or more photos in the Library module
2. Go to **Library > Missing Opsin Color Analysis**
3. Click **Analyze Colors** to start the AI analysis
4. Review the AI-generated recommendations
5. Apply suggested adjustments manually in the Develop module

### Menu Options
- **Library > Missing Opsin Color Analysis**: Main analysis interface
- **Library > Missing Opsin Settings**: Configuration dialog
- **Help > Missing Opsin Help**: Help and quick configuration
- **File > Export > Analyze Colors with Missing Opsin**: Export integration (coming soon)

## Azure OpenAI Configuration

The plugin requires an Azure OpenAI service with:
- GPT-4 or GPT-4 Turbo deployment
- Chat Completions API access
- Proper API key authentication

Default configuration from `truesight-config.txt`:
```
Endpoint: https://your-resource.openai.azure.com/
Deployment: your-deployment-name
API Key: your-api-key-here
```

## Troubleshooting

### Connection Issues
- Verify your Azure OpenAI endpoint URL is correct
- Check that your API key is valid and has proper permissions
- Ensure the deployment name matches your Azure OpenAI deployment
- Test the connection using the built-in test feature

### Analysis Issues
- Make sure photos are selected before running analysis
- Check that your Azure OpenAI service has sufficient quota
- Review the plugin logs in Lightroom for detailed error messages

### Configuration Problems
- Use the "Use Default Configuration" button for quick setup
- Verify that all three fields (endpoint, API key, deployment) are configured
- Check for trailing slashes in the endpoint URL (the plugin handles this automatically)

## Technical Details

- **API Version**: Uses Azure OpenAI API version 2024-06-01 (stable release compatible with Lightroom)
- **Model**: GPT-4.1 (2025-04-14) with optimized prompts for color analysis
- **Capacity**: 50K tokens per minute with higher request limits
- **Response Format**: Structured recommendations for Lightroom adjustments
- **Error Handling**: Comprehensive error reporting and logging

## Version History

- **v1.0.0**: Initial release with Azure OpenAI integration
  - Color analysis using GPT-4
  - Batch processing support
  - Configuration management
  - Connection testing

## Support

For technical support or feature requests, check the plugin logs in Lightroom Classic and review the error messages in the analysis dialog.

## Security Note

This plugin handles sensitive API keys. The configuration is stored locally in Lightroom preferences and is not transmitted to any third parties except your configured Azure OpenAI endpoint.
