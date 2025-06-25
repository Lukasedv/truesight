--[[
Configuration Dialog Module - Simplified Version
Handles Azure OpenAI configuration without complex property binding
]]

local LrView = import 'LrView'
local LrFunctionContext = import 'LrFunctionContext'
local LrBinding = import 'LrBinding'
local LrDialogs = import 'LrDialogs'
local LrPrefs = import 'LrPrefs'
local LrTasks = import 'LrTasks'

-- Lazy loading of Azure OpenAI to prevent plugin loading failures
local function getAzureOpenAI(silent)
    local success, module = pcall(require, 'AzureOpenAI')
    if not success then
        if not silent then
            LrDialogs.message('Missing Opsin Error', 'Azure OpenAI module failed to load. Please check your installation.')
        end
        return nil
    end
    return module
end

local ConfigDialog = {}

function ConfigDialog.showConfigDialog()
    local success, error = pcall(function()
        LrFunctionContext.callWithContext('configDialog', function(context)
            local f = LrView.osFactory()
            local LrColor = import('LrColor')
            
            -- Load current configuration
            local prefs = LrPrefs.prefsForPlugin()
            local currentEndpoint = prefs.azureEndpoint or ''
            local currentApiKey = prefs.azureApiKey or ''
            local currentDeployment = prefs.azureDeploymentName or ''
            
            -- Simple storage for field values (no complex binding)
            local fieldValues = {
                endpoint = currentEndpoint,
                apiKey = currentApiKey,
                deployment = currentDeployment
            }
            
            local contents = f:column {
                spacing = f:control_spacing(),
                
                f:row {
                    f:static_text {
                        title = 'Missing Opsin Configuration',
                        font = '<system/bold>',
                    },
                },
                
                f:separator { fill_horizontal = 1 },
                
                f:group_box {
                    title = 'Azure OpenAI Settings',
                    f:column {
                        spacing = f:control_spacing(),
                        
                        f:row {
                            f:static_text {
                                title = 'Endpoint URL:',
                                alignment = 'right',
                                width = 120,
                            },
                            
                            f:edit_field {
                                value = currentEndpoint,
                                width_in_chars = 50,
                                immediate = true,
                                value_to_string = function(value) return tostring(value or '') end,
                                string_to_value = function(value) 
                                    fieldValues.endpoint = tostring(value or '')
                                    return fieldValues.endpoint 
                                end,
                            },
                        },
                        
                        f:row {
                            f:static_text {
                                title = 'API Key:',
                                alignment = 'right',
                                width = 120,
                            },
                            
                            f:password_field {
                                value = currentApiKey,
                                width_in_chars = 50,
                                immediate = true,
                                value_to_string = function(value) return tostring(value or '') end,
                                string_to_value = function(value) 
                                    fieldValues.apiKey = tostring(value or '')
                                    return fieldValues.apiKey 
                                end,
                            },
                        },
                        
                        f:row {
                            f:static_text {
                                title = 'Deployment Name:',
                                alignment = 'right',
                                width = 120,
                            },
                            
                            f:edit_field {
                                value = currentDeployment,
                                width_in_chars = 30,
                                immediate = true,
                                value_to_string = function(value) return tostring(value or '') end,
                                string_to_value = function(value) 
                                    fieldValues.deployment = tostring(value or '')
                                    return fieldValues.deployment 
                                end,
                            },
                        },
                        
                        f:row {
                            f:static_text {
                                title = '',
                                alignment = 'right',
                                width = 120,
                            },
                            
                            f:static_text {
                                title = 'Enter the deployment name from your Azure OpenAI service (e.g., gpt-4o-deployment)',
                                text_color = LrColor(0.6, 0.6, 0.6),
                                width_in_chars = 50,
                            },
                        },
                    },
                },
                
                f:separator { fill_horizontal = 1 },
                
                f:row {
                    f:push_button {
                        title = 'Test Connection',
                        action = function()
                            ConfigDialog.testConnection(fieldValues)
                        end,
                    },
                    
                    f:spacer { fill_horizontal = 1 },
                    
                    f:static_text {
                        title = 'Configure your Azure OpenAI service endpoint and API key',
                        text_color = LrColor(0.6, 0.6, 0.6),
                    },
                },
            }
            
            local result = LrDialogs.presentModalDialog({
                title = 'Missing Opsin Configuration',
                contents = contents,
                actionVerb = 'Save',
            })
            
            if result == 'ok' then
                ConfigDialog.saveConfiguration(fieldValues)
            end
        end)
    end)
    
    if not success then
        local errorMsg = 'Failed to load configuration dialog: ' .. tostring(error)
        LrDialogs.message('Missing Opsin Configuration Error', errorMsg, 'critical')
    end
end

function ConfigDialog.saveConfiguration(fieldValues)
    -- Trim whitespace from all values
    local endpointValue = string.gsub(tostring(fieldValues.endpoint or ''), "^%s*(.-)%s*$", "%1")
    local apiKeyValue = string.gsub(tostring(fieldValues.apiKey or ''), "^%s*(.-)%s*$", "%1")
    local deploymentValue = string.gsub(tostring(fieldValues.deployment or ''), "^%s*(.-)%s*$", "%1")
    
    -- Save to preferences
    local prefs = LrPrefs.prefsForPlugin()
    prefs.azureEndpoint = endpointValue
    prefs.azureApiKey = apiKeyValue
    prefs.azureDeploymentName = deploymentValue
    
    -- Also save via AzureOpenAI module if available
    local AzureOpenAI = getAzureOpenAI(true)
    if AzureOpenAI then
        local config = {
            endpoint = endpointValue,
            apiKey = apiKeyValue,
            deploymentName = deploymentValue,
        }
        AzureOpenAI.setConfig(config)
    end
    
    -- Verify the save worked
    local savedEndpoint = prefs.azureEndpoint or 'NOT SAVED'
    local savedDeployment = prefs.azureDeploymentName or 'NOT SAVED'
    local savedApiKeyLength = string.len(prefs.azureApiKey or '')
    
    LrDialogs.message('Missing Opsin', 'Configuration saved successfully!\n\nEndpoint: ' .. savedEndpoint .. '\nDeployment: ' .. savedDeployment .. '\nAPI Key Length: ' .. savedApiKeyLength)
end

function ConfigDialog.testConnection(fieldValues)
    -- Get current field values
    local endpointValue = string.gsub(tostring(fieldValues.endpoint or ''), "^%s*(.-)%s*$", "%1")
    local apiKeyValue = string.gsub(tostring(fieldValues.apiKey or ''), "^%s*(.-)%s*$", "%1")
    local deploymentValue = string.gsub(tostring(fieldValues.deployment or ''), "^%s*(.-)%s*$", "%1")
    
    -- Debug output
    local debugMsg = 'Debug Info:\n' ..
                    'Endpoint length: ' .. string.len(endpointValue) .. '\n' ..
                    'Endpoint value: "' .. endpointValue .. '"\n' ..
                    'API Key length: ' .. string.len(apiKeyValue) .. '\n' ..
                    'Deployment: "' .. deploymentValue .. '"'
    
    -- Basic validation
    if endpointValue == '' then
        LrDialogs.message('Configuration Error', 'Please enter the Azure OpenAI endpoint URL.\n\n' .. debugMsg)
        return
    end
    
    if not (string.find(endpointValue, 'openai%.azure%.com') and string.find(endpointValue, 'https://')) then
        LrDialogs.message('Configuration Error', 'Invalid endpoint URL format.\n\nThe endpoint should look like:\nhttps://your-service-name.openai.azure.com/\n\nCurrent value: "' .. endpointValue .. '"\n\n' .. debugMsg)
        return
    end
    
    if apiKeyValue == '' then
        LrDialogs.message('Configuration Error', 'Please enter the Azure OpenAI API key.\n\n' .. debugMsg)
        return
    end
    
    if deploymentValue == '' then
        LrDialogs.message('Configuration Error', 'Please enter the deployment name (e.g., gpt-4o-deployment).\n\n' .. debugMsg)
        return
    end
    
    -- Test connection
    LrDialogs.message('Connection Test', 'Configuration appears valid!\n\nEndpoint: ' .. endpointValue .. '\nDeployment: ' .. deploymentValue .. '\n\nClick Save to store the settings.')
end

-- Export the module
return ConfigDialog.showConfigDialog
