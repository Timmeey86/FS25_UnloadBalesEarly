---This class stores settings for the UnloadBalesEarly mod
---@class UnloadBalesSettings
---@field enableOverloading boolean @Enables or disables the overloading functionality
---@field enableUnloading boolean @Enables or disables the unloading functionality
---@field overloadingThreshold number|nil @The minimum percentage for overloading
---@field unloadingThreshold number|nil @The minimum percentage for unloading
UnloadBalesSettings = {
}
local UnloadBalesSettings_mt = Class(UnloadBalesSettings)

---Creates a new settings instance
---@return table @The new instance
function UnloadBalesSettings.new()
	local self = setmetatable({}, UnloadBalesSettings_mt)
	self.enableOverloading = true
	self.enableUnloading = true
	self.overloadingThreshold = 0
	self.unloadingThreshold = 0
	return self
end

---Publishes new settings in case of multiplayer
function UnloadBalesSettings:publishNewSettings()
	if g_server ~= nil then
		-- Broadcast to other clients, if any are connected
		g_server:broadcastEvent(UnloadBalesSettingsChangeEvent.new(self))
	else
		-- Ask the server to broadcast the event
		g_client:getServerConnection():sendEvent(UnloadBalesSettingsChangeEvent.new(self))
	end
end

---Recevies the initial settings from the server when joining a multiplayer game
---@param streamId any @The ID of the stream to read from
---@param connection any @Unused
function UnloadBalesSettings:onReadStream(streamId, connection)
	print(MOD_NAME .. ": Receiving new settings")
	self.enableOverloading = streamReadBool(streamId)
	self.enableUnloading = streamReadBool(streamId)
	self.overloadingThreshold = streamReadInt16(streamId)
	self.unloadingThreshold = streamReadInt16(streamId)
	print(MOD_NAME .. ": Done receiving new settings")
end

---Sends the current settings to a client which is connecting to a multiplayer game
---@param streamId any @The ID of the stream to write to
---@param connection any @Unused
function UnloadBalesSettings:onWriteStream(streamId, connection)
	print(MOD_NAME .. ": Sending new settings")
	streamWriteBool(streamId, self.enableOverloading)
	streamWriteBool(streamId, self.enableUnloading)
	streamWriteInt16(streamId, self.overloadingThreshold)
	streamWriteInt16(streamId, self.unloadingThreshold)
	print(MOD_NAME .. ": Done sending new settings")
end