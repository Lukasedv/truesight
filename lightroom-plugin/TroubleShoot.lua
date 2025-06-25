--[[
TrueSight Troubleshooting Module
Provides diagnostic tools to help troubleshoot plugin loading and configuration issues
]]

local LrDialogs = import 'LrDialogs'
local LrApplication = import 'LrApplication'
local LrSystemInfo = import 'LrSystemInfo'
local LrPrefs = import 'LrPrefs'
local LrFileUtils = import 'LrFileUtils'
local LrPathUtils = import 'LrPathUtils'

local TroubleShoot = {}

function TroubleShoot.showTroubleshootingDialog()
    local diagnostics = TroubleShoot.runDiagnostics()
    
    local message = "TrueSight Plugin Diagnostics\n" ..
                   "=============================\n\n" ..
                   diagnostics
    
    LrDialogs.message("TrueSight Troubleshooting", message, "info")
end

function TroubleShoot.runDiagnostics()
    local results = {}
    
    -- Check Lightroom version
    local app = LrApplication
    local versionInfo = "Lightroom Version: " .. (app.versionString or "Unknown")
    table.insert(results, versionInfo)
    
    -- Check OS information
    local osInfo = "Operating System: " .. LrSystemInfo.summaryString()
    table.insert(results, osInfo)
    
    -- Check plugin installation
    local pluginPath = _PLUGIN.path
    local pluginInfo = "Plugin Path: " .. (pluginPath or "Unknown")
    table.insert(results, pluginInfo)
    
    -- Check required files
    local requiredFiles = {
        "Info.lua",
        "ColorAnalysis.lua", 
        "AzureOpenAI.lua",
        "ColorAdjustments.lua",
        "ConfigDialog.lua",
        "ExportDialog.lua"
    }
    
    table.insert(results, "\nRequired Files Check:")
    for _, file in ipairs(requiredFiles) do
        local filePath = LrPathUtils.child(pluginPath, file)
        local exists = LrFileUtils.exists(filePath)
        local status = exists and "✓ OK" or "✗ MISSING"
        table.insert(results, "  " .. file .. ": " .. status)
    end
    
    -- Check module loading
    table.insert(results, "\nModule Loading Check:")
    local modules = {
        {name = "AzureOpenAI", file = "AzureOpenAI"},
        {name = "ColorAnalysis", file = "ColorAnalysis"},
        {name = "ColorAdjustments", file = "ColorAdjustments"},
        {name = "ConfigDialog", file = "ConfigDialog"},
        {name = "ExportDialog", file = "ExportDialog"}
    }
    
    for _, module in ipairs(modules) do
        local success, result = pcall(require, module.file)
        local status = success and "✓ OK" or ("✗ ERROR: " .. tostring(result))
        table.insert(results, "  " .. module.name .. ": " .. status)
    end
    
    -- Check configuration
    table.insert(results, "\nConfiguration Check:")
    local prefs = LrPrefs.prefsForPlugin()
    local hasEndpoint = prefs.azureEndpoint and prefs.azureEndpoint ~= ""
    local hasApiKey = prefs.azureApiKey and prefs.azureApiKey ~= ""
    
    table.insert(results, "  Azure Endpoint: " .. (hasEndpoint and "✓ Configured" or "✗ Not configured"))
    table.insert(results, "  Azure API Key: " .. (hasApiKey and "✓ Configured" or "✗ Not configured"))
    
    -- SDK Version check
    table.insert(results, "\nSDK Information:")
    table.insert(results, "  Plugin SDK Version: 13.0")
    table.insert(results, "  Minimum SDK Version: 10.0")
    table.insert(results, "  Compatible with Lightroom Classic 14.4+")
    
    return table.concat(results, "\n")
end

-- Export the function that will be called by the menu
return TroubleShoot.showTroubleshootingDialog