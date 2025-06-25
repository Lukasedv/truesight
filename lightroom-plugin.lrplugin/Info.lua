--[[
TrueSight Lightroom Plugin
A plugin to help photographers with color deficiency analyze and correct photos using Azure OpenAI

Compatible with Lightroom Classic 14.4 and later
SDK Version: 13.0
]]

return {
    LrSdkVersion = 13.0,
    LrSdkMinimumVersion = 10.0,
    
    LrToolkitIdentifier = 'com.truesight.colordeficiency',
    LrPluginName = 'TrueSight - Color Deficiency Assistant',
    
    LrPluginInfoUrl = 'https://github.com/Lukasedv/truesight',
    
    LrHelpMenuItems = {
        {
            title = 'TrueSight Help',
            file = 'help.html',
        },
        {
            title = 'TrueSight Configuration',
            file = 'ConfigDialog.lua',
        },
        {
            title = 'TrueSight Troubleshooting',
            file = 'TroubleShoot.lua',
        },
    },
    
    LrExportMenuItems = {
        {
            title = 'Analyze Colors with TrueSight',
            file = 'ExportDialog.lua',
        },
    },
    
    LrLibraryMenuItems = {
        {
            title = 'TrueSight Color Analysis',
            file = 'ColorAnalysis.lua',
        },
    },
    LrInitPlugin = 'PluginInit.lua',
    
    VERSION = { major=1, minor=0, revision=0, build=0, },
}