--[[----------------------------------------------------------------------------

Missing Opsin - Lightroom Plugin for Color Deficiency Support
Copyright 2025

HelpDialog.lua
Help and configuration dialog.

------------------------------------------------------------------------------]]

-- Access the Lightroom SDK namespaces
local LrFunctionContext = import 'LrFunctionContext'
local LrBinding = import 'LrBinding'
local LrDialogs = import 'LrDialogs'
local LrView = import 'LrView'
local LrLogger = import 'LrLogger'

-- Create logger
local logger = LrLogger('MissingOpsinLogger')
logger:enable("print")

--------------------------------------------------------------------------------
-- Help dialog function

local function showHelp()
    
    LrFunctionContext.callWithContext("showHelp", function(context)
        
        logger:trace("Opening help dialog")
        
        -- Create bindable properties
        local props = LrBinding.makePropertyTable(context)
        
        -- Create the dialog factory
        local f = LrView.osFactory()
        
        -- Create dialog contents
        local contents = f:column {
            bind_to_object = props,
            spacing = f:dialog_spacing(),
            
            f:row {
                f:static_text {
                    title = "Missing Opsin Help",
                    text_color = LrView.kColorBlack,
                    font = '<system/bold>',
                },
            },
            
            f:separator { fill_horizontal = 1 },
            
            f:scrolled_view {
                width = 600,
                height = 400,
                f:column {
                    spacing = f:control_spacing(),
                    
                    f:static_text {
                        title = "Welcome to Missing Opsin!",
                        font = '<system/bold>',
                    },
                    
                    f:static_text {
                        title = [[
Missing Opsin is designed to help photographers with color deficiency analyze and correct their photos using AI-powered color analysis through Azure OpenAI's GPT-4 Vision capabilities.

FEATURES:
• AI-Powered Color Analysis using GPT-4 Vision
• Intelligent color correction recommendations
• Batch processing of multiple photos
• Export integration for color analysis

QUICK START:
1. Configure your Azure OpenAI settings (click Configuration below)
2. Select photos in the Library module  
3. Go to Library > Missing Opsin Color Analysis
4. Review suggestions and apply adjustments

CONFIGURATION:
Enter your Azure OpenAI details from truesight-config.txt:
• Endpoint: https://your-resource.openai.azure.com/
• API Key: your-api-key-here
• Deployment: your-deployment-name

SETUP STEPS:
1. Go to Library > Missing Opsin Settings  
2. Click "Use Default Configuration" or enter details manually
3. Click "Test Connection" to verify setup
4. Select photos and run Library > Missing Opsin Color Analysis

USAGE TIPS:
• Select multiple photos for batch analysis
• Review AI suggestions before applying changes
• Use the export feature for workflow integration
• Color analysis works best with well-lit photos

For technical support or feature requests, please visit our GitHub repository.
                        ]],
                        width = 550,
                        height = 300,
                    },
                },
            },
            
            f:separator { fill_horizontal = 1 },
            
            f:row {
                f:push_button {
                    title = "Configuration",
                    action = function()
                        -- Close help and open settings
                        LrDialogs.stopModalWithResult("settings")
                    end,
                },
                
                f:push_button {
                    title = "Test Analysis",
                    action = function()
                        -- Close help and open color analysis
                        LrDialogs.stopModalWithResult("analysis")
                    end,
                },
                
                f:spacer { fill_horizontal = 1 },
                
                f:static_text {
                    title = "Version 1.0.0",
                    text_color = LrView.kColorBlue,
                },
            },
        }
        
        -- Show the dialog
        local result = LrDialogs.presentModalDialog {
            title = "Missing Opsin - Help & Configuration",
            contents = contents,
            actionVerb = "Close",
        }
        
        -- Handle special results
        if result == "settings" then
            -- Load and execute settings dialog
            require "Settings"
        elseif result == "analysis" then
            -- Load and execute color analysis
            require "ColorAnalysis"
        end
        
    end)
end

-- Execute the help dialog
showHelp()
