---This event is sent from the client to the server when an early unload is requested by a client
---@class OverloadChamberEarlyEvent
---@field baler Baler @The baler to be overloaded
OverloadChamberEarlyEvent = {}
local OverloadChamberEarlyEvent_mt = Class(OverloadChamberEarlyEvent, Event)

InitEventClass(OverloadChamberEarlyEvent, "OverloadChamberEarlyEvent")

---Creates a new empty event
---@return table @The new instance
function OverloadChamberEarlyEvent.emptyNew()
	return Event.new(OverloadChamberEarlyEvent_mt)
end

---Creates a new event
---@param baler Baler @The baler to be overloaded
---@return table @The new instance
function OverloadChamberEarlyEvent.new(baler)
	local self = OverloadChamberEarlyEvent.emptyNew()
	self.baler = baler
	return self
end

local debugMp = false
local function dbgPrintMp(text)
	if debugMp then
		print(MOD_NAME .. ": " .. text)
	end
end

---This will be executed on the server if a client sends an OverloadChamberEarlyEvent Event
---@param streamId any @The ID of the stream to read from.
---@param connection any @The connection which sent the event.
function OverloadChamberEarlyEvent:readStream(streamId, connection)
	dbgPrintMp("Receiving OverloadChamberEarlyEvent")
	if not connection:getIsServer() then
		dbgPrintMp("Running OverloadChamberEarlyEvent")
		-- We are the server: Act as if the event was triggered on the server, this should trigger all necessary client actions on the way
		self.baler = NetworkUtil.readNodeObject(streamId)
		EarlyUnloadHandler.startOverloading(self.baler)
		dbgPrintMp("Done running OverloadChamberEarlyEvent")
	else
		Logging.error("%s: OverloadChamberEarlyEvent is a client-to-server-only event.", MOD_NAME)
	end
	dbgPrintMp("Done receiving OverloadChamberEarlyEvent")
end

---Asks the server to trigger an early overload for the baler stored in the event.
---@param streamId any @The stream ID.
---@param connection any @The connection to use.
function OverloadChamberEarlyEvent:writeStream(streamId, connection)
	dbgPrintMp("Sending OverloadChamberEarlyEvent")
	if connection:getIsServer() then
		-- Connected to a server: Tell the server which baler to unload
		NetworkUtil.writeNodeObject(streamId, self.baler)
	else
		Logging.error("%s: OverloadChamberEarlyEvent is a client-to-server-only event.", MOD_NAME)
	end
	dbgPrintMp("Done sending OverloadChamberEarlyEvent")
end