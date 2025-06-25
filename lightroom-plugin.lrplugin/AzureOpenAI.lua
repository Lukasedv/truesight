--[[
Azure OpenAI Integration Module
Handles communication with Azure OpenAI service for image analysis
]]

local LrHttp = import 'LrHttp'
local LrDialogs = import 'LrDialogs'
local LrPrefs = import 'LrPrefs'
local LrPathUtils = import 'LrPathUtils'
local LrFileUtils = import 'LrFileUtils'
local LrStringUtils = import 'LrStringUtils'
local LrBase64 = import 'LrBase64'
local LrTasks = import 'LrTasks'

local AzureOpenAI = {}

-- Configuration
local AZURE_OPENAI_VERSION = "2024-02-15-preview"
local DEFAULT_MODEL = "gpt-4o"
local MAX_RETRIES = 3
local TIMEOUT = 30

-- Get configuration from preferences
function AzureOpenAI.getConfig()
    local prefs = LrPrefs.prefsForPlugin()
    return {
        endpoint = prefs.azureEndpoint or '',
        apiKey = prefs.azureApiKey or '',
        deploymentName = prefs.azureDeploymentName or '',
    }
end

-- Set configuration
function AzureOpenAI.setConfig(config)
    local prefs = LrPrefs.prefsForPlugin()
    prefs.azureEndpoint = config.endpoint or ''
    prefs.azureApiKey = config.apiKey or ''
    prefs.azureDeploymentName = config.deploymentName or ''
end

-- Analyze image with Azure OpenAI
function AzureOpenAI.analyzeImage(imagePath)
    local config = AzureOpenAI.getConfig()
    
    if not config.endpoint or not config.apiKey then
        LrDialogs.message('Missing Opsin Configuration Error', 
            'Please configure Azure OpenAI settings in the plugin preferences.')
        return nil
    end
    
    -- Read image file and encode to base64
    local imageData = LrFileUtils.readFile(imagePath)
    if not imageData then
        return nil
    end
    
    local base64Image = LrBase64.encode(imageData)
    
    -- Prepare the request
    local url = string.format("%s/openai/deployments/%s/chat/completions?api-version=%s", 
        config.endpoint, config.deploymentName or config.model, AZURE_OPENAI_VERSION)
    
    local headers = {
        ["Content-Type"] = "application/json",
        ["api-key"] = config.apiKey,
    }
    
    local requestBody = {
        model = config.model,
        messages = {
            {
                role = "system",
                content = AzureOpenAI.getSystemPrompt()
            },
            {
                role = "user",
                content = {
                    {
                        type = "text",
                        text = "Please analyze this photograph for color accuracy and provide suggestions for color correction that would help photographers with color deficiency (color blindness) make their photos look more natural and appealing."
                    },
                    {
                        type = "image_url",
                        image_url = {
                            url = "data:image/jpeg;base64," .. base64Image
                        }
                    }
                }
            }
        },
        max_tokens = 1000,
        temperature = 0.3,
    }
    
    local jsonBody = AzureOpenAI.encodeJson(requestBody)
    
    -- Make the API request with retries
    local result = nil
    for attempt = 1, MAX_RETRIES do
        local response, hdrs = LrHttp.post(url, jsonBody, headers, 'POST', TIMEOUT)
        
        if response then
            result = AzureOpenAI.parseResponse(response)
            if result then
                break
            end
        end
        
        if attempt < MAX_RETRIES then
            -- Wait before retry
            LrTasks.sleep(1)
        end
    end
    
    return result
end

-- Get system prompt for color analysis
function AzureOpenAI.getSystemPrompt()
    return [[You are an expert photography assistant specializing in helping photographers with color deficiency (color blindness) improve their photos. 

When analyzing images, focus on:
1. Overall color balance and accuracy
2. Skin tone naturalness
3. Color harmony and contrast
4. Potential issues that might not be visible to someone with color deficiency
5. Specific Lightroom adjustments that can improve the image

Provide your response in this JSON format:
{
    "description": "Brief analysis of the current color characteristics",
    "issues": ["List of specific color issues found"],
    "suggestions": "Detailed suggestions for improvement",
    "adjustments": {
        "exposure": 0.0,
        "highlights": 0,
        "shadows": 0,
        "whites": 0,
        "blacks": 0,
        "temperature": 0,
        "tint": 0,
        "vibrance": 0,
        "saturation": 0,
        "red_hue": 0,
        "red_saturation": 0,
        "red_luminance": 0,
        "orange_hue": 0,
        "orange_saturation": 0,
        "orange_luminance": 0,
        "yellow_hue": 0,
        "yellow_saturation": 0,
        "yellow_luminance": 0,
        "green_hue": 0,
        "green_saturation": 0,
        "green_luminance": 0,
        "aqua_hue": 0,
        "aqua_saturation": 0,
        "aqua_luminance": 0,
        "blue_hue": 0,
        "blue_saturation": 0,
        "blue_luminance": 0,
        "purple_hue": 0,
        "purple_saturation": 0,
        "purple_luminance": 0,
        "magenta_hue": 0,
        "magenta_saturation": 0,
        "magenta_luminance": 0
    }
}

Only suggest adjustments where you're confident they would improve the image. Use 0 for parameters that don't need adjustment.]]
end

-- Simple JSON encoding (basic implementation)
function AzureOpenAI.encodeJson(data)
    if type(data) == "table" then
        local result = {}
        local isArray = true
        local maxIndex = 0
        
        -- Check if it's an array
        for k, v in pairs(data) do
            if type(k) ~= "number" then
                isArray = false
                break
            end
            maxIndex = math.max(maxIndex, k)
        end
        
        if isArray and maxIndex == #data then
            -- Array
            for i, v in ipairs(data) do
                table.insert(result, AzureOpenAI.encodeJson(v))
            end
            return "[" .. table.concat(result, ",") .. "]"
        else
            -- Object
            for k, v in pairs(data) do
                table.insert(result, '"' .. tostring(k) .. '":' .. AzureOpenAI.encodeJson(v))
            end
            return "{" .. table.concat(result, ",") .. "}"
        end
    elseif type(data) == "string" then
        return '"' .. string.gsub(data, '"', '\\"') .. '"'
    else
        return tostring(data)
    end
end

-- Parse API response
function AzureOpenAI.parseResponse(response)
    -- Simple JSON parsing for the response
    local success, result = pcall(function()
        -- Extract the content from the response
        local content = response:match('"content":"([^"]*)"')
        if content then
            -- Unescape JSON
            content = content:gsub('\\"', '"'):gsub('\\\\', '\\')
            
            -- Try to parse as JSON
            local data = AzureOpenAI.parseJson(content)
            return data
        end
        return nil
    end)
    
    if success and result then
        return result
    else
        -- Fallback: return raw content if JSON parsing fails
        local content = response:match('"content":"([^"]*)"')
        if content then
            return {
                description = content,
                suggestions = "Manual review recommended",
                adjustments = {}
            }
        end
    end
    
    return nil
end

-- Simple JSON parsing (basic implementation)
function AzureOpenAI.parseJson(jsonStr)
    -- This is a very basic JSON parser - in production, you'd want a more robust solution
    local result = {}
    
    -- Extract description
    local description = jsonStr:match('"description"%s*:%s*"([^"]*)"')
    if description then
        result.description = description
    end
    
    -- Extract suggestions
    local suggestions = jsonStr:match('"suggestions"%s*:%s*"([^"]*)"')
    if suggestions then
        result.suggestions = suggestions
    end
    
    -- Extract adjustments object
    local adjustments = {}
    local adjustmentsStr = jsonStr:match('"adjustments"%s*:%s*{([^}]*))')
    if adjustmentsStr then
        for key, value in adjustmentsStr:gmatch('"([^"]+)"%s*:%s*([^,}]+)') do
            adjustments[key] = tonumber(value) or 0
        end
    end
    result.adjustments = adjustments
    
    return result
end

return AzureOpenAI