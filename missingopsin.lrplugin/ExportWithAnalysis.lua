--[[----------------------------------------------------------------------------

Missing Opsin - Lightroom Plugin for Color Deficiency Support
Copyright 2025

ExportWithAnalysis.lua
Export menu integration for color analysis.

------------------------------------------------------------------------------]]

-- Access the Lightroom SDK namespaces
local LrDialogs = import 'LrDialogs'
local LrLogger = import 'LrLogger'

-- Create logger
local logger = LrLogger('MissingOpsinLogger')
logger:enable("print")

--------------------------------------------------------------------------------
-- Export with analysis function

local function exportWithAnalysis()
    logger:trace("Export with analysis called")
    
    LrDialogs.message(
        "Export Feature Coming Soon", 
        "The export integration feature will be available in a future version. For now, please use the Library > Missing Opsin Color Analysis menu item to analyze your photos.", 
        "info"
    )
end

-- Execute the export function
exportWithAnalysis()
