--[[
Missing Opsin Troubleshooting Module
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
    -- Wrap in error handling to ensure dialog always shows
    local success, error = pcall(function()
        local diagnostics = TroubleShoot.runDiagnostics()
        
        local message = "Missing Opsin Plugin Diagnostics\n" ..
                       "=============================\n\n" ..
                       diagnostics
        
        LrDialogs.message("Missing Opsin Troubleshooting", message, "info")
    end)
    
    -- If there was an error in the main diagnostics, show a fallback error dialog
    if not success then
        local fallbackMessage = "Missing Opsin Plugin Diagnostics\n" ..
                               "=============================\n\n" ..
                               "ERROR: Failed to run complete diagnostics: " .. tostring(error) .. "\n\n" ..
                               "Basic Information:\n" ..
                               "- Plugin appears to be loaded (menu item accessible)\n" ..
                               "- Error occurred during diagnostics execution\n" ..
                               "- This may indicate missing files or dependency issues\n\n" ..
                               "Recommended Actions:\n" ..
                               "1. Restart Lightroom Classic\n" ..
                               "2. Reinstall the plugin\n" ..
                               "3. Check that all plugin files are present\n" ..
                               "4. Verify Lightroom Classic version is 14.4 or later"
        
        LrDialogs.message("Missing Opsin Troubleshooting", fallbackMessage, "warning")
    end
end

function TroubleShoot.runDiagnostics()
    local results = {}
    
    -- Wrap each diagnostic section in error handling
    local function safeDiagnostic(name, diagnosticFunc)
        local success, result = pcall(diagnosticFunc)
        if success then
            return result
        else
            return "ERROR in " .. name .. ": " .. tostring(result)
        end
    end
    
    -- Check Lightroom version
    local versionInfo = safeDiagnostic("version check", function()
        local app = LrApplication
        local versionString = app.versionString() or "Unknown"
        local info = "Lightroom Version: " .. versionString
        
        -- Extract version number for compatibility check
        local versionNumber = versionString:match("(%d+%.%d+)")
        if versionNumber then
            local majorVersion = tonumber(versionNumber:match("(%d+)%."))
            local minorVersion = tonumber(versionNumber:match("%.(%d+)"))
            
            -- Check compatibility (14.4 or later)
            local isCompatible = (majorVersion > 14) or (majorVersion == 14 and minorVersion >= 4)
            local compatStatus = isCompatible and "✓ Compatible" or "✗ Requires 14.4+"
            info = info .. "\nCompatibility: " .. compatStatus
        else
            info = info .. "\nCompatibility: ⚠ Could not determine version"
        end
        
        return info
    end)
    table.insert(results, versionInfo)
    
    -- Check OS information
    local osInfo = safeDiagnostic("OS info check", function()
        return "Operating System: " .. LrSystemInfo.summaryString()
    end)
    table.insert(results, osInfo)
    
    -- Check plugin installation
    local pluginInfo = safeDiagnostic("plugin path check", function()
        local pluginPath = _PLUGIN.path
        return "Plugin Path: " .. (pluginPath or "Unknown")
    end)
    table.insert(results, pluginInfo)
    
    -- Check required files
    local fileCheckInfo = safeDiagnostic("file check", function()
        local pluginPath = _PLUGIN.path
        local requiredFiles = {
            "Info.lua",
            "ColorAnalysis.lua", 
            "AzureOpenAI.lua",
            "ColorAdjustments.lua",
            "ConfigDialog.lua",
            "ExportDialog.lua"
        }
        
        local fileResults = {"\nRequired Files Check:"}
        for _, file in ipairs(requiredFiles) do
            local filePath = LrPathUtils.child(pluginPath, file)
            local exists = LrFileUtils.exists(filePath)
            local status = exists and "✓ OK" or "✗ MISSING"
            table.insert(fileResults, "  " .. file .. ": " .. status)
        end
        return table.concat(fileResults, "\n")
    end)
    table.insert(results, fileCheckInfo)
    
    -- Check module loading
    local moduleCheckInfo = safeDiagnostic("module loading check", function()
        local modules = {
            {name = "AzureOpenAI", file = "AzureOpenAI"},
            {name = "ColorAnalysis", file = "ColorAnalysis"},
            {name = "ColorAdjustments", file = "ColorAdjustments"},
            {name = "ConfigDialog", file = "ConfigDialog"},
            {name = "ExportDialog", file = "ExportDialog"}
        }
        
        local moduleResults = {"\nModule Loading Check:"}
        local moduleErrors = {}
        
        for _, module in ipairs(modules) do
            local success, result = pcall(require, module.file)
            if success then
                table.insert(moduleResults, "  " .. module.name .. ": ✓ OK")
            else
                local errorMsg = tostring(result)
                table.insert(moduleResults, "  " .. module.name .. ": ✗ ERROR")
                table.insert(moduleErrors, module.name .. ": " .. errorMsg)
            end
        end
        
        -- Report detailed module errors if any
        if #moduleErrors > 0 then
            table.insert(moduleResults, "\nModule Error Details:")
            for _, error in ipairs(moduleErrors) do
                table.insert(moduleResults, "  " .. error)
            end
        end
        
        return table.concat(moduleResults, "\n")
    end)
    table.insert(results, moduleCheckInfo)
    
    -- Check configuration
    local configInfo = safeDiagnostic("configuration check", function()
        local prefs = LrPrefs.prefsForPlugin()
        local hasEndpoint = prefs.azureEndpoint and prefs.azureEndpoint ~= ""
        local hasApiKey = prefs.azureApiKey and prefs.azureApiKey ~= ""
        
        local configResults = {"\nConfiguration Check:"}
        table.insert(configResults, "  Azure Endpoint: " .. (hasEndpoint and "✓ Configured" or "✗ Not configured"))
        table.insert(configResults, "  Azure API Key: " .. (hasApiKey and "✓ Configured" or "✗ Not configured"))
        
        return table.concat(configResults, "\n")
    end)
    table.insert(results, configInfo)
    
    -- SDK Version check
    table.insert(results, "\nSDK Information:")
    table.insert(results, "  Plugin SDK Version: 13.0")
    table.insert(results, "  Minimum SDK Version: 10.0")
    table.insert(results, "  Compatible with Lightroom Classic 14.4+")
    
    return table.concat(results, "\n")
end

-- Export the function that will be called by the menu
return TroubleShoot.showTroubleshootingDialog