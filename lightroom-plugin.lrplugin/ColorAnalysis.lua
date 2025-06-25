--[[
Color Analysis Module
Main module for analyzing photos and providing color correction suggestions
]]

local LrApplication = import 'LrApplication'
local LrDialogs = import 'LrDialogs'
local LrFunctionContext = import 'LrFunctionContext'
local LrTasks = import 'LrTasks'
local LrHttp = import 'LrHttp'
local LrPathUtils = import 'LrPathUtils'
local LrFileUtils = import 'LrFileUtils'
local LrProgressScope = import 'LrProgressScope'

-- Lazy loading of dependencies to prevent plugin loading failures
local function getAzureOpenAI()
    local success, module = pcall(require, 'AzureOpenAI')
    if not success then
        LrDialogs.message('TrueSight Error', 'Azure OpenAI module failed to load. Please check your configuration.')
        return nil
    end
    return module
end

local function getColorAdjustments()
    local success, module = pcall(require, 'ColorAdjustments')
    if not success then
        LrDialogs.message('TrueSight Error', 'Color Adjustments module failed to load.')
        return nil
    end
    return module
end

local ColorAnalysis = {}

-- Main analysis function
function ColorAnalysis.analyzeSelectedPhotos()
    LrFunctionContext.callWithContext('analyzePhotos', function(context)
        local progressScope = LrProgressScope({
            title = 'TrueSight Color Analysis',
            functionContext = context,
        })
        
        local catalog = LrApplication.activeCatalog()
        local selectedPhotos = catalog:getTargetPhotos()
        
        if #selectedPhotos == 0 then
            LrDialogs.message('TrueSight', 'Please select one or more photos to analyze.')
            return
        end
        
        progressScope:setPortionComplete(0, #selectedPhotos)
        
        for i, photo in ipairs(selectedPhotos) do
            if progressScope:isCanceled() then
                break
            end
            
            progressScope:setCaption('Analyzing photo ' .. i .. ' of ' .. #selectedPhotos)
            
            -- Analyze individual photo
            ColorAnalysis.analyzeSinglePhoto(photo, context)
            
            progressScope:setPortionComplete(i, #selectedPhotos)
        end
        
        progressScope:done()
    end)
end

-- Analyze a single photo
function ColorAnalysis.analyzeSinglePhoto(photo, context)
    LrTasks.startAsyncTask(function()
        -- Get Azure OpenAI module with error handling
        local AzureOpenAI = getAzureOpenAI()
        if not AzureOpenAI then
            return
        end
        
        -- Export photo temporarily for analysis
        local tempPath = ColorAnalysis.exportPhotoForAnalysis(photo)
        
        if tempPath then
            -- Send to Azure OpenAI for analysis
            local analysis = AzureOpenAI.analyzeImage(tempPath)
            
            if analysis then
                -- Show results and suggestions
                ColorAnalysis.showAnalysisResults(photo, analysis)
            else
                LrDialogs.message('TrueSight Error', 'Failed to analyze photo. Please check your Azure OpenAI configuration.')
            end
            
            -- Clean up temporary file
            LrFileUtils.delete(tempPath)
        end
    end)
end

-- Export photo for analysis
function ColorAnalysis.exportPhotoForAnalysis(photo)
    local tempDir = LrPathUtils.getStandardFilePath('temp')
    local filename = 'truesight_' .. photo:getFormattedMetadata('fileName') .. '.jpg'
    local tempPath = LrPathUtils.child(tempDir, filename)
    
    -- Export photo as JPEG for analysis
    local exportSettings = {
        LR_export_destinationType = 'specificFolder',
        LR_export_destinationPathPrefix = tempDir,
        LR_export_destinationPathSuffix = '',
        LR_export_format = 'JPEG',
        LR_jpeg_quality = 0.8,
        LR_size_doConstrain = true,
        LR_size_maxWidth = 1920,
        LR_size_maxHeight = 1080,
        LR_size_units = 'pixels',
        LR_reimportExportedPhoto = false,
    }
    
    local success = photo:requestJpegThumbnail(1920, 1080, function(jpg, errorMessage)
        if jpg then
            local file = io.open(tempPath, 'wb')
            if file then
                file:write(jpg)
                file:close()
                return tempPath
            end
        end
        return nil
    end)
    
    return tempPath
end

-- Show analysis results to user
function ColorAnalysis.showAnalysisResults(photo, analysis)
    local result = LrDialogs.presentModalDialog({
        title = 'TrueSight Color Analysis Results',
        contents = ColorAnalysis.createResultsDialog(analysis),
        actionVerb = 'Apply Adjustments',
        cancelVerb = 'Close',
    })
    
    if result == 'ok' and analysis.adjustments then
        local ColorAdjustments = getColorAdjustments()
        if ColorAdjustments then
            ColorAdjustments.applyAdjustments(photo, analysis.adjustments)
        end
    end
end

-- Create results dialog UI
function ColorAnalysis.createResultsDialog(analysis)
    local LrView = import 'LrView'
    local f = LrView.osFactory()
    
    return f:column {
        spacing = f:control_spacing(),
        
        f:static_text {
            title = 'Color Analysis Results:',
            font = '<system/bold>',
        },
        
        f:edit_field {
            title = 'Analysis:',
            value = analysis.description or 'No analysis available',
            height_in_lines = 6,
            width_in_chars = 60,
            enabled = false,
        },
        
        f:static_text {
            title = 'Suggested Adjustments:',
            font = '<system/bold>',
        },
        
        f:edit_field {
            title = 'Adjustments:',
            value = analysis.suggestions or 'No suggestions available',
            height_in_lines = 4,
            width_in_chars = 60,
            enabled = false,
        },
    }
end

return ColorAnalysis.analyzeSelectedPhotos