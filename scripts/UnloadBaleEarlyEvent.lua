---This event is sent from the client to the server when an early unload is requested by a client
---@class UnloadBaleEarlyEvent
---@field baler Baler @The baler to be unloaded
UnloadBaleEarlyEvent = {}
local UnloadBaleEarlyEvent_mt = Class(UnloadBaleEarlyEvent, Event)

InitEventClass(UnloadBaleEarlyEvent, "UnloadBaleEarlyEvent")

---Creates a new empty event
---@return table @The new instance
function UnloadBaleEarlyEvent.emptyNew()
	return Event.new(UnloadBaleEarlyEvent_mt)
end

---Creates a new event
---@param baler Baler @The baler to be unloaded
---@return table @The new instance
function UnloadBaleEarlyEvent.new(baler)
	local self = UnloadBaleEarlyEvent.emptyNew()
	self.baler = baler
	return self
end

local debugMp = false
local function dbgPrintMp(text)
	if debugMp then
		print(MOD_NAME .. ": " .. text)
	end
end

---This will be executed on the server if a client sends an UnloadBaleEarly Event
---@param streamId any @The ID of the stream to read from.
---@param connection any @The connection which sent the event.
function UnloadBaleEarlyEvent:readStream(streamId, connection)
	dbgPrintMp("Receiving UnloadBaleEarlyEvent")
	if not connection:getIsServer() then
		dbgPrintMp("Running UnloadBaleEarlyEvent")
		-- We are the server: Act as if the event was triggered on the server, this should trigger all necessary client actions on the way
		self.baler = NetworkUtil.readNodeObject(streamId)
		self.baler:handleUnloadingBaleEvent()
		dbgPrintMp("Done running UnloadBaleEarlyEvent")
	else
		Logging.error("%s: UnloadBaleEarlyEvent is a client-to-server-only event.", MOD_NAME)
	end
	dbgPrintMp("Done receiving UnloadBaleEarlyEvent")
end

---Asks the server to trigger an early unload for the baler stored in the event.
---@param streamId any @The stream ID.
---@param connection any @The connection to use.
function UnloadBaleEarlyEvent:writeStream(streamId, connection)
	dbgPrintMp("Sending UnloadBaleEarlyEvent")
	if connection:getIsServer() then
		-- Connected to a server: Tell the server which baler to unload
		NetworkUtil.writeNodeObject(streamId, self.baler)
	else
		Logging.error("%s: UnloadBaleEarlyEvent is a client-to-server-only event.", MOD_NAME)
	end
	dbgPrintMp("Done sending UnloadBaleEarlyEvent")
end