--[[----------------------------------------------------------------------------

Missing Opsin - Lightroom Plugin for Color Deficiency Support
Copyright 2025

Info.lua
Main plugin information and menu definitions.

------------------------------------------------------------------------------]]

return {
	
	LrSdkVersion = 13.0,
	LrSdkMinimumVersion = 10.0, -- minimum SDK version required by this plug-in

	LrToolkitIdentifier = 'com.missingopsin.lightroom.plugin',

	LrPluginName = "Missing Opsin",
	
	-- Add the menu items to the Library menu for photo analysis
	LrLibraryMenuItems = {
	    {
		    title = "Missing Opsin Color Analysis",
		    file = "ColorAnalysis.lua",
		},
		{
		    title = "Missing Opsin Settings",
		    file = "Settings.lua",
		},
	},

	-- Add the menu item to the Help menu for configuration
	LrHelpMenuItems = {
		{
			title = "Missing Opsin Help",
			file = "HelpDialog.lua",
		},
	},

	-- Add export menu item for analyzing colors during export
	LrExportMenuItems = {
		title = "Analyze Colors with Missing Opsin",
		file = "ExportWithAnalysis.lua",
	},

	VERSION = { major=1, minor=0, revision=0, build="20250625-001", },

}
