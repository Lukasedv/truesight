--[[
Color Adjustments Module
Applies color corrections to photos in Lightroom
]]

local LrApplication = import 'LrApplication'
local LrDevelopController = import 'LrDevelopController'
local LrDialogs = import 'LrDialogs'

local ColorAdjustments = {}

-- Apply adjustments to a photo
function ColorAdjustments.applyAdjustments(photo, adjustments)
    if not adjustments or type(adjustments) ~= "table" then
        return false
    end
    
    local catalog = LrApplication.activeCatalog()
    
    catalog:withWriteAccessDo("Apply Missing Opsin Color Adjustments", function()
        -- Select the photo first
        catalog:setSelectedPhotos(photo, {photo})
        
        -- Apply basic adjustments
        if adjustments.exposure then
            LrDevelopController.setValue("Exposure2012", adjustments.exposure)
        end
        
        if adjustments.highlights then
            LrDevelopController.setValue("Highlights2012", adjustments.highlights)
        end
        
        if adjustments.shadows then
            LrDevelopController.setValue("Shadows2012", adjustments.shadows)
        end
        
        if adjustments.whites then
            LrDevelopController.setValue("Whites2012", adjustments.whites)
        end
        
        if adjustments.blacks then
            LrDevelopController.setValue("Blacks2012", adjustments.blacks)
        end
        
        if adjustments.temperature then
            LrDevelopController.setValue("Temperature", adjustments.temperature)
        end
        
        if adjustments.tint then
            LrDevelopController.setValue("Tint", adjustments.tint)
        end
        
        if adjustments.vibrance then
            LrDevelopController.setValue("Vibrance", adjustments.vibrance)
        end
        
        if adjustments.saturation then
            LrDevelopController.setValue("Saturation", adjustments.saturation)
        end
        
        -- Apply HSL adjustments
        ColorAdjustments.applyHSLAdjustments(adjustments)
    end)
    
    return true
end

-- Apply HSL (Hue, Saturation, Luminance) adjustments
function ColorAdjustments.applyHSLAdjustments(adjustments)
    local hslMapping = {
        -- Hue adjustments
        {key = "red_hue", lr_key = "HueAdjustmentRed"},
        {key = "orange_hue", lr_key = "HueAdjustmentOrange"},
        {key = "yellow_hue", lr_key = "HueAdjustmentYellow"},
        {key = "green_hue", lr_key = "HueAdjustmentGreen"},
        {key = "aqua_hue", lr_key = "HueAdjustmentAqua"},
        {key = "blue_hue", lr_key = "HueAdjustmentBlue"},
        {key = "purple_hue", lr_key = "HueAdjustmentPurple"},
        {key = "magenta_hue", lr_key = "HueAdjustmentMagenta"},
        
        -- Saturation adjustments
        {key = "red_saturation", lr_key = "SaturationAdjustmentRed"},
        {key = "orange_saturation", lr_key = "SaturationAdjustmentOrange"},
        {key = "yellow_saturation", lr_key = "SaturationAdjustmentYellow"},
        {key = "green_saturation", lr_key = "SaturationAdjustmentGreen"},
        {key = "aqua_saturation", lr_key = "SaturationAdjustmentAqua"},
        {key = "blue_saturation", lr_key = "SaturationAdjustmentBlue"},
        {key = "purple_saturation", lr_key = "SaturationAdjustmentPurple"},
        {key = "magenta_saturation", lr_key = "SaturationAdjustmentMagenta"},
        
        -- Luminance adjustments
        {key = "red_luminance", lr_key = "LuminanceAdjustmentRed"},
        {key = "orange_luminance", lr_key = "LuminanceAdjustmentOrange"},
        {key = "yellow_luminance", lr_key = "LuminanceAdjustmentYellow"},
        {key = "green_luminance", lr_key = "LuminanceAdjustmentGreen"},
        {key = "aqua_luminance", lr_key = "LuminanceAdjustmentAqua"},
        {key = "blue_luminance", lr_key = "LuminanceAdjustmentBlue"},
        {key = "purple_luminance", lr_key = "LuminanceAdjustmentPurple"},
        {key = "magenta_luminance", lr_key = "LuminanceAdjustmentMagenta"},
    }
    
    for _, mapping in ipairs(hslMapping) do
        if adjustments[mapping.key] and adjustments[mapping.key] ~= 0 then
            LrDevelopController.setValue(mapping.lr_key, adjustments[mapping.key])
        end
    end
end

-- Get current adjustments from a photo
function ColorAdjustments.getCurrentAdjustments(photo)
    local adjustments = {}
    
    if photo then
        local settings = photo:getDevelopSettings()
        
        adjustments.exposure = settings.Exposure2012 or 0
        adjustments.highlights = settings.Highlights2012 or 0
        adjustments.shadows = settings.Shadows2012 or 0
        adjustments.whites = settings.Whites2012 or 0
        adjustments.blacks = settings.Blacks2012 or 0
        adjustments.temperature = settings.Temperature or 0
        adjustments.tint = settings.Tint or 0
        adjustments.vibrance = settings.Vibrance or 0
        adjustments.saturation = settings.Saturation or 0
        
        -- HSL adjustments
        adjustments.red_hue = settings.HueAdjustmentRed or 0
        adjustments.orange_hue = settings.HueAdjustmentOrange or 0
        adjustments.yellow_hue = settings.HueAdjustmentYellow or 0
        adjustments.green_hue = settings.HueAdjustmentGreen or 0
        adjustments.aqua_hue = settings.HueAdjustmentAqua or 0
        adjustments.blue_hue = settings.HueAdjustmentBlue or 0
        adjustments.purple_hue = settings.HueAdjustmentPurple or 0
        adjustments.magenta_hue = settings.HueAdjustmentMagenta or 0
        
        adjustments.red_saturation = settings.SaturationAdjustmentRed or 0
        adjustments.orange_saturation = settings.SaturationAdjustmentOrange or 0
        adjustments.yellow_saturation = settings.SaturationAdjustmentYellow or 0
        adjustments.green_saturation = settings.SaturationAdjustmentGreen or 0
        adjustments.aqua_saturation = settings.SaturationAdjustmentAqua or 0
        adjustments.blue_saturation = settings.SaturationAdjustmentBlue or 0
        adjustments.purple_saturation = settings.SaturationAdjustmentPurple or 0
        adjustments.magenta_saturation = settings.SaturationAdjustmentMagenta or 0
        
        adjustments.red_luminance = settings.LuminanceAdjustmentRed or 0
        adjustments.orange_luminance = settings.LuminanceAdjustmentOrange or 0
        adjustments.yellow_luminance = settings.LuminanceAdjustmentYellow or 0
        adjustments.green_luminance = settings.LuminanceAdjustmentGreen or 0
        adjustments.aqua_luminance = settings.LuminanceAdjustmentAqua or 0
        adjustments.blue_luminance = settings.LuminanceAdjustmentBlue or 0
        adjustments.purple_luminance = settings.LuminanceAdjustmentPurple or 0
        adjustments.magenta_luminance = settings.LuminanceAdjustmentMagenta or 0
    end
    
    return adjustments
end

-- Reset all adjustments to default
function ColorAdjustments.resetAdjustments(photo)
    local catalog = LrApplication.activeCatalog()
    
    catalog:withWriteAccessDo("Reset Missing Opsin Adjustments", function()
        photo:resetDevelopmentSettings()
    end)
end

return ColorAdjustments