local modDirectory = g_currentModDirectory or ""
MOD_NAME = g_currentModName or "unknown"

UnloadBalesEarly = {}

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

-- Override methods which don't require any settings
Baler.onLoad = Utils.overwrittenFunction(Baler.onLoad, EarlyUnloadHandler.onBalerLoad)
Baler.updateActionEvents = Utils.overwrittenFunction(Baler.updateActionEvents, EarlyUnloadHandler.updateActionEvents)
Baler.onRegisterActionEvents = Utils.overwrittenFunction(Baler.onRegisterActionEvents, EarlyUnloadHandler.onRegisterActionEvents)
Baler.getCanUnloadUnfinishedBale = Utils.overwrittenFunction(Baler.getCanUnloadUnfinishedBale, EarlyUnloadHandler.getCanUnloadUnfinishedBale)
Baler.onUpdateTick = Utils.appendedFunction(Baler.onUpdateTick, EarlyUnloadHandler.after_onUpdateTick)
Baler.actionEventUnloading = Utils.overwrittenFunction(Baler.actionEventUnloading, EarlyUnloadHandler.onActionEventUnloading)

-----------------------
--- Enable settings ---
-----------------------

---Creates a settings object which can be accessed from the UI and the rest of the code
---@param   mission     table   @The object which is later available as g_currentMission
local function createModSettings(mission)
	-- Register the settings object globally so we can access it from the event class and others later
    mission.unloadBalesEarlySettings = UnloadBalesSettings.new()
    addModEventListener(mission.unloadBalesEarlySettings)
end
Mission00.load = Utils.prependedFunction(Mission00.load, createModSettings)

---Destroys the settings object when it is no longer needed.
local function destroyModSettings()
    if g_currentMission ~= nil and g_currentMission.unloadBalesEarlySettings ~= nil then
        removeModEventListener(g_currentMission.unloadBalesEarlySettings)
        g_currentMission.unloadBalesEarlySettings = nil
    end
end
FSBaseMission.delete = Utils.appendedFunction(FSBaseMission.delete, destroyModSettings)

---Restore the settings when the map has finished loading
BaseMission.loadMapFinished = Utils.prependedFunction(BaseMission.loadMapFinished, function(...)
	UnloadBalesSettingsRepository.restoreSettings()
end)
-- Save settings when the savegame is being saved
FSBaseMission.saveSavegame = Utils.appendedFunction(FSBaseMission.saveSavegame, UnloadBalesSettingsRepository.storeSettings)


-- MP Debug
Baler.handleUnloadingBaleEvent = Utils.overwrittenFunction(Baler.handleUnloadingBaleEvent, function(baler, superFunc, ...)
    print("Baler.handleUnloadingBaleEvent")
    return superFunc(baler, ...)
end)
BalerSetIsUnloadingBaleEvent.new = Utils.overwrittenFunction(BalerSetIsUnloadingBaleEvent.new, function(arg1, superFunc, ...)
    print"BalerSetIsUnloadingBaleEvent.new"
    return superFunc(arg1, ...)
end)
TraceBalerCreateBaleEvent = {}
function TraceBalerCreateBaleEvent.new(object, superFunc, baleFillType, baleTime, baleServerId)
    print("Creating BalerCreateBaleEvent")
    return superFunc(object, baleFillType, baleTime, baleServerId)
end
BalerCreateBaleEvent.new = Utils.overwrittenFunction(BalerCreateBaleEvent.new, TraceBalerCreateBaleEvent.new)
BalerCreateBaleEvent.readStream = Utils.prependedFunction(BalerCreateBaleEvent.readStream, function() print("Receiving BalerCreateBaleEvent") end)
BalerCreateBaleEvent.readStream = Utils.appendedFunction(BalerCreateBaleEvent.readStream, function() print("Done receiving BalerCreateBaleEvent") end)
BalerCreateBaleEvent.writeStream = Utils.prependedFunction(BalerCreateBaleEvent.writeStream, function() print("Sending BalerCreateBaleEvent") end)
BalerCreateBaleEvent.writeStream = Utils.appendedFunction(BalerCreateBaleEvent.writeStream, function() print("Done sending BalerCreateBaleEvent") end)
BalerCreateBaleEvent.run = Utils.prependedFunction(BalerCreateBaleEvent.run, function() print("Running BalerCreateBaleEvent") end)
BalerCreateBaleEvent.run = Utils.appendedFunction(BalerCreateBaleEvent.run, function() print("Done running BalerCreateBaleEvent") end)

TraceBalerSetIsUnloadingBaleEvent = {}
function TraceBalerSetIsUnloadingBaleEvent.new(object, superFunc, isUnloadingBale)
    print("Creating BalerSetIsUnloadingBaleEvent")
    return superFunc(object, isUnloadingBale)
end
BalerSetIsUnloadingBaleEvent.new = Utils.overwrittenFunction(BalerSetIsUnloadingBaleEvent.new, TraceBalerSetIsUnloadingBaleEvent.new)
BalerSetIsUnloadingBaleEvent.readStream = Utils.prependedFunction(BalerSetIsUnloadingBaleEvent.readStream, function() print("Receiving BalerSetIsUnloadingBaleEvent") end)
BalerSetIsUnloadingBaleEvent.readStream = Utils.appendedFunction(BalerSetIsUnloadingBaleEvent.readStream, function() print("Done receiving BalerSetIsUnloadingBaleEvent") end)
BalerSetIsUnloadingBaleEvent.writeStream = Utils.prependedFunction(BalerSetIsUnloadingBaleEvent.writeStream, function() print("Sending BalerSetIsUnloadingBaleEvent") end)
BalerSetIsUnloadingBaleEvent.writeStream = Utils.appendedFunction(BalerSetIsUnloadingBaleEvent.writeStream, function() print("Done sending BalerSetIsUnloadingBaleEvent") end)
BalerSetIsUnloadingBaleEvent.run = Utils.prependedFunction(BalerSetIsUnloadingBaleEvent.run, function() print("Running BalerSetIsUnloadingBaleEvent") end)
BalerSetIsUnloadingBaleEvent.run = Utils.appendedFunction(BalerSetIsUnloadingBaleEvent.run, function() print("Done running BalerSetIsUnloadingBaleEvent") end)
