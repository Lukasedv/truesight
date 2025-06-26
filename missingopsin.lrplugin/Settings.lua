--[[----------------------------------------------------------------------------

Missing Opsin - Lightroom Plugin for Color Deficiency Support
Copyright 2025

Settings.lua
Configuration dialog for Azure OpenAI settings.

------------------------------------------------------------------------------]]

-- Access the Lightroom SDK namespaces
local LrFunctionContext = import 'LrFunctionContext'
local LrBinding = import 'LrBinding'
local LrDialogs = import 'LrDialogs'
local LrView = import 'LrView'
local LrPrefs = import 'LrPrefs'
local LrLogger = import 'LrLogger'
local LrTasks = import 'LrTasks'

-- Import our HTTP utilities
local HttpUtils = require 'HttpUtils'

-- Create logger
local logger = LrLogger('MissingOpsinLogger')
logger:enable("print")

-- Get plugin preferences
local prefs = LrPrefs.prefsForPlugin()

--------------------------------------------------------------------------------
-- Settings dialog function

local function showSettings()
    
    LrFunctionContext.callWithContext("showSettings", function(context)
        
        logger:trace("Opening settings dialog")
        
        -- Create bindable properties with current preferences
        local props = LrBinding.makePropertyTable(context)
        props.endpoint = prefs.azureEndpoint or ""
        props.apiKey = prefs.azureApiKey or ""
        props.deploymentName = prefs.deploymentName or "gpt-4.1"
        props.testStatus = ""
        props.isTesting = false
        
        -- Create the dialog factory
        local f = LrView.osFactory()
        
        -- Create dialog contents
        local contents = f:column {
            bind_to_object = props,
            spacing = f:dialog_spacing(),
            
            f:row {
                f:static_text {
                    title = "Missing Opsin Settings",
                    text_color = LrView.kColorBlack,
                    font = '<system/bold>',
                },
            },
            
            f:separator { fill_horizontal = 1 },
            
            f:group_box {
                title = "Azure OpenAI Configuration",
                fill_horizontal = 1,
                
                f:column {
                    spacing = f:control_spacing(),
                    
                    f:row {
                        f:static_text {
                            title = "Endpoint URL:",
                            width = 120,
                        },
                        f:edit_field {
                            bind_to_object = props,
                            value = LrView.bind("endpoint"),
                            width_in_chars = 50,
                            immediate = true,
                        },
                    },
                    
                    f:row {
                        f:static_text {
                            title = "API Key:",
                            width = 120,
                        },
                        f:password_field {
                            bind_to_object = props,
                            value = LrView.bind("apiKey"),
                            width_in_chars = 50,
                            immediate = true,
                        },
                    },
                    
                    f:row {
                        f:static_text {
                            title = "Deployment Name:",
                            width = 120,
                        },
                        f:edit_field {
                            bind_to_object = props,
                            value = LrView.bind("deploymentName"),
                            width_in_chars = 30,
                            immediate = true,
                        },
                    },
                },
            },
            
            f:separator { fill_horizontal = 1 },
            
            f:row {
                f:push_button {
                    title = "Test Connection",
                    enabled = LrView.bind { 
                        keys = { "endpoint", "apiKey", "isTesting" },
                        operation = function(binder, values, fromTable)
                            return values.endpoint ~= "" and values.apiKey ~= "" and not values.isTesting
                        end
                    },
                    action = function()
                        logger:trace("Testing connection to Azure OpenAI")
                        
                        LrTasks.startAsyncTask(function()
                            props.isTesting = true
                            props.testStatus = "Testing connection..."
                            
                            -- Perform real connection test
                            local success, message = HttpUtils.testAzureOpenAIConnection(
                                props.endpoint,
                                props.apiKey,
                                props.deploymentName
                            )
                            
                            if success then
                                props.testStatus = "✓ " .. message
                                logger:trace("Connection test successful: " .. message)
                            else
                                props.testStatus = "✗ " .. message
                                logger:trace("Connection test failed: " .. message)
                            end
                            
                            props.isTesting = false
                        end)
                    end,
                },
                
                f:push_button {
                    title = "LR Compat Test",
                    enabled = LrView.bind { 
                        keys = { "endpoint", "apiKey", "isTesting" },
                        operation = function(binder, values, fromTable)
                            return values.endpoint ~= "" and values.apiKey ~= "" and not values.isTesting
                        end
                    },
                    action = function()
                        logger:trace("Testing Lightroom HTTP client compatibility")
                        
                        LrTasks.startAsyncTask(function()
                            props.isTesting = true
                            props.testStatus = "Testing Lightroom compatibility..."
                            
                            -- Test with simplified parameters
                            local success, message = HttpUtils.testLightroomCompatibility(
                                props.endpoint,
                                props.apiKey,
                                props.deploymentName
                            )
                            
                            if success then
                                props.testStatus = "✓ " .. message
                                logger:trace("Lightroom compatibility test successful: " .. message)
                            else
                                props.testStatus = "✗ " .. message  
                                logger:trace("Lightroom compatibility test failed: " .. message)
                            end
                            
                            props.isTesting = false
                        end)
                    end,
                },
                
                f:push_button {
                    title = "Detailed Test",
                    enabled = LrView.bind { 
                        keys = { "endpoint", "apiKey", "isTesting" },
                        operation = function(binder, values, fromTable)
                            return values.endpoint ~= "" and values.apiKey ~= "" and not values.isTesting
                        end
                    },
                    action = function()
                        logger:trace("Running detailed connection test")
                        
                        LrTasks.startAsyncTask(function()
                            props.isTesting = true
                            props.testStatus = "Running detailed test..."
                            
                            -- Perform detailed connection test
                            local success, message, details = HttpUtils.testAzureOpenAIConnectionDetailed(
                                props.endpoint,
                                props.apiKey,
                                props.deploymentName
                            )
                            
                            local detailedReport = "DETAILED CONNECTION TEST REPORT\n" ..
                                "================================\n\n" ..
                                "Timestamp: " .. (details and details.timestamp or "Unknown") .. "\n\n" ..
                                "REQUEST:\n" ..
                                "URL: " .. (details and details.requestUrl or "Unknown") .. "\n" ..
                                "Headers: api-key=" .. (props.apiKey:sub(1, 8) .. "..." .. props.apiKey:sub(-4)) .. "\n" ..
                                "Payload: " .. (details and details.requestPayload or "Unknown") .. "\n\n" ..
                                "RESPONSE:\n" ..
                                "Status: " .. (details and details.responseStatus or "Unknown") .. "\n" ..
                                "Body: " .. (details and details.responseBody or "No body") .. "\n\n" ..
                                "RESULT:\n" .. (success and "SUCCESS" or "FAILURE") .. ": " .. message
                            
                            LrDialogs.message("Detailed Test Results", detailedReport, success and "info" or "critical")
                            
                            if success then
                                props.testStatus = "✓ " .. message
                            else
                                props.testStatus = "✗ " .. message
                            end
                            
                            props.isTesting = false
                        end)
                    end,
                },
                
                f:push_button {
                    title = "Show HTTP Details",
                    enabled = LrView.bind { 
                        keys = { "endpoint", "apiKey" },
                        operation = function(binder, values, fromTable)
                            return values.endpoint ~= "" and values.apiKey ~= ""
                        end
                    },
                    action = function()
                        -- Generate diagnostic information
                        local diagnostics = HttpUtils.generateDiagnosticInfo(
                            props.endpoint,
                            props.apiKey,
                            props.deploymentName
                        )
                        
                        local detailsText = "HTTP REQUEST DETAILS\n" ..
                            "====================\n\n" ..
                            "URL:\n" .. diagnostics.url .. "\n\n" ..
                            "Headers:\n" .. diagnostics.headers .. "\n\n" ..
                            "Payload (formatted):\n" .. diagnostics.payloadPretty .. "\n\n" ..
                            "Payload (actual JSON):\n" .. diagnostics.payload .. "\n\n" ..
                            "This is exactly what the plugin will send to Azure OpenAI.\n" ..
                            "Compare this with your working curl command."
                        
                        LrDialogs.message("HTTP Request Details", detailsText, "info")
                    end,
                },
            },
            
            f:row {
                f:static_text {
                    title = LrView.bind("testStatus"),
                    fill_horizontal = 1,
                },
            },
            
            f:separator { fill_horizontal = 1 },
            
            f:static_text {
                title = "Default Configuration (from truesight-config.txt):",
                font = '<system/bold>',
            },
            
            f:static_text {
                title = "Endpoint: https://your-resource.openai.azure.com/",
                text_color = LrView.kColorBlue,
            },
            
            f:static_text {
                title = "Deployment: your-deployment-name",
                text_color = LrView.kColorBlue,
            },
            
            f:push_button {
                title = "Use Default Configuration",
                action = function()
                    props.endpoint = "https://your-resource.openai.azure.com/"
                    props.apiKey = "your-api-key-here"
                    props.deploymentName = "your-deployment"
                end,
            },
        }
        
        -- Show the dialog
        local result = LrDialogs.presentModalDialog {
            title = "Missing Opsin - Settings",
            contents = contents,
            actionVerb = "Save",
            cancelVerb = "Cancel",
        }
        
        -- Save preferences if user clicked Save
        if result == "ok" then
            prefs.azureEndpoint = props.endpoint
            prefs.azureApiKey = props.apiKey
            prefs.deploymentName = props.deploymentName
            
            logger:trace("Settings saved successfully")
            LrDialogs.message("Settings Saved", "Your Azure OpenAI configuration has been saved.", "info")
        end
        
    end)
end

-- Execute the settings dialog
showSettings()
