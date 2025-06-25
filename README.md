# Missing Opsin - Lightroom Plugin for Color Deficiency Support

Missing Opsin is a powerful Adobe Lightroom Classic plugin designed to help photographers with color deficiency (color blindness) analyze and correct their photos using AI-powered color analysis through Azure OpenAI's GPT-4 Vision capabilities.

## 🎯 Features

- **AI-Powered Color Analysis**: Uses Azure OpenAI's GPT-4 Vision to analyze photos for color accuracy
- **Intelligent Suggestions**: Provides specific color correction recommendations tailored for color deficiency
- **Automatic Adjustments**: One-click application of suggested corrections
- **Batch Processing**: Analyze multiple photos simultaneously
- **Comprehensive HSL Control**: Fine-tune hue, saturation, and luminance across all color ranges
- **Export Integration**: Analyze colors during the export process

## 🚀 Quick Start

### Prerequisites

- Adobe Lightroom Classic (version 14.4 or later)
- Azure subscription with OpenAI access
- Basic understanding of photo editing

### Compatibility

- **Lightroom Classic**: Version 14.4 or later
- **SDK Version**: 13.0 (minimum 10.0)
- **Operating Systems**: Windows and macOS

### Installation

1. **Download the Plugin**
   ```bash
   git clone https://github.com/Lukasedv/missing-opsin.git
   cd missing-opsin
   ```

2. **Install in Lightroom**
   - Open Lightroom Classic
   - Go to `File > Plug-in Manager`
   - Click `Add` and select the `lightroom-plugin.lrplugin` folder
   - Click `Done`

3. **Deploy Azure Infrastructure**
   ```bash
   cd azure-infrastructure
   ./deploy.sh
   ```

4. **Configure the Plugin**
   - In Lightroom, go to `Help > Missing Opsin Help`
   - Click the configuration button
   - Enter your Azure OpenAI endpoint and API key

## 📖 Usage Guide

### Basic Color Analysis

1. Select one or more photos in the Library module
2. Go to `Library > Missing Opsin Color Analysis`
3. Wait for the AI analysis to complete
4. Review the suggestions and click `Apply Adjustments` if desired

### Export with Analysis

1. Select photos to export
2. Go to `File > Export > Analyze Colors with Missing Opsin`
3. Choose your analysis and export options
4. Click `Export`

### Understanding the Analysis

Missing Opsin analyzes your photos for:

- **Color Balance**: Temperature and tint corrections
- **Skin Tones**: Natural skin color reproduction
- **Color Harmony**: Pleasing color relationships
- **Contrast**: Optimal contrast for visual appeal
- **HSL Adjustments**: Precise hue, saturation, and luminance corrections

## 🏗️ Development Setup

### Local Development

1. **Clone the Repository**
   ```bash
   git clone https://github.com/Lukasedv/missing-opsin.git
   cd missing-opsin
   ```

2. **Install Development Tools**
   ```bash
   # Install Lua for syntax checking
   sudo apt-get install lua5.3
   
   # Install Azure CLI
   curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
   ```

3. **Validate Plugin Code**
   ```bash
   # Check Lua syntax
   find lightroom-plugin.lrplugin -name "*.lua" -exec lua5.3 -l {} \;
   
   # Validate Azure ARM template
   az deployment group validate \
     --resource-group "test-rg" \
     --template-file azure-infrastructure/deploy-openai.json
   ```

### Plugin Structure

```
lightroom-plugin.lrplugin/
├── Info.lua                 # Plugin manifest
├── ColorAnalysis.lua        # Main analysis module
├── AzureOpenAI.lua         # Azure OpenAI integration
├── ColorAdjustments.lua    # Lightroom adjustment application
├── ExportDialog.lua        # Export interface
├── ConfigDialog.lua        # Configuration interface
├── TroubleShoot.lua        # Troubleshooting diagnostics
├── PluginInit.lua          # Plugin initialization
└── help.html               # User documentation
```

## 🔧 Troubleshooting

### Plugin Not Loading

If Missing Opsin doesn't appear in Lightroom menus:

1. **Check Compatibility**: Ensure you're using Lightroom Classic 14.4 or later
2. **Plugin Manager**: Go to `File > Plug-in Manager` to verify Missing Opsin is listed
3. **Run Diagnostics**: Use `Help > Missing Opsin Troubleshooting` for detailed checks
4. **Restart Lightroom**: Close and reopen Lightroom Classic
5. **Reinstall Plugin**: Remove and re-add the plugin if necessary

### Common Issues

- **SDK Version Error**: Update to Lightroom Classic 14.4 or later
- **Module Loading Errors**: Check that all required files are present
- **Configuration Issues**: Verify Azure OpenAI endpoint and API key
- **Network Problems**: Ensure internet connectivity for Azure services

### Diagnostic Tools

The plugin includes built-in diagnostics accessible via `Help > Missing Opsin Troubleshooting`:

- Plugin installation verification
- Lightroom compatibility checks
- Module loading tests
- Azure OpenAI configuration validation

### Getting Help

- Use the built-in troubleshooting tool first
- Check the [GitHub Issues](https://github.com/Lukasedv/missing-opsin/issues) page
- Review the help documentation within Lightroom

## 🛠️ Azure Infrastructure

### Deployment

The plugin requires an Azure OpenAI service with GPT-4 Vision capabilities:

```bash
cd azure-infrastructure
./deploy.sh
```

This creates:
- Azure OpenAI service
- GPT-4 Vision model deployment
- Required access keys and endpoints

### Manual Deployment

If you prefer manual deployment:

1. Create an Azure OpenAI resource in the Azure portal
2. Deploy a GPT-4 Vision model (gpt-4o recommended)
3. Copy the endpoint URL and API key
4. Configure the plugin with these values

### Cost Considerations

- Azure OpenAI charges per token
- Image analysis costs vary by image size and complexity
- Monitor usage through Azure Cost Management

## 🔄 CI/CD Pipeline

The project includes automated CI/CD workflows:

### Continuous Integration
- Lua syntax validation
- Plugin structure verification
- Azure ARM template validation
- Security scanning

### Continuous Deployment
- Automatic plugin packaging
- Azure infrastructure deployment
- Release artifact generation

### GitHub Actions Setup

1. Configure Azure service principal:
   ```bash
   az ad sp create-for-rbac --name "missing-opsin-sp" --role "Contributor" --scopes "/subscriptions/{subscription-id}"
   ```

2. Add secrets to GitHub repository:
   - `AZURE_CREDENTIALS`: Service principal JSON

## 📚 API Documentation

### ColorAnalysis Module

```lua
-- Analyze selected photos
ColorAnalysis.analyzeSelectedPhotos()

-- Analyze single photo
ColorAnalysis.analyzeSinglePhoto(photo, context)
```

### AzureOpenAI Module

```lua
-- Configure Azure OpenAI
AzureOpenAI.setConfig({
    endpoint = "https://your-endpoint.openai.azure.com/",
    apiKey = "your-api-key",
    model = "gpt-4o",
    deploymentName = "your-deployment"
})

-- Analyze image
local result = AzureOpenAI.analyzeImage(imagePath)
```

### ColorAdjustments Module

```lua
-- Apply adjustments to photo
ColorAdjustments.applyAdjustments(photo, adjustments)

-- Get current adjustments
local current = ColorAdjustments.getCurrentAdjustments(photo)
```

## 🔧 Configuration

### Plugin Preferences

The plugin stores configuration in Lightroom preferences:

- `azureEndpoint`: Azure OpenAI endpoint URL
- `azureApiKey`: Azure OpenAI API key
- `azureModel`: Model name (default: gpt-4o)
- `azureDeploymentName`: Deployment name

### Supported Models

- `gpt-4o`: Recommended for best results
- `gpt-4-vision-preview`: Alternative vision model
- `gpt-4-turbo`: High-performance option

## 🛡️ Security

### Best Practices

- Never commit API keys to version control
- Use Azure Key Vault for production deployments
- Regularly rotate API keys
- Monitor API usage and costs

### Privacy Considerations

- Images are sent to Azure OpenAI for analysis
- No images are permanently stored by the service
- Review Azure's privacy policy before use

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

### Development Guidelines

- Follow Lua coding conventions
- Add comments for complex logic
- Test with various image types
- Update documentation as needed

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Adobe for the Lightroom SDK
- Microsoft Azure for OpenAI services
- The color science community for research and insights

## 📞 Support

- GitHub Issues: [Report bugs or request features](https://github.com/Lukasedv/missing-opsin/issues)
- Documentation: [User Guide](lightroom-plugin.lrplugin/help.html)
- Email: [Support Email] (configure as needed)

## 🗓️ Roadmap

- [ ] Support for additional AI models
- [ ] Batch processing improvements
- [ ] Custom color profiles
- [ ] Integration with other Adobe products
- [ ] Mobile companion app

---

**Note**: This plugin requires an Azure subscription and may incur costs based on usage. Please review Azure OpenAI pricing before deployment.