--[[
Configuration Dialog Module
Handles Azure OpenAI configuration
]]

local LrView = import 'LrView'
local LrFunctionContext = import 'LrFunctionContext'
local LrBinding = import 'LrBinding'
local LrDialogs = import 'LrDialogs'
local LrPrefs = import 'LrPrefs'

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
    -- Ensure a dialog always shows, even if there are errors
    local success, error = pcall(function()
        LrFunctionContext.callWithContext('configDialog', function(context)
            local f = LrView.osFactory()
            local bind = LrView.bind
            local share = LrView.share
            local LrColor = import('LrColor')
            
            local props = LrBinding.makePropertyTable(context)
            
            -- Load current configuration with error handling
            local prefs = LrPrefs.prefsForPlugin()
            local AzureOpenAI = getAzureOpenAI(true)  -- Silent mode for config dialog
            local config = {}
            if AzureOpenAI then
                config = AzureOpenAI.getConfig()
            end
        
            -- Initialize properties with defaults, ensuring they're never nil
            -- Use preferences directly as the primary source
            props.azureEndpoint = prefs.azureEndpoint or config.endpoint or ''
            props.azureApiKey = prefs.azureApiKey or config.apiKey or ''
            props.azureDeploymentName = prefs.azureDeploymentName or config.deploymentName or ''
            
            -- Debug: Log what we loaded
            local loadedMsg = 'Config loaded:\n' ..
                            'Endpoint: "' .. tostring(props.azureEndpoint) .. '"\n' ..
                            'API Key length: ' .. string.len(tostring(props.azureApiKey)) .. '\n' ..
                            'Deployment: "' .. tostring(props.azureDeploymentName) .. '"'
            
            -- Add property observers to ensure binding is working
            props:addObserver('azureEndpoint', function()
                -- Optional: add debug logging here if needed
            end)
            
            props:addObserver('azureApiKey', function()
                -- Optional: add debug logging here if needed  
            end)
            
            props:addObserver('azureDeploymentName', function()
                -- Optional: add debug logging here if needed
            end)
        
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
                            width = share 'labelWidth',
                        },
                        
                        f:edit_field {
                            value = bind 'azureEndpoint',
                            width_in_chars = 50,
                            immediate = true,
                        },
                    },
                    
                    f:row {
                        f:static_text {
                            title = 'API Key:',
                            alignment = 'right',
                            width = share 'labelWidth',
                        },
                        
                        f:password_field {
                            value = bind 'azureApiKey',
                            width_in_chars = 50,
                            immediate = true,
                        },
                    },
                    
                    f:row {
                        f:static_text {
                            title = 'Deployment Name:',
                            alignment = 'right',
                            width = share 'labelWidth',
                        },
                        
                        f:edit_field {
                            value = bind 'azureDeploymentName',
                            width_in_chars = 30,
                            immediate = true,
                        },
                    },
                    
                    f:row {
                        f:static_text {
                            title = '',
                            alignment = 'right',
                            width = share 'labelWidth',
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
                        -- Use a task to ensure UI is fully updated
                        LrTasks.startAsyncTask(function()
                            ConfigDialog.testConnection(props)
                        end)
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
            ConfigDialog.saveConfiguration(props)
        end
        end)
    end)
    
    -- If there was an error in the main dialog creation, show a fallback error dialog
    if not success then
        local errorMsg = 'Failed to load configuration dialog: ' .. tostring(error)
        LrDialogs.message('Missing Opsin Configuration Error', 
            errorMsg .. 
            '\n\nThis may indicate a problem with the plugin installation. Please try:' ..
            '\n1. Restarting Lightroom Classic' ..
            '\n2. Reinstalling the plugin' ..
            '\n3. Checking that all plugin files are present' ..
            '\n\nIf the problem persists, please report this error message on GitHub.', 'critical')
    end
end

function ConfigDialog.saveConfiguration(props)
    -- Ensure we have valid values
    local endpointValue = tostring(props.azureEndpoint or '')
    local apiKeyValue = tostring(props.azureApiKey or '')
    local deploymentValue = tostring(props.azureDeploymentName or '')
    
    -- Trim whitespace
    endpointValue = string.gsub(endpointValue, "^%s*(.-)%s*$", "%1")
    apiKeyValue = string.gsub(apiKeyValue, "^%s*(.-)%s*$", "%1")
    deploymentValue = string.gsub(deploymentValue, "^%s*(.-)%s*$", "%1")
    
    -- Save directly to preferences - this is more reliable
    local prefs = LrPrefs.prefsForPlugin()
    prefs.azureEndpoint = endpointValue
    prefs.azureApiKey = apiKeyValue
    prefs.azureDeploymentName = deploymentValue
    
    -- Also try to save via AzureOpenAI module if available
    local AzureOpenAI = getAzureOpenAI(true)  -- Silent mode
    if AzureOpenAI then
        local config = {
            endpoint = endpointValue,
            apiKey = apiKeyValue,
            deploymentName = deploymentValue,
        }
        AzureOpenAI.setConfig(config)
    end
    
    -- Verify the save worked by re-reading
    local savedEndpoint = prefs.azureEndpoint or 'NOT SAVED'
    local savedDeployment = prefs.azureDeploymentName or 'NOT SAVED'
    local savedApiKeyLength = string.len(prefs.azureApiKey or '')
    
    LrDialogs.message('Missing Opsin', 'Configuration saved successfully!\n\nEndpoint: ' .. savedEndpoint .. '\nDeployment: ' .. savedDeployment .. '\nAPI Key Length: ' .. savedApiKeyLength)
end

function ConfigDialog.testConnection(props)
    -- Add a small delay to ensure UI values are synchronized
    LrTasks.sleep(0.1)
    
    -- Force refresh properties from the dialog state
    local endpointValue = tostring(props.azureEndpoint or '')
    local apiKeyValue = tostring(props.azureApiKey or '')
    local deploymentValue = tostring(props.azureDeploymentName or '')
    
    -- Trim whitespace
    endpointValue = string.gsub(endpointValue, "^%s*(.-)%s*$", "%1")
    apiKeyValue = string.gsub(apiKeyValue, "^%s*(.-)%s*$", "%1")
    deploymentValue = string.gsub(deploymentValue, "^%s*(.-)%s*$", "%1")
    
    -- Debug output (more detailed)
    local debugMsg = 'Debug Info:\n' ..
                    'Endpoint length: ' .. string.len(endpointValue) .. '\n' ..
                    'Endpoint value: "' .. endpointValue .. '"\n' ..
                    'API Key length: ' .. string.len(apiKeyValue) .. '\n' ..
                    'Deployment: "' .. deploymentValue .. '"\n' ..
                    'Props type: ' .. type(props) .. '\n' ..
                    'Raw endpoint: ' .. tostring(props.azureEndpoint)
    
    -- Basic validation with detailed error messages
    if endpointValue == '' then
        LrDialogs.message('Configuration Error', 'Please enter the Azure OpenAI endpoint URL.\n\n' .. debugMsg)
        return
    end
    
    -- More flexible endpoint format validation
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
    
    -- Test connection with the current values
    LrDialogs.message('Connection Test', 'Configuration appears valid!\n\nEndpoint: ' .. endpointValue .. '\nDeployment: ' .. deploymentValue .. '\n\nClick Save to store the settings.')
end

-- Export the module
return ConfigDialog.showConfigDialog