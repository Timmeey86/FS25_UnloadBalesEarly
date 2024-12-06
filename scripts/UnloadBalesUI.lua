---This class adds UI controls for settings of the mod
---@class UnloadBalesUI
---@field settings UnloadBalesSettings @The settings object
---@field controls table @A list of all UI controls
---@field sectionTitle table @The UI header for UnloadBalesEarly settings
---@field overloadingThreshold table @The UI control for the overload threshold
---@field unloadingThreshold table @The UI control for the unload threshold
UnloadBalesUI = {
}

local UnloadBalesUI_mt = Class(UnloadBalesUI)

---Creates a new instance
---@param settings UnloadBalesSettings @The settings object
---@return UnloadBalesUI @The new instance
function UnloadBalesUI.new(settings)
	local self = setmetatable({}, UnloadBalesUI_mt)

	self.controls = {}
	self.settings = settings
	self.isInitialized = false
	return self
end

---Injects the UI into the base game UI
function UnloadBalesUI:injectUiSettings()
	if self.isInitialized then
		return
	end
	self.isInitialized = true

	print(MOD_NAME .. ": Injecting UI settings")
	-- Get a reference to the base game general settings page
	local settingsPage = g_gui.screenControllers[InGameMenu].pageSettings

	-- Define the UI controls. For each control, a <prefix>_<name>_short and _long key must exist in the i18n values
	local controlProperties = {
		{ name = "overloadingThreshold", min = 0, max = 90, step = 10, autoBind = true, nillable = true },
		{ name = "unloadingThreshold", min = 0, max = 90, step = 10, autoBind = true, nillable = true }
	}
	UIHelper.createControlsDynamically(settingsPage, "ub_section_title", self, controlProperties, "ub_")
	UIHelper.setupAutoBindControls(self, self.settings, UnloadBalesUI.onSettingsChange)

	-- Apply initial values
	self:updateUiElements()

	-- Trigger an update in order to enable/disable controls on settings frame open
	InGameMenuSettingsFrame.onFrameOpen = Utils.appendedFunction(InGameMenuSettingsFrame.onFrameOpen, function()
		self:updateUiElements(true) -- skip autobind controls
	end)
end

function UnloadBalesUI:onSettingsChange()
	self:updateUiElements()
	self.settings:publishNewSettings()
end

function UnloadBalesUI:updateUiElements(skipAutoBindControls)
	if not skipAutoBindControls then
		-- Note: This method is created dynamically by UIHelper.setupAutoBindControls
		self.populateAutoBindControls()
	end

	local isAdmin = g_currentMission:getIsServer() or g_currentMission.isMasterUser
	for _, control in ipairs(self.controls) do
		control:setDisabled(not isAdmin)
	end

	-- Update the focus manager
	local settingsPage = g_gui.screenControllers[InGameMenu].pageSettings
	settingsPage.generalSettingsLayout:invalidateLayout()
end