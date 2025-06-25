--[[
Export Dialog Module
Provides export functionality with color analysis
]]

local LrView = import 'LrView'
local LrFunctionContext = import 'LrFunctionContext'
local LrBinding = import 'LrBinding'
local LrDialogs = import 'LrDialogs'
local LrApplication = import 'LrApplication'

-- Lazy loading to prevent plugin loading failures
local function getColorAnalysis()
    local success, module = pcall(require, 'ColorAnalysis')
    if not success then
        LrDialogs.message('TrueSight Error', 'Color Analysis module failed to load.')
        return nil
    end
    return module
end

local ExportDialog = {}

function ExportDialog.showDialog()
    LrFunctionContext.callWithContext('exportDialog', function(context)
        local f = LrView.osFactory()
        local bind = LrView.bind
        local share = LrView.share
        
        local props = LrBinding.makePropertyTable(context)
        props.analyzeBeforeExport = true
        props.applyAdjustments = false
        props.exportFormat = 'JPEG'
        
        local contents = f:column {
            spacing = f:control_spacing(),
            
            f:row {
                f:static_text {
                    title = 'TrueSight Export with Color Analysis',
                    font = '<system/bold>',
                },
            },
            
            f:separator { fill_horizontal = 1 },
            
            f:group_box {
                title = 'Analysis Options',
                f:column {
                    spacing = f:control_spacing(),
                    
                    f:checkbox {
                        title = 'Analyze colors before export',
                        value = bind 'analyzeBeforeExport',
                    },
                    
                    f:checkbox {
                        title = 'Automatically apply suggested adjustments',
                        value = bind 'applyAdjustments',
                        enabled = bind 'analyzeBeforeExport',
                    },
                },
            },
            
            f:group_box {
                title = 'Export Settings',
                f:column {
                    spacing = f:control_spacing(),
                    
                    f:row {
                        f:static_text {
                            title = 'Format:',
                            alignment = 'right',
                            width = share 'labelWidth',
                        },
                        
                        f:popup_menu {
                            value = bind 'exportFormat',
                            items = {
                                { title = 'JPEG', value = 'JPEG' },
                                { title = 'TIFF', value = 'TIFF' },
                                { title = 'PNG', value = 'PNG' },
                            },
                        },
                    },
                },
            },
        }
        
        local result = LrDialogs.presentModalDialog({
            title = 'TrueSight Export',
            contents = contents,
            actionVerb = 'Export',
        })
        
        if result == 'ok' then
            ExportDialog.processExport(props)
        end
    end)
end

function ExportDialog.processExport(props)
    local catalog = LrApplication.activeCatalog()
    local selectedPhotos = catalog:getTargetPhotos()
    
    if #selectedPhotos == 0 then
        LrDialogs.message('TrueSight Export', 'Please select photos to export.')
        return
    end
    
    if props.analyzeBeforeExport then
        local ColorAnalysis = getColorAnalysis()
        if ColorAnalysis then
            -- Analyze photos first
            for _, photo in ipairs(selectedPhotos) do
                ColorAnalysis.analyzeSinglePhoto(photo)
            end
        else
            LrDialogs.message('TrueSight Export', 'Color analysis is not available. Proceeding with standard export.')
        end
    end
    
    -- Proceed with standard export
    LrDialogs.message('TrueSight Export', 'Analysis complete. Photos ready for standard export.')
end

-- Export the module
return ExportDialog.showDialog