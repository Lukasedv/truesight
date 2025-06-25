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
    LrFunctionContext.callWithContext('configDialog', function(context)
        local f = LrView.osFactory()
        local bind = LrView.bind
        local share = LrView.share
        
        local props = LrBinding.makePropertyTable(context)
        
        -- Load current configuration with error handling
        local AzureOpenAI = getAzureOpenAI(true)  -- Silent mode for config dialog
        local config = {}
        if AzureOpenAI then
            config = AzureOpenAI.getConfig()
        end
        
        props.azureEndpoint = config.endpoint or ''
        props.azureApiKey = config.apiKey or ''
        props.azureModel = config.model or 'gpt-4o'
        props.azureDeploymentName = config.deploymentName or ''
        
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
                            title = 'Model:',
                            alignment = 'right',
                            width = share 'labelWidth',
                        },
                        
                        f:popup_menu {
                            value = bind 'azureModel',
                            items = {
                                { title = 'GPT-4 Vision (gpt-4o)', value = 'gpt-4o' },
                                { title = 'GPT-4 Vision Preview', value = 'gpt-4-vision-preview' },
                                { title = 'GPT-4 Turbo', value = 'gpt-4-turbo' },
                            },
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
                },
            },
            
            f:separator { fill_horizontal = 1 },
            
            f:row {
                f:push_button {
                    title = 'Test Connection',
                    action = function()
                        ConfigDialog.testConnection(props)
                    end,
                },
                
                f:spacer { fill_horizontal = 1 },
                
                f:static_text {
                    title = 'Configure your Azure OpenAI service endpoint and API key',
                    text_color = import('LrColor')(0.6, 0.6, 0.6),
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
end

function ConfigDialog.saveConfiguration(props)
    local AzureOpenAI = getAzureOpenAI(true)  -- Silent mode
    
    if AzureOpenAI then
        -- Use AzureOpenAI module to save config
        local config = {
            endpoint = props.azureEndpoint,
            apiKey = props.azureApiKey,
            model = props.azureModel,
            deploymentName = props.azureDeploymentName,
        }
        AzureOpenAI.setConfig(config)
    else
        -- Fallback: save directly to preferences
        local prefs = LrPrefs.prefsForPlugin()
        prefs.azureEndpoint = props.azureEndpoint
        prefs.azureApiKey = props.azureApiKey
        prefs.azureModel = props.azureModel
        prefs.azureDeploymentName = props.azureDeploymentName
    end
    
    LrDialogs.message('Missing Opsin', 'Configuration saved successfully.')
end

function ConfigDialog.testConnection(props)
    -- Basic validation
    if not props.azureEndpoint or props.azureEndpoint == '' then
        LrDialogs.message('Configuration Error', 'Please enter the Azure OpenAI endpoint URL.')
        return
    end
    
    if not props.azureApiKey or props.azureApiKey == '' then
        LrDialogs.message('Configuration Error', 'Please enter the Azure OpenAI API key.')
        return
    end
    
    -- Test connection (simplified - in real implementation you'd make a test API call)
    LrDialogs.message('Connection Test', 'Configuration appears valid. Click Save to store the settings.')
end

-- Export the module
return ConfigDialog.showConfigDialog