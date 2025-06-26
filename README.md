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