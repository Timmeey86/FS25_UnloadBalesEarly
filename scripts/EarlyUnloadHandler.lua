---This class is responsible for allowing the player to unload bales early
---The logic for doing that is already in the game, we just have to enable it and do some calls to make sure the physics work properly
---for balers which weren't intended to have that functionality.
---@class EarlyUnloadHandler
---@field overrideFillLevel number @If this value is greater than zero during Baler.createBale, the bale's amount of liters will be overwritten with this value
---@field settings UnloadBalesSettings @The settings object
EarlyUnloadHandler = {}
local EarlyUnloadHandler_mt = Class(EarlyUnloadHandler)

---Creates a new instance
---@return table @The new instance
function EarlyUnloadHandler.new(settings)
	local self = setmetatable({}, EarlyUnloadHandler_mt)
	self.overrideFillLevel = -1
	self.settings = settings
	return self
end

local traceCalls = false
local function traceMethod(methodName)
	if traceCalls then
		print(MOD_NAME .. ": " .. methodName)
	end
end

---Allows unloading unfinished bales on all balers on load, independent of their XML settings
---@param baler table @The baler which is being loaded
---@param superFunc function @The base game implementation
---@param savegame table @The save game object
function EarlyUnloadHandler.onBalerLoad(baler, superFunc, savegame)
	traceMethod("onBalerLoad")
	local spec = baler.spec_baler

	-- Execute base game behavior first
	superFunc(baler, savegame)

	-- Allow unloading bales early for every single baler
	print(("%s: Forcing early unload possibility for %s %s '%s'"):format(MOD_NAME, baler.typeName, baler.brand.title, baler.configFileNameClean))
	spec.canUnloadUnfinishedBale = true

	-- Remember the original threshold at which overloading is supposed to start for two-chamber balers
	if spec.buffer and spec.buffer.overloadingStartFillLevelPct then
		spec.originalOverloadPct = spec.buffer.overloadingStartFillLevelPct
	else
		spec.originalOverloadPct = 1
	end
	spec.overloadingThresholdIsOverridden = false
end

---Scales the bale to the maximum bale size and sets the given fill level
---Note that the fill level will usually be the maximum at this point, and will be overridden by the server later on
---@param baler Baler @The baler which will be unloaded shortly after
---@param fillLevel number @The fill level to be set
function EarlyUnloadHandler.scaleBaleToMax(baler, fillLevel)
	local spec = baler.spec_baler
	baler:updateDummyBale(spec.dummyBale, spec.fillTypeIndex, fillLevel, fillLevel)
	baler:setAnimationTime(spec.baleTypes[spec.currentBaleTypeIndex].animations.fill, 1)
	if g_server then
		-- If we are a server, inform all clients about the bale size change. Will do nothing if no client is connected
		g_server:broadcastEvent(OverrideBaleSizeEvent.new(baler, fillLevel), nil, connection, nil)
	end
end

---Unloads the bale after the player pressed the hotkey
---@param baler table @The baler instance
---@param superFunc function @The base game implementation
function EarlyUnloadHandler:onHandleUnloadingBaleEvent(baler, superFunc)
	traceMethod("onHandleUnloadingBaleEvent")
	local spec = baler.spec_baler
	if spec.unloadingState == Baler.UNLOADING_CLOSED and #spec.bales == 0 and baler:getCanUnloadUnfinishedBale() then
		traceMethod("onHandleUnloadingBaleEvent/create bale")
		-- Remember the current fill level of the baler
		self.overrideFillLevel = baler:getFillUnitFillLevel(spec.fillUnitIndex)
		-- Set the bale to max fill level so the physics doesn't bug out when unloading. This will also cause clients to update their bale sizes
		local maxFillLevel = baler:getFillUnitCapacity(spec.fillUnitIndex)
		EarlyUnloadHandler.scaleBaleToMax(baler, maxFillLevel)
		-- Finish the bale, which will override the fill level
		baler:finishBale()
	end

	-- Now that we made sure a bale was created if necessary, call the base game behavior
	traceMethod("onHandleUnloadingBaleEvent/superFunc")
	superFunc(baler)
end

---Causes the baler to automatically start overloading its first chamber into its second one
---@param baler Baler @The baler
function EarlyUnloadHandler.startOverloading(baler)
	traceMethod("startOverloading")
	--Two-chamber vehicles: Reduce the overloading percentage so the baler starts unloading
	local spec = baler.spec_baler
	if UnloadBalesEarly.settings.overloadingThreshold then
		spec.buffer.overloadingStartFillLevelPct = UnloadBalesEarly.settings.overloadingThreshold / 100
		spec.overloadingThresholdIsOverridden = true
	end
end

---Intercepts the action call in order to start overloading if necessary. 
---@param baler table @The baler instace
---@param superFunc function @The base game implementation
function EarlyUnloadHandler:onActionEventUnloading(baler, superFunc, ...)
	traceMethod("onActionEventUnloading")
	if EarlyUnloadHandler.getCanOverloadBuffer(baler) then
		traceMethod("onActionEventUnloading/can overload")
		if g_server == nil then
			-- Ask the server to trigger an overload
			g_client:getServerConnection():sendEvent(OverloadChamberEarlyEvent.new(baler))
		else
			-- Single player and multiplayer host: Overload directly
			EarlyUnloadHandler.startOverloading(baler)
		end
		-- Do not call super func since we wanted the overload rather than the unload
	elseif g_server == nil and baler:getCanUnloadUnfinishedBale() then
		traceMethod("onActionEventUnloading/can unload as a client")
		local spec = baler.spec_baler
		if spec.unloadingState == Baler.UNLOADING_CLOSED and #spec.bales == 0 then
			-- override the fill level so the bale gets 
			self.overrideFillLevel = baler:getFillUnitFillLevel(spec.fillUnitIndex)
			-- Set the bale to max fill level so the physics doesn't bug out when unloading
			local maxFillLevel = baler:getFillUnitCapacity(spec.fillUnitIndex)
			baler:updateDummyBale(spec.dummyBale, spec.fillTypeIndex, maxFillLevel, maxFillLevel)
			baler:setAnimationTime(spec.baleTypes[spec.currentBaleTypeIndex].animations.fill, 1)
			-- Ask the server to trigger an early unload.
			g_client:getServerConnection():sendEvent(UnloadBaleEarlyEvent.new(baler))
			-- Do not call super func. The server will make sure the necessary functions get called on the clients
		else
			superFunc(baler, ...)
		end
	else
		traceMethod("onActionEventUnloading/can not overload")
		-- Forward the event through base game mechanism in all other cases
		-- In single player or for the hosting player, this could trigger an early unload
		superFunc(baler, ...)
	end
end

---Resets the overloading percentage threshold as soon as the baler has started overloading
---@param baler table  @The baler
---@param ... any @Any other unused parameters
function EarlyUnloadHandler.after_onUpdateTick(baler, ...)
	-- Reset the overloading percentage when unloading has started
	local spec = baler.spec_baler
	if spec.buffer.unloadingStarted and spec.overloadingThresholdIsOverridden then
		traceMethod("after_onUpdateTick/reset overloading threshold")
		spec.buffer.overloadingStartFillLevelPct = spec.originalOverloadPct
		spec.overloadingThresholdIsOverridden = false
	end
end

---Intercepts bale creation and adjusts the overrides the fill level, but only when finishBale() was called from within onHandleUnloadingBaleEvent
---This is done so the bale and bale physics are created for a full sized bale, but then the bale which will be dropped only has the actual amount 
---of liters.
---@param baler table @The baler instance
---@param superFunc function @The base game implementation
---@param baleFillType number @The type of bale (grass, cotton, ...)
---@param fillLevel number @The amount of liters in the bale
---@param baleServerId number @The ID of the bale on the server
---@param baleTime number @Not sure, probably an animation time
---@param xmlFileName string @The name of the XML which contains bale data (when loading)
---@return boolean @True if a valid bale was created
function EarlyUnloadHandler:interceptBaleCreation(baler, superFunc, baleFillType, fillLevel, baleServerId, baleTime, xmlFileName)
	traceMethod("interceptBaleCreation")
	local adjustedFillLevel = fillLevel
	-- Override the fill level when unloading an unfinished bale
	if self.overrideFillLevel >= 0 then
		adjustedFillLevel = self.overrideFillLevel
		-- Reset the override so other bales will not fail
		self.overrideFillLevel = -1
	end
	-- Call the base game behavior with the adjusted fill level
	return superFunc(baler, baleFillType, adjustedFillLevel, baleServerId, baleTime, xmlFileName)
end

local first = true
---Enables or disables our hotkey for unloading bales, dependent on whether or not the threshold was reached
---@param baler table @The baler instance
---@param superFunc function @The base game implementation
function EarlyUnloadHandler.updateActionEvents(baler, superFunc)
	-- Enable base game actions
	superFunc(baler)

	-- Some balers like the Göweil VarioMaster always trigger updateActionEvents even if the player is not inside the baler
	-- This might make sense for base game, so the player can fold the baler while standing next to it, but we don't want this behavior for our own actions
	local currentPlayerVehicle = g_localPlayer and g_localPlayer:getCurrentVehicle()
	local balerRootVehicle = baler:findRootVehicle()
	if currentPlayerVehicle ~= balerRootVehicle then
		traceMethod(("updateActionEvents/ignore baler %s"):format(baler.configFileName))
		return
	end

	-- Enable the unload early option when necessary
	local spec = baler.spec_baler
	local showAction = false
	if UnloadBalesEarly.settings.overloadingThreshold and EarlyUnloadHandler.getCanOverloadBuffer(baler) then
		-- Two-chamber balers like the JD Cotton Harvester or the modded Fendt Rotana 180 Xtra-V:
		-- Use the same action which will just trigger a different mechanism
		if spec.unloadingState == Baler.UNLOADING_CLOSED and not spec.platformReadyToDrop then
			g_inputBinding:setActionEventText(baler.unloadBaleActionEventId, g_i18n:getText("ub_overload_early"))
			showAction = true
		else
			traceMethod(("udpateActionEvents/unloadingState = %d, not platformReadyToDrop = %s"):format(spec.unloadingState, not spec.platformReadyToDrop))
		end
	end
	if UnloadBalesEarly.settings.unloadingThreshold and not showAction and baler:isUnloadingAllowed() and (spec.hasUnloadingAnimation or spec.allowsBaleUnloading) then
		-- Any other baler really
		if spec.unloadingState == Baler.UNLOADING_CLOSED then
			if baler:getCanUnloadUnfinishedBale() and not spec.platformReadyToDrop then
				g_inputBinding:setActionEventText(baler.unloadBaleActionEventId, g_i18n:getText("input_UNLOAD_BALE_EARLY"))
				showAction = true
				traceMethod("updateActionEvents/canUnload")
			else
				traceMethod(("updateActionEvents/canUnloadUnfinishedBale = %s, not platformReadyToDrop = %s"):format(baler:getCanUnloadUnfinishedBale(), not spec.platformReadyToDrop))
			end
		else
			traceMethod(("updateActionEvents/unloadingState = %d"):format(spec.unloadingState))
		end
	elseif not showAction then
		traceMethod(("updateActionEvents/isUnloadingAllowed = %s, hasUnloadingAnimation = %s, allowsBaleUnloading = %s"):format(baler:isUnloadingAllowed(), spec.hasUnloadingAnimation, spec.allowsBaleUnloading))
	end
	g_inputBinding:setActionEventActive(baler.unloadBaleActionEventId, showAction)
	if showAction then
		traceMethod("updateActionEvents/action is enabled")
	else
		traceMethod("updateActionEvents/action is disabled")
	end
end

---Registers the action for unloading early when necessary
---@param baler table @The baler instance
---@param superFunc function @The base game implementation
---@param isActiveForInput boolean @True if the baler is the currently selected implement
---@param isActiveForInputIgnoreSelection boolean @True if the player is in a tractor which is connected to the baler
function EarlyUnloadHandler.onRegisterActionEvents(baler, superFunc, isActiveForInput, isActiveForInputIgnoreSelection)
	-- Create the base game actions first - this will clear the event list
	superFunc(baler, isActiveForInput, isActiveForInputIgnoreSelection)

	local spec = baler.spec_baler
	if baler.isClient and isActiveForInputIgnoreSelection then
		-- Add an "unload unfinished bale" function
		local isValid, actionEventId = baler:addPoweredActionEvent(spec.actionEvents, 'UNLOAD_BALE_EARLY', baler, Baler.actionEventUnloading, false, true, false, true, nil)
		if isValid then
			g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_HIGH)
			g_inputBinding:setActionEventActive(false)
			baler.unloadBaleActionEventId = actionEventId
		else
			Logging.warning("%s: Failed registering the action event for unloading early. Another action might be bound to the same key.", MOD_NAME)
		end
	end

	-- Upade action events again to include our new option
	Baler.updateActionEvents(baler)
end

---Checks whether or not unfinished bales can be unloaded
---@param baler table @The baler instance
---@param superFunc function @The base game implementation
---@return boolean @True if the baler can unload right now
function EarlyUnloadHandler.getCanUnloadUnfinishedBale(baler, superFunc)
	-- Adjust the threshold now. This will also adjust it for functions which don't use the getter
	local spec = baler.spec_baler
	if UnloadBalesEarly.settings.unloadingThreshold then
		-- A custom threshold was configured, get the threshold as a float value
		spec.unfinishedBaleThreshold = EarlyUnloadHandler.getUnloadBaleThreshold(baler, 1)
	-- else: Keep default threshold
	end
	traceMethod(("getCanUnloadUnfinishedBale/fillLevel = %s, threshold = %s"):format(baler:getFillUnitFillLevel(spec.fillUnitIndex), spec.unfinishedBaleThreshold))
	-- Return the base game implementation now that we adjusted the threshold
	return superFunc(baler)
end

---Checks whether or not the buffer can be overloaded into the bale chamber for two-chamber balers.
---When the threshold is set to 0%, overloading will still require at least one liter as otherwise the option to unload would never show up
---@param baler table @The baler instance
---@return boolean @True if overloading is possible right now
function EarlyUnloadHandler.getCanOverloadBuffer(baler)
	local spec = baler.spec_baler
	-- Do not offer the option to overload if it's not a two chamber baler
	if spec.buffer.fillUnitIndex ~= 2 then
		return false
	end
	-- Göweil DLC (and maybe others): Do not offer the option if the baler always automatically overloads
	if spec.originalOverloadPct == 0 then
		return false
	end
	local requiredLiters = math.max(1, EarlyUnloadHandler.getOverloadBaleThreshold(baler, 2))
	return baler:getIsTurnedOn() and baler.spec_fillUnit.fillUnits[2].fillLevel >= requiredLiters
end

---Calculates the threshold for unloading bales for the given fill unit index
---@param baler table @The baler to be updated
---@param fillUnitIndex integer @The index of the relevant fill unit (the bale chamber)
function EarlyUnloadHandler.getUnloadBaleThreshold(baler, fillUnitIndex)
	local factor = 1
	if UnloadBalesEarly.settings.unloadingThreshold then
		factor = UnloadBalesEarly.settings.unloadingThreshold / 100
	end
	return baler:getFillUnitCapacity(fillUnitIndex) * factor
end

---Calculates the threshold for overloading from the given fill unit index to a different chamber
---@param baler table @The baler to be updated
---@param fillUnitIndex integer @The index of the relevant fill unit (the buffer chamber)
function EarlyUnloadHandler.getOverloadBaleThreshold(baler, fillUnitIndex)
	local factor = 1
	if UnloadBalesEarly.settings.overloadingThreshold then
		factor = UnloadBalesEarly.settings.overloadingThreshold / 100
	end
	return baler:getFillUnitCapacity(fillUnitIndex) * factor
end