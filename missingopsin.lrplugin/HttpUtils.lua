--[[----------------------------------------------------------------------------

Missing Opsin - Lightroom Plugin for Color Deficiency Support
Copyright 2025

HttpUtils.lua
HTTP utility functions for Azure OpenAI API calls.

------------------------------------------------------------------------------]]

local LrHttp = import 'LrHttp'
local LrLogger = import 'LrLogger'

-- Create logger
local logger = LrLogger('MissingOpsinHttpLogger')
logger:enable("print")

local HttpUtils = {}

--------------------------------------------------------------------------------
-- Test basic Azure OpenAI endpoint accessibility
function HttpUtils.testBasicEndpoint(endpoint, apiKey)
    logger:trace("Testing basic Azure OpenAI endpoint accessibility")
    
    -- Note: Azure OpenAI doesn't support the deployments listing endpoint
    -- So we'll just validate the endpoint format and API key format here
    local cleanEndpoint = endpoint:gsub("/$", "")
    
    logger:trace("DIAGNOSTIC: Basic endpoint validation")
    logger:trace("DIAGNOSTIC: Clean endpoint: " .. cleanEndpoint)
    logger:trace("DIAGNOSTIC: API key length: " .. tostring(string.len(apiKey or "")))
    logger:trace("DIAGNOSTIC: API key first 10 chars: " .. (apiKey and apiKey:sub(1, 10) or "nil") .. "...")
    
    -- Validate endpoint format
    if not cleanEndpoint:match("^https://.*%.openai%.azure%.com$") then
        return false, "❌ Invalid Azure OpenAI endpoint format. Expected format: https://your-service.openai.azure.com"
    end
    
    -- Validate API key format
    if not apiKey or apiKey == "" then
        return false, "❌ API key is empty"
    end
    
    if string.len(apiKey) < 10 then
        return false, "❌ API key appears too short (less than 10 characters)"
    end
    
    logger:trace("DIAGNOSTIC: Basic validation passed")
    return true, "✓ Endpoint format and API key format appear valid"
end

--------------------------------------------------------------------------------
-- Test Azure OpenAI connection
function HttpUtils.testAzureOpenAIConnection(endpoint, apiKey, deploymentName)
    logger:trace("=== STARTING AZURE OPENAI CONNECTION TEST ===")
    logger:trace("DIAGNOSTIC: Endpoint: " .. tostring(endpoint))
    logger:trace("DIAGNOSTIC: Deployment: " .. tostring(deploymentName))
    logger:trace("DIAGNOSTIC: API Key length: " .. tostring(string.len(apiKey or "")))
    logger:trace("DIAGNOSTIC: API Key first 10 chars: " .. (apiKey and apiKey:sub(1, 10) or "nil") .. "...")
    
    -- First, do basic validation
    logger:trace("DIAGNOSTIC: Step 1 - Basic validation")
    local basicSuccess, basicMessage = HttpUtils.testBasicEndpoint(endpoint, apiKey)
    if not basicSuccess then
        logger:trace("DIAGNOSTIC: Basic validation failed: " .. basicMessage)
        return false, "STEP 1 FAILED - " .. basicMessage
    end
    
    logger:trace("DIAGNOSTIC: Step 1 passed - " .. basicMessage)
    logger:trace("DIAGNOSTIC: Step 2 - Testing chat completions endpoint with deployment")
    
    -- Clean up endpoint URL
    local cleanEndpoint = endpoint:gsub("/$", "") -- Remove trailing slash
    
    -- Use the stable API version (2025-01-01-preview may not work with Lightroom's HTTP client)
    local apiUrl = cleanEndpoint .. "/openai/deployments/" .. deploymentName .. "/chat/completions?api-version=2024-06-01"
    
    logger:trace("DIAGNOSTIC: Full deployment API URL: " .. apiUrl)
    logger:trace("DIAGNOSTIC: Clean endpoint: " .. cleanEndpoint)
    logger:trace("DIAGNOSTIC: Deployment name: " .. deploymentName)
    
    -- Prepare headers with correct Lightroom format (table of tables with field/value)
    local headers = {
        { field = 'Content-Type', value = 'application/json' },
        { field = 'api-key', value = apiKey },
    }
    
    logger:trace("DIAGNOSTIC: Headers prepared")
    for i, header in ipairs(headers) do
        if header.field == "api-key" then
            logger:trace("DIAGNOSTIC: Header " .. header.field .. " = " .. (header.value:sub(1, 10) or "") .. "... (truncated)")
        else
            logger:trace("DIAGNOSTIC: Header " .. header.field .. " = " .. tostring(header.value))
        end
    end
    
    -- Test payload matching the working curl sample
    local testPayload = {
        messages = {
            {
                role = "user",
                content = "Test connection"
            }
        },
        model = deploymentName,  -- Include model field as in working sample
        max_completion_tokens = 5,  -- Use max_completion_tokens instead of max_tokens
        temperature = 0
    }
    
    -- Convert payload to JSON string
    local jsonPayload = HttpUtils.tableToJson(testPayload)
    logger:trace("DIAGNOSTIC: Request payload length: " .. tostring(string.len(jsonPayload)))
    logger:trace("DIAGNOSTIC: Request payload: " .. jsonPayload)
    
    -- Make the HTTP request
    logger:trace("DIAGNOSTIC: Making HTTP POST request...")
    local response, responseHeaders = LrHttp.post(apiUrl, jsonPayload, headers)
    
    logger:trace("DIAGNOSTIC: HTTP request completed")
    
    -- Log detailed response information
    if responseHeaders then
        logger:trace("DIAGNOSTIC: Response headers received")
        for k, v in pairs(responseHeaders) do
            logger:trace("DIAGNOSTIC: Response header " .. tostring(k) .. " = " .. tostring(v))
        end
    else
        logger:trace("DIAGNOSTIC: No response headers received")
    end
    
    if response then
        logger:trace("DIAGNOSTIC: Response body length: " .. tostring(string.len(response)))
        logger:trace("DIAGNOSTIC: Response body: " .. tostring(response))
    else
        logger:trace("DIAGNOSTIC: No response body received")
    end
    
    -- Check response
    if response then
        logger:trace("DIAGNOSTIC: Response body: " .. tostring(response))
        
        -- Check if we got a valid response (even an error response is good - means we connected)
        if responseHeaders and responseHeaders.status then
            local status = responseHeaders.status
            logger:trace("DIAGNOSTIC: HTTP Status: " .. tostring(status))
            
            if status == 200 then
                return true, "✓ Connection successful! Deployment " .. deploymentName .. " is working with API version 2024-06-01."
            elseif status == 401 then
                return false, "❌ Authentication failed at deployment level. API key may not have permissions for deployment '" .. deploymentName .. "'. Check your Azure OpenAI resource permissions."
            elseif status == 404 then
                return false, "❌ Deployment '" .. deploymentName .. "' not found OR API version 2024-06-01 not supported. \n\nTested URL: " .. apiUrl .. "\n\nTry different API version or verify deployment name in Azure portal."
            elseif status == 400 then
                -- Bad request - might be API version issue, try older version
                logger:trace("DIAGNOSTIC: 400 error, trying fallback API version")
                return HttpUtils.testWithOlderApiVersion(cleanEndpoint, apiKey, deploymentName)
            elseif status == 429 then
                return false, "❌ Rate limit exceeded (HTTP 429). Your Azure OpenAI service is being throttled. Wait a moment and try again."
            elseif status >= 400 and status < 500 then
                return false, "❌ Client error (HTTP " .. status .. "). URL: " .. apiUrl .. "\n\nResponse details: " .. (response or "No details available")
            elseif status >= 500 then
                return false, "❌ Server error (HTTP " .. status .. "). Azure OpenAI service may be temporarily unavailable. Try again in a few minutes."
            else
                return true, "⚠️ Unexpected response (HTTP " .. status .. ") but connection established. May still work for analysis."
            end
        else
            return false, "❌ Invalid response from server. No HTTP status code received. Check network connectivity."
        end
    else
        return false, "❌ Failed to connect to deployment endpoint. No response received. \n\nURL tested: " .. apiUrl .. "\n\nCheck network connectivity and firewall settings."
    end
end

--------------------------------------------------------------------------------
-- Try with older API version
function HttpUtils.testWithOlderApiVersion(cleanEndpoint, apiKey, deploymentName)
    logger:trace("DIAGNOSTIC: Trying fallback API version 2024-02-01")
    
    local apiUrl = cleanEndpoint .. "/openai/deployments/" .. deploymentName .. "/chat/completions?api-version=2024-02-01"
    logger:trace("DIAGNOSTIC: Fallback API URL: " .. apiUrl)
    
    local headers = {
        { field = 'Content-Type', value = 'application/json' },
        { field = 'api-key', value = apiKey },
    }
    
    local testPayload = {
        messages = {
            {
                role = "user",
                content = "Test connection"
            }
        },
        model = deploymentName,  -- Include model field
        max_completion_tokens = 5,  -- Use max_completion_tokens
        temperature = 0
    }
    
    local jsonPayload = HttpUtils.tableToJson(testPayload)
    logger:trace("DIAGNOSTIC: Making fallback request...")
    local response, responseHeaders = LrHttp.post(apiUrl, jsonPayload, headers)
    
    logger:trace("DIAGNOSTIC: Fallback request completed")
    if responseHeaders then
        for k, v in pairs(responseHeaders) do
            logger:trace("DIAGNOSTIC: Fallback header " .. tostring(k) .. " = " .. tostring(v))
        end
    end
    
    if response then
        logger:trace("DIAGNOSTIC: Fallback response: " .. tostring(response))
    end
    
    if responseHeaders and responseHeaders.status then
        local status = responseHeaders.status
        logger:trace("DIAGNOSTIC: Fallback API version HTTP Status: " .. tostring(status))
        
        if status == 200 then
            return true, "✓ Connection successful using fallback API version 2024-02-01! Consider updating to newer API version."
        elseif status == 401 then
            return false, "❌ Authentication failed with both API versions (2024-06-01 and 2024-02-01). Please verify your API key has proper permissions."
        elseif status == 404 then
            return false, "❌ Deployment '" .. deploymentName .. "' not found with either API version. \n\nPlease verify deployment name in Azure portal. \n\nTested URLs:\n- " .. cleanEndpoint .. "/openai/deployments/" .. deploymentName .. "/chat/completions?api-version=2024-06-01\n- " .. apiUrl
        else
            return false, "❌ Error with both API versions. Latest attempt (HTTP " .. status .. "): " .. (response or "No response details")
        end
    else
        return false, "❌ Failed to connect with either API version (2024-06-01 or 2024-02-01). Check network connectivity."
    end
end

--------------------------------------------------------------------------------
-- Simple JSON table to string conversion
function HttpUtils.tableToJson(t)
    local function escape(s)
        return s:gsub('\\', '\\\\'):gsub('"', '\\"'):gsub('\n', '\\n'):gsub('\r', '\\r'):gsub('\t', '\\t')
    end
    
    local function serializeValue(val)
        local valType = type(val)
        if valType == "string" then
            return '"' .. escape(val) .. '"'
        elseif valType == "number" then
            return tostring(val)
        elseif valType == "boolean" then
            return val and "true" or "false"
        elseif valType == "table" then
            return HttpUtils.tableToJson(val)
        else
            return '"' .. escape(tostring(val)) .. '"'
        end
    end
    
    if type(t) ~= "table" then
        return serializeValue(t)
    end
    
    -- Check if it's an array
    local isArray = true
    local arraySize = 0
    for k, v in pairs(t) do
        if type(k) ~= "number" then
            isArray = false
            break
        end
        arraySize = arraySize + 1
    end
    
    if isArray then
        local parts = {}
        for i = 1, arraySize do
            table.insert(parts, serializeValue(t[i]))
        end
        return "[" .. table.concat(parts, ",") .. "]"
    else
        local parts = {}
        for k, v in pairs(t) do
            table.insert(parts, '"' .. escape(tostring(k)) .. '":' .. serializeValue(v))
        end
        return "{" .. table.concat(parts, ",") .. "}"
    end
end

--------------------------------------------------------------------------------
-- Make Azure OpenAI API call for color analysis
function HttpUtils.analyzeColors(endpoint, apiKey, deploymentName, prompt, photoName)
    logger:trace("Making color analysis API call for: " .. photoName)
    
    -- Validate inputs
    if not endpoint or endpoint == "" then
        return false, "Azure endpoint not configured"
    end
    if not apiKey or apiKey == "" then
        return false, "Azure API key not configured"
    end
    if not deploymentName or deploymentName == "" then
        return false, "Azure deployment name not configured"
    end
    
    -- Clean up endpoint URL
    local cleanEndpoint = endpoint:gsub("/$", "")
    local apiUrl = cleanEndpoint .. "/openai/deployments/" .. deploymentName .. "/chat/completions?api-version=2024-06-01"
    
    -- Prepare headers with correct Lightroom format (table of tables with field/value)
    local headers = {
        { field = 'Content-Type', value = 'application/json' },
        { field = 'api-key', value = apiKey },
    }
    
    -- Create the analysis payload matching Azure OpenAI format
    local payload = {
        messages = {
            {
                role = "system",
                content = "You are a professional photography color analyst helping photographers with color deficiency. Provide specific, actionable recommendations for color correction in Adobe Lightroom. Focus on color balance, skin tones, saturation, and HSL adjustments."
            },
            {
                role = "user",
                content = "Analyze the color characteristics of the photo named '" .. photoName .. "'. " .. prompt
            }
        },
        model = deploymentName,  -- Include model field
        max_completion_tokens = 800,  -- Use max_completion_tokens
        temperature = 0.3,
        top_p = 0.95
    }
    
    -- Convert payload to JSON string
    local jsonPayload = HttpUtils.tableToJson(payload)
    logger:trace("API Request URL: " .. apiUrl)
    logger:trace("Request payload length: " .. tostring(string.len(jsonPayload)))
    
    -- Make the HTTP request
    local response, responseHeaders = LrHttp.post(apiUrl, jsonPayload, headers)
    
    -- Handle response
    if response and responseHeaders and responseHeaders.status then
        local status = responseHeaders.status
        logger:trace("API Response Status: " .. tostring(status))
        logger:trace("Response length: " .. tostring(string.len(response or "")))
        
        if status == 200 then
            -- Parse the response to extract the content
            local content = HttpUtils.parseOpenAIResponse(response)
            if content then
                logger:trace("Successfully parsed response content")
                return true, content
            else
                logger:trace("Failed to parse response content")
                return false, "Unable to parse API response format. Raw response: " .. (response or "empty")
            end
        elseif status == 401 then
            return false, "Authentication failed - please check your API key"
        elseif status == 404 then
            return false, "Deployment '" .. deploymentName .. "' not found on endpoint " .. cleanEndpoint
        elseif status == 429 then
            return false, "Rate limit exceeded - please try again later"
        elseif status >= 500 then
            return false, "Azure OpenAI service error (HTTP " .. status .. ")"
        else
            local errorDetails = response and (": " .. response) or ""
            return false, "API error (HTTP " .. status .. ")" .. errorDetails
        end
    else
        logger:trace("No response or invalid response headers")
        return false, "Unable to connect to Azure OpenAI service. Check your internet connection and endpoint configuration."
    end
end

--------------------------------------------------------------------------------
-- Parse OpenAI API response to extract content
function HttpUtils.parseOpenAIResponse(response)
    if not response then
        return nil
    end
    
    -- Simple JSON parsing to extract the content field
    -- Look for the pattern: "content":"..."
    local contentStart = response:find('"content":"')
    if contentStart then
        contentStart = contentStart + 12 -- Skip the '"content":"' part
        
        -- Find the end of the content (looking for the next field or end of object)
        local contentEnd = nil
        local pos = contentStart
        local escapeNext = false
        
        while pos <= #response do
            local char = response:sub(pos, pos)
            
            if escapeNext then
                escapeNext = false
            elseif char == '\\' then
                escapeNext = true
            elseif char == '"' then
                contentEnd = pos - 1
                break
            end
            
            pos = pos + 1
        end
        
        if contentEnd then
            local content = response:sub(contentStart, contentEnd)
            -- Unescape JSON content
            content = content:gsub('\\"', '"')
                           :gsub('\\n', '\n')
                           :gsub('\\r', '\r')
                           :gsub('\\t', '\t')
                           :gsub('\\\\', '\\')
            return content
        end
    end
    
    logger:trace("Could not parse response content")
    return nil
end

--------------------------------------------------------------------------------
-- Generate diagnostic information for HTTP requests
function HttpUtils.generateDiagnosticInfo(endpoint, apiKey, deploymentName)
    local cleanEndpoint = endpoint:gsub("/$", "")
    local apiUrl = cleanEndpoint .. "/openai/deployments/" .. deploymentName .. "/chat/completions?api-version=2024-06-01"
    
    local headers = {
        { field = 'Content-Type', value = 'application/json' },
        { field = 'api-key', value = apiKey },
    }
    
    local testPayload = {
        messages = {
            {
                role = "user",
                content = "Test connection"
            }
        },
        model = deploymentName,
        max_completion_tokens = 5,
        temperature = 0
    }
    
    local jsonPayload = HttpUtils.tableToJson(testPayload)
    
    -- Format headers for display (mask API key)
    local headersDisplay = "Content-Type: application/json\n"
    headersDisplay = headersDisplay .. "api-key: " .. (apiKey:sub(1, 8) .. "..." .. apiKey:sub(-4)) .. " (masked for security)"
    
    local diagnosticInfo = {
        url = apiUrl,
        headers = headersDisplay,
        payload = jsonPayload,
        payloadPretty = "{\n  \"messages\": [\n    {\n      \"role\": \"user\",\n      \"content\": \"Test connection\"\n    }\n  ],\n  \"model\": \"" .. deploymentName .. "\",\n  \"max_completion_tokens\": 5,\n  \"temperature\": 0\n}"
    }
    
    return diagnosticInfo
end

--------------------------------------------------------------------------------
-- Enhanced connection test with detailed HTTP information
function HttpUtils.testAzureOpenAIConnectionDetailed(endpoint, apiKey, deploymentName)
    logger:trace("=== DETAILED AZURE OPENAI CONNECTION TEST ===")
    
    -- Generate diagnostic info
    local diagnostics = HttpUtils.generateDiagnosticInfo(endpoint, apiKey, deploymentName)
    
    logger:trace("DETAILED TEST: URL = " .. diagnostics.url)
    logger:trace("DETAILED TEST: Payload = " .. diagnostics.payload)
    
    -- Validate inputs
    if not endpoint or endpoint == "" then
        return false, "Azure endpoint not configured", nil
    end
    if not apiKey or apiKey == "" then
        return false, "Azure API key not configured", nil
    end
    if not deploymentName or deploymentName == "" then
        return false, "Azure deployment name not configured", nil
    end
    
    -- Clean up endpoint URL
    local cleanEndpoint = endpoint:gsub("/$", "")
    local apiUrl = cleanEndpoint .. "/openai/deployments/" .. deploymentName .. "/chat/completions?api-version=2024-06-01"
    
    -- Prepare headers with correct Lightroom format
    local headers = {
        { field = 'Content-Type', value = 'application/json' },
        { field = 'api-key', value = apiKey },
    }
    
    -- Test payload
    local testPayload = {
        messages = {
            {
                role = "user",
                content = "Test connection"
            }
        },
        model = deploymentName,
        max_completion_tokens = 5,
        temperature = 0
    }
    
    local jsonPayload = HttpUtils.tableToJson(testPayload)
    
    -- Make the HTTP request
    logger:trace("DETAILED TEST: Making HTTP POST request...")
    local response, responseHeaders = LrHttp.post(apiUrl, jsonPayload, headers)
    
    -- Collect detailed response information
    local detailedInfo = {
        requestUrl = apiUrl,
        requestHeaders = headers,
        requestPayload = jsonPayload,
        responseStatus = responseHeaders and responseHeaders.status or "No status",
        responseHeaders = responseHeaders or {},
        responseBody = response or "No response body",
        timestamp = os.date("%Y-%m-%d %H:%M:%S")
    }
    
    -- Check response
    if response and responseHeaders and responseHeaders.status then
        local status = responseHeaders.status
        logger:trace("DETAILED TEST: HTTP Status: " .. tostring(status))
        
        if status == 200 then
            return true, "✓ Connection successful! (API version 2024-06-01)", detailedInfo
        elseif status == 401 then
            return false, "❌ Authentication failed (HTTP 401). API key rejected by Azure OpenAI.", detailedInfo
        elseif status == 404 then
            return false, "❌ Not found (HTTP 404). Check deployment name and API version.", detailedInfo
        elseif status == 400 then
            return false, "❌ Bad request (HTTP 400). Payload format may be incorrect.", detailedInfo
        elseif status == 429 then
            return false, "❌ Rate limit exceeded (HTTP 429).", detailedInfo
        elseif status >= 500 then
            return false, "❌ Server error (HTTP " .. status .. ").", detailedInfo
        else
            return false, "❌ Unexpected response (HTTP " .. status .. ").", detailedInfo
        end
    else
        detailedInfo.responseStatus = "No HTTP response"
        return false, "❌ Failed to connect. No HTTP response received.", detailedInfo
    end
end

--------------------------------------------------------------------------------
-- Test with Lightroom-compatible parameters
function HttpUtils.testLightroomCompatibility(endpoint, apiKey, deploymentName)
    logger:trace("=== TESTING LIGHTROOM HTTP CLIENT COMPATIBILITY ===")
    
    local cleanEndpoint = endpoint:gsub("/$", "")
    local apiUrl = cleanEndpoint .. "/openai/deployments/" .. deploymentName .. "/chat/completions?api-version=2024-06-01"
    
    local headers = {
        { field = 'Content-Type', value = 'application/json' },
        { field = 'api-key', value = apiKey },
    }
    
    -- Test with old max_tokens parameter for Lightroom compatibility
    local testPayload = {
        messages = {
            {
                role = "user",
                content = "Test connection"
            }
        },
        max_tokens = 5,  -- Use old parameter
        temperature = 0
        -- Remove model field to simplify
    }
    
    local jsonPayload = HttpUtils.tableToJson(testPayload)
    logger:trace("LIGHTROOM COMPAT TEST: Making request with simplified payload...")
    logger:trace("LIGHTROOM COMPAT TEST: URL: " .. apiUrl)
    logger:trace("LIGHTROOM COMPAT TEST: Payload: " .. jsonPayload)
    
    local response, responseHeaders = LrHttp.post(apiUrl, jsonPayload, headers)
    
    if response and responseHeaders and responseHeaders.status then
        local status = responseHeaders.status
        logger:trace("LIGHTROOM COMPAT TEST: Status: " .. tostring(status))
        logger:trace("LIGHTROOM COMPAT TEST: Response: " .. tostring(response))
        
        if status == 200 then
            return true, "✓ Lightroom compatibility test successful with simplified parameters!"
        else
            return false, "❌ Lightroom compatibility test failed (HTTP " .. status .. "): " .. (response or "No response")
        end
    else
        return false, "❌ Lightroom compatibility test failed: No response received"
    end
end

return HttpUtils
