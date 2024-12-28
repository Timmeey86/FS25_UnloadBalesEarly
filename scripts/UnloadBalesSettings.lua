---This class stores settings for the UnloadBalesEarly mod
---@class UnloadBalesSettings
---@field overloadingThreshold number|nil @The minimum percentage for overloading
---@field unloadingThreshold number|nil @The minimum percentage for unloading
UnloadBalesSettings = {
}
local UnloadBalesSettings_mt = Class(UnloadBalesSettings)

---Creates a new settings instance
---@return table @The new instance
function UnloadBalesSettings.new()
	local self = setmetatable({}, UnloadBalesSettings_mt)
	self.overloadingThreshold = 0
	self.unloadingThreshold = 0
	self:initializeMultiplayerListeners()
	return self
end

---Sets up initial distribution of settings for when a player connects. This will have no effect in single player.
function UnloadBalesSettings:initializeMultiplayerListeners()
	-- Write the settings on server side when a new player connects
	Player.writeStream = Utils.appendedFunction(Player.writeStream, function(player, streamId, connection)
		self:onWriteStream(streamId, connection)
	end)

	-- Read the settings on client side when connecting to a server
	Player.readStream = Utils.appendedFunction(Player.readStream, function(player, streamId, connection)
		self:onReadStream(streamId, connection)
	end)
end

---Publishes new settings in case of multiplayer
function UnloadBalesSettings:publishNewSettings()
	if g_server ~= nil then
		-- Broadcast to other clients, if any are connected
		g_server:broadcastEvent(UnloadBalesSettingsChangeEvent.new())
	else
		-- Ask the server to broadcast the event
		g_client:getServerConnection():sendEvent(UnloadBalesSettingsChangeEvent.new())
	end
end

---Recevies the initial settings from the server when joining a multiplayer game
---@param streamId any @The ID of the stream to read from
---@param connection any @Unused
function UnloadBalesSettings:onReadStream(streamId, connection)
	print(MOD_NAME .. ": Receiving new settings")
	if streamReadBool(streamId) then
		self.overloadingThreshold = streamReadInt16(streamId)
	else
		self.overloadingThreshold = nil
	end
	if streamReadBool(streamId) then
		self.unloadingThreshold = streamReadInt16(streamId)
	else
		self.unloadingThreshold = nil
	end
	print(MOD_NAME .. ": Done receiving new settings")
end

---Sends the current settings to a client which is connecting to a multiplayer game
---@param streamId any @The ID of the stream to write to
---@param connection any @Unused
function UnloadBalesSettings:onWriteStream(streamId, connection)
	print(MOD_NAME .. ": Sending new settings")
	if streamWriteBool(streamId, self.overloadingThreshold ~= nil) then
		streamWriteInt16(streamId, self.overloadingThreshold)
	end
	if streamWriteBool(streamId, self.unloadingThreshold ~= nil) then
		streamWriteInt16(streamId, self.unloadingThreshold)
	end
	print(MOD_NAME .. ": Done sending new settings")
end