--[[----------------------------------------------------------------------------

Missing Opsin - Lightroom Plugin for Color Deficiency Support
Copyright 2025

ColorAnalysis.lua
Main color analysis functionality.

------------------------------------------------------------------------------]]

-- Access the Lightroom SDK namespaces
local LrFunctionContext = import 'LrFunctionContext'
local LrBinding = import 'LrBinding'
local LrDialogs = import 'LrDialogs'
local LrView = import 'LrView'
local LrSelection = import 'LrSelection'
local LrApplication = import 'LrApplication'
local LrTasks = import 'LrTasks'
local LrLogger = import 'LrLogger'
local LrPrefs = import 'LrPrefs'

-- Import our HTTP utilities
local HttpUtils = require 'HttpUtils'

-- Create logger
local logger = LrLogger('MissingOpsinLogger')
logger:enable("print")

-- Get plugin preferences
local prefs = LrPrefs.prefsForPlugin()

--------------------------------------------------------------------------------
-- Make Azure OpenAI API call for color analysis
function analyzePhotoWithAI(photoPath, photoName)
    logger:trace("Analyzing photo with Azure OpenAI: " .. photoName)
    
    -- Check if we have the required configuration
    if not prefs.azureEndpoint or not prefs.azureApiKey or not prefs.deploymentName then
        return false, "Azure OpenAI configuration not found. Please configure the plugin first."
    end
    
    -- Create the prompt for color analysis
    local prompt = [[
Analyze this image for color balance, skin tones, and overall color harmony. 
Provide specific, actionable recommendations for color correction in Adobe Lightroom.

Focus on:
1. Overall color balance and temperature
2. Skin tone accuracy (if people are present)  
3. Color harmony and saturation levels
4. Specific HSL adjustments needed
5. Suggestions for photographers with color deficiency

Keep your response concise but specific with actionable Lightroom adjustments.
Format your response with clear sections and bullet points for easy reading.
    ]]
    
    -- Use the HttpUtils function for the API call
    return HttpUtils.analyzeColors(
        prefs.azureEndpoint,
        prefs.azureApiKey,
        prefs.deploymentName,
        prompt,
        photoName
    )
end

--------------------------------------------------------------------------------
-- Main color analysis function

local function analyzeColors()
    
    LrFunctionContext.callWithContext("analyzeColors", function(context)
        
        -- Get the current catalog and selected photos
        local catalog = LrApplication.activeCatalog()
        local selectedPhotos = catalog:getTargetPhotos()
        
        if #selectedPhotos == 0 then
            LrDialogs.message("No Photos Selected", "Please select one or more photos to analyze.", "info")
            return
        end
        
        logger:trace("Starting color analysis for " .. #selectedPhotos .. " photos")
        
        -- Create bindable properties
        local props = LrBinding.makePropertyTable(context)
        props.analysisStatus = "Ready to analyze " .. #selectedPhotos .. " photo(s)"
        props.isAnalyzing = false
        props.analysisResults = ""
        
        -- Create the dialog factory
        local f = LrView.osFactory()
        
        -- Create dialog contents
        local contents = f:column {
            bind_to_object = props,
            spacing = f:dialog_spacing(),
            
            f:row {
                f:static_text {
                    title = "Missing Opsin Color Analysis",
                    text_color = LrView.kColorBlack,
                    font = '<system/bold>',
                },
            },
            
            f:separator { fill_horizontal = 1 },
            
            f:row {
                f:static_text {
                    title = "Status:",
                    width = 80,
                },
                f:static_text {
                    title = LrView.bind("analysisStatus"),
                    fill_horizontal = 1,
                },
            },
            
            f:row {
                f:static_text {
                    title = "Selected Photos:",
                    width = 80,
                },
                f:static_text {
                    title = tostring(#selectedPhotos),
                },
            },
            
            f:separator { fill_horizontal = 1 },
            
            f:scrolled_view {
                width = 500,
                height = 200,
                f:edit_field {
                    bind_to_object = props,
                    value = LrView.bind("analysisResults"),
                    width_in_chars = 60,
                    height_in_lines = 12,
                    enabled = false,
                },
            },
            
            f:row {
                f:push_button {
                    title = "Analyze Colors",
                    enabled = LrView.bind { key = "isAnalyzing", transform = function(value) return not value end },
                    action = function()
                        -- Start analysis in background task
                        LrTasks.startAsyncTask(function()
                            props.isAnalyzing = true
                            props.analysisStatus = "Starting analysis..."
                            props.analysisResults = "Initializing Azure OpenAI analysis...\n\n"
                            
                            -- Check configuration first
                            if not prefs.azureEndpoint or not prefs.azureApiKey or not prefs.deploymentName then
                                props.analysisResults = "ERROR: Azure OpenAI configuration missing!\n\n"
                                props.analysisResults = props.analysisResults .. "Please go to Library > Missing Opsin Settings to configure:\n"
                                props.analysisResults = props.analysisResults .. "• Endpoint: " .. (prefs.azureEndpoint or "Not set") .. "\n"
                                props.analysisResults = props.analysisResults .. "• API Key: " .. (prefs.azureApiKey and "Set" or "Not set") .. "\n"
                                props.analysisResults = props.analysisResults .. "• Deployment: " .. (prefs.deploymentName or "Not set") .. "\n"
                                props.analysisStatus = "Configuration required"
                                props.isAnalyzing = false
                                return
                            end
                            
                            local analysisText = "Azure OpenAI Color Analysis Results:\n"
                            analysisText = analysisText .. "Endpoint: " .. prefs.azureEndpoint .. "\n"
                            analysisText = analysisText .. "Deployment: " .. prefs.deploymentName .. "\n\n"
                            
                            -- Analyze each photo
                            for i, photo in ipairs(selectedPhotos) do
                                local photoName = photo:getFormattedMetadata("fileName") or ("Photo " .. i)
                                local photoPath = photo:getRawMetadata("path") or ""
                                
                                props.analysisStatus = "Analyzing photo " .. i .. " of " .. #selectedPhotos .. ": " .. photoName
                                analysisText = analysisText .. "=== " .. photoName .. " ===\n"
                                props.analysisResults = analysisText
                                
                                -- Make actual API call
                                local success, result = analyzePhotoWithAI(photoPath, photoName)
                                
                                if success then
                                    analysisText = analysisText .. result .. "\n\n"
                                    logger:trace("Successfully analyzed: " .. photoName)
                                else
                                    analysisText = analysisText .. "Error: " .. result .. "\n\n"
                                    logger:trace("Failed to analyze: " .. photoName .. " - " .. result)
                                end
                                
                                props.analysisResults = analysisText
                                
                                -- Small delay to show progress
                                if i < #selectedPhotos then
                                    LrTasks.sleep(0.5)
                                end
                            end
                            
                            props.analysisStatus = "Analysis complete - " .. #selectedPhotos .. " photo(s) processed"
                            props.isAnalyzing = false
                            logger:trace("Color analysis completed for all photos")
                        end)
                    end,
                },
                
                f:push_button {
                    title = "Apply Adjustments",
                    enabled = false, -- TODO: Enable when analysis is complete
                    action = function()
                        LrDialogs.message("Coming Soon", "Automatic adjustment application will be implemented in the next version.", "info")
                    end,
                },
            },
        }
        
        -- Show the dialog
        local result = LrDialogs.presentModalDialog {
            title = "Missing Opsin - Color Analysis",
            contents = contents,
            actionVerb = "Close",
        }
        
    end)
end

-- Execute the analysis
analyzeColors()
