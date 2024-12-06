---This event is sent between client and server when an admin changes any setting in multiplayer
---It is also sent once when a client joins the server
---@class UnloadBalesSettingsChangeEvent
---@field settings UnloadBalesSettings @The settings to be synchronized
UnloadBalesSettingsChangeEvent = {}
local UnloadBalesSettingsChangeEvent_mt = Class(UnloadBalesSettingsChangeEvent, Event)

InitEventClass(UnloadBalesSettingsChangeEvent, "UnloadBalesSettingsChangeEvent")

---Creates a new empty event
---@return table @The new instance
function UnloadBalesSettingsChangeEvent.emptyNew()
	return Event.new(UnloadBalesSettingsChangeEvent_mt)
end

---Creates a new event
---@param settings UnloadBalesSettings @The settings object
---@return table @The new instance
function UnloadBalesSettingsChangeEvent.new(settings)
	local self = UnloadBalesSettingsChangeEvent.emptyNew()
	self.settings = settings
	return self
end

---Reads settings which were sent by another network participant and then applies them locally
---@param streamId any @The ID of the stream to read from.
---@param connection any @The connection which sent the event.
function UnloadBalesSettingsChangeEvent:readStream(streamId, connection)
	self.settings:onReadStream(streamId, connection)

	local eventWasSentByServer = connection:getIsServer()
	if not eventWasSentByServer then
		print(MOD_NAME .. ": Broadcasting event")
		-- We are the server. Boradcast the event to all other clients (except for the one which sent them)
		g_server:broadcastEvent(UnloadBalesSettingsChangeEvent.new(self.settings), nil, connection, nil)
	else
		print(MOD_NAME .. ": Not broadcasting since we are not the server")
	end
end

---Sends event data to another network participant
---@param streamId any @The stream ID.
---@param connection any @The connection to use.
function UnloadBalesSettingsChangeEvent:writeStream(streamId, connection)
	self.settings:onWriteStream(streamId, connection)
end