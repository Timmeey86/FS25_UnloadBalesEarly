local modDirectory = g_currentModDirectory or ""
MOD_NAME = g_currentModName or "unknown"

---@class UnloadBalesEarly
---@field settings UnloadBalesSettings @The settings
UnloadBalesEarly = {}
UnloadBalesEarly.settings = nil
---------------------------
--- Enable early unload ---
---------------------------

-- Create a handler for bale unloading
local earlyUnloadHandler = EarlyUnloadHandler.new()
-- Override methods and inject the instance into the calls so the required variables can be accessed
Baler.handleUnloadingBaleEvent = Utils.overwrittenFunction(Baler.handleUnloadingBaleEvent, function(baler, superFunc)
	earlyUnloadHandler:onHandleUnloadingBaleEvent(baler, superFunc)
end)
Baler.createBale = Utils.overwrittenFunction(Baler.createBale, function(baler, superFunc, baleFillType, fillLevel, baleServerId, baleTime, xmlFileName)
	return earlyUnloadHandler:interceptBaleCreation(baler, superFunc, baleFillType, fillLevel, baleServerId, baleTime, xmlFileName)
end)
Baler.actionEventUnloading = Utils.overwrittenFunction(Baler.actionEventUnloading, function(...) earlyUnloadHandler:onActionEventUnloading(...) end)

-- Override methods which don't require any settings
Baler.onLoad = Utils.overwrittenFunction(Baler.onLoad, EarlyUnloadHandler.onBalerLoad)
Baler.updateActionEvents = Utils.overwrittenFunction(Baler.updateActionEvents, EarlyUnloadHandler.updateActionEvents)
Baler.onRegisterActionEvents = Utils.overwrittenFunction(Baler.onRegisterActionEvents, EarlyUnloadHandler.onRegisterActionEvents)
Baler.getCanUnloadUnfinishedBale = Utils.overwrittenFunction(Baler.getCanUnloadUnfinishedBale, EarlyUnloadHandler.getCanUnloadUnfinishedBale)
Baler.onUpdateTick = Utils.appendedFunction(Baler.onUpdateTick, EarlyUnloadHandler.after_onUpdateTick)

-----------------------
--- Enable settings ---
-----------------------

---Destroys the settings object when it is no longer needed.
local function destroyModSettings()
	if UnloadBalesEarly.settings ~= nil then
		removeModEventListener(UnloadBalesEarly.settings)
		UnloadBalesEarly.settings = nil
	end
end
FSBaseMission.delete = Utils.appendedFunction(FSBaseMission.delete, destroyModSettings)

-- Create default settings for now
UnloadBalesEarly.settings = UnloadBalesSettings.new()
local unloadBalesUi = UnloadBalesUI.new(UnloadBalesEarly.settings)

BaseMission.loadMapFinished = Utils.prependedFunction(BaseMission.loadMapFinished, function(...)
	---Override the default settings with settings from the savegame.
	---This needs to be done after g_currentMission is valid, otherwise the save directory wouldn't be found
	---Note: In multiplayer, this will do nothing on the client
	UnloadBalesSettingsRepository.restoreSettings(UnloadBalesEarly.settings)
	-- Initialize the UI now that the settings are up-to-date
	unloadBalesUi:injectUiSettings()
end)
-- Save settings when the savegame is being saved
ItemSystem.save = Utils.prependedFunction(ItemSystem.save, function()
	UnloadBalesSettingsRepository.storeSettings(UnloadBalesEarly.settings)
end)