# TrueSight Plugin Installation Guide for Lightroom 14.4

## Compatibility Requirements

**IMPORTANT**: This plugin requires Adobe Lightroom Classic 14.4 or later.

- **Lightroom Classic Version**: 14.4 or later
- **SDK Version**: 13.0 (backward compatible to 10.0)
- **Operating Systems**: Windows 10/11, macOS 10.15 or later

## Step-by-Step Installation

### 1. Check Lightroom Version

Before installing, verify your Lightroom Classic version:
- Open Lightroom Classic
- Go to `Help > System Info`
- Look for the Lightroom version number
- Ensure it's 14.4 or later

### 2. Download Plugin

Download the complete `lightroom-plugin.lrplugin` folder from the repository.

### 3. Install in Lightroom

1. Open Adobe Lightroom Classic
2. Navigate to `File > Plug-in Manager`
3. Click the `Add` button
4. Select the downloaded `lightroom-plugin.lrplugin` folder
5. Click `Done`

### 4. Verify Installation

After installation, you should see:
- `Help > TrueSight Help`
- `Help > TrueSight Configuration`
- `Help > TrueSight Troubleshooting`
- `Library > TrueSight Color Analysis`
- `File > Export > Analyze Colors with TrueSight`

## Troubleshooting Installation Issues

### Plugin Not Appearing in Menus

If TrueSight doesn't appear in Lightroom menus:

1. **Check Version Compatibility**
   - Verify Lightroom Classic is 14.4 or later
   - Older versions are not supported

2. **Run Built-in Diagnostics**
   - If the plugin partially loads, go to `Help > TrueSight Troubleshooting`
   - This will provide detailed diagnostic information

3. **Check Plugin Manager**
   - Go to `File > Plug-in Manager`
   - Look for "TrueSight - Color Deficiency Assistant" in the list
   - If present but disabled, enable it
   - If showing errors, note the error message

4. **Common Solutions**
   - Restart Lightroom Classic completely
   - Remove and re-add the plugin
   - Check that all files are present in the plugin folder

### Plugin Files Checklist

Ensure these files are present in your plugin folder:
- ✅ Info.lua
- ✅ ColorAnalysis.lua
- ✅ AzureOpenAI.lua
- ✅ ColorAdjustments.lua
- ✅ ConfigDialog.lua
- ✅ ExportDialog.lua
- ✅ TroubleShoot.lua
- ✅ PluginInit.lua
- ✅ help.html

### Error Messages

**"Plugin requires a newer SDK version"**
- Your Lightroom version is too old
- Update to Lightroom Classic 14.4 or later

**"Module failed to load"**
- One or more plugin files may be missing or corrupted
- Re-download and reinstall the plugin

**"Configuration Error"**
- The plugin loaded but Azure OpenAI is not configured
- This is normal - configure Azure settings after installation

## Next Steps After Installation

1. **Configure Azure OpenAI**
   - Go to `Help > TrueSight Configuration`
   - Enter your Azure OpenAI endpoint and API key

2. **Test the Plugin**
   - Select a photo in Library
   - Go to `Library > TrueSight Color Analysis`
   - Check that the interface appears

3. **Run Diagnostics**
   - Use `Help > TrueSight Troubleshooting` to verify everything is working

## Getting Help

If you're still experiencing issues:

1. Run the built-in troubleshooting tool
2. Check the [GitHub Issues](https://github.com/Lukasedv/truesight/issues) page  
3. Create a new issue with your diagnostic information

## Version History

- **v1.0.0**: Initial release with Lightroom 14.4 support
- **SDK 13.0**: Compatible with latest Lightroom Classic versions