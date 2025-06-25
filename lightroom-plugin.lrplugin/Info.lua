--[[
Missing Opsin Lightroom Plugin
A plugin to help photographers with color deficiency analyze and correct photos using Azure OpenAI

Compatible with Lightroom Classic 14.4 and later
SDK Version: 13.0
]]

return {
    LrSdkVersion = 13.0,
    LrSdkMinimumVersion = 10.0,
    
    LrToolkitIdentifier = 'com.missingopsin.colordeficiency',
    LrPluginName = 'Missing Opsin - Color Deficiency Assistant',
    
    LrPluginInfoUrl = 'https://github.com/Lukasedv/missing-opsin',
    
    LrHelpMenuItems = {
        {
            title = 'Missing Opsin Help',
            file = 'help.html',
        },
        {
            title = 'Missing Opsin Configuration',
            file = 'ConfigDialog.lua',
        },
        {
            title = 'Missing Opsin Troubleshooting',
            file = 'TroubleShoot.lua',
        },
    },
    
    LrExportMenuItems = {
        {
            title = 'Analyze Colors with Missing Opsin',
            file = 'ExportDialog.lua',
        },
    },
    
    LrLibraryMenuItems = {
        {
            title = 'Missing Opsin Color Analysis',
            file = 'ColorAnalysis.lua',
        },
    },
    LrInitPlugin = 'PluginInit.lua',
    
    VERSION = { major=1, minor=0, revision=0, build=0, },
}