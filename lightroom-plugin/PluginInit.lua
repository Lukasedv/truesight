--[[
TrueSight Plugin Initialization
This file is called when the plugin is loaded to perform initialization checks
]]

local LrDialogs = import 'LrDialogs'
local LrLogger = import 'LrLogger'
local LrApplication = import 'LrApplication'

-- Set up logging
local pluginLogger = LrLogger('TrueSight')
pluginLogger:enable("logfile")

-- Initialize plugin
local function initPlugin()
    pluginLogger:info("TrueSight plugin initializing...")
    
    -- Check Lightroom version compatibility
    local app = LrApplication
    local version = app.versionString or "Unknown"
    pluginLogger:info("Lightroom version: " .. version)
    
    -- Check if required modules can be loaded
    local modules = {
        'AzureOpenAI',
        'ColorAnalysis', 
        'ColorAdjustments',
        'ConfigDialog',
        'ExportDialog'
    }
    
    local loadErrors = {}
    
    for _, moduleName in ipairs(modules) do
        local success, result = pcall(require, moduleName)
        if success then
            pluginLogger:info("Module loaded successfully: " .. moduleName)
        else
            local error = "Failed to load module " .. moduleName .. ": " .. tostring(result)
            pluginLogger:error(error)
            table.insert(loadErrors, error)
        end
    end
    
    -- Report any loading errors
    if #loadErrors > 0 then
        local errorMessage = "TrueSight Plugin Loading Issues:\n\n" .. table.concat(loadErrors, "\n\n") ..
                           "\n\nPlease check the plugin installation and try restarting Lightroom."
        
        -- Show error dialog only if in development mode or if requested
        local showErrors = false -- Set to true during development/debugging
        if showErrors then
            LrDialogs.message("TrueSight Plugin Error", errorMessage, "critical")
        end
        
        pluginLogger:error("Plugin initialization completed with errors")
    else
        pluginLogger:info("TrueSight plugin initialized successfully")
    end
end

-- Initialize the plugin
initPlugin()

-- No return value needed for initialization modules