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
    local versionString = app.versionString or "Unknown"
    local versionInfo = "Lightroom Version: " .. versionString
    table.insert(results, versionInfo)
    
    -- Extract version number for compatibility check
    local versionNumber = versionString:match("(%d+%.%d+)")
    if versionNumber then
        local majorVersion = tonumber(versionNumber:match("(%d+)%."))
        local minorVersion = tonumber(versionNumber:match("%.(%d+)"))
        
        -- Check compatibility (14.4 or later)
        local isCompatible = (majorVersion > 14) or (majorVersion == 14 and minorVersion >= 4)
        local compatStatus = isCompatible and "✓ Compatible" or "✗ Requires 14.4+"
        table.insert(results, "Compatibility: " .. compatStatus)
    else
        table.insert(results, "Compatibility: ⚠ Could not determine version")
    end
    
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
    
    local moduleErrors = {}
    for _, module in ipairs(modules) do
        local success, result = pcall(require, module.file)
        if success then
            table.insert(results, "  " .. module.name .. ": ✓ OK")
        else
            local errorMsg = tostring(result)
            table.insert(results, "  " .. module.name .. ": ✗ ERROR")
            table.insert(moduleErrors, module.name .. ": " .. errorMsg)
        end
    end
    
    -- Report detailed module errors if any
    if #moduleErrors > 0 then
        table.insert(results, "\nModule Error Details:")
        for _, error in ipairs(moduleErrors) do
            table.insert(results, "  " .. error)
        end
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