--[[
TrueSight Lightroom Plugin
A plugin to help photographers with color deficiency analyze and correct photos using Azure OpenAI
]]

return {
    LrSdkVersion = 6.0,
    LrSdkMinimumVersion = 6.0,
    
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
    
    VERSION = { major=1, minor=0, revision=0, build=0, },
}