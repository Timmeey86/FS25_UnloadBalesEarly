---This event is sent from the serverName to the clients when a bale needs to be adjusted in size due to an early unload
---@class OverrideBaleSizeEvent
---@field baler Baler @The baler to be overloaded
---@field fillLevel number @The fill level to be set
OverrideBaleSizeEvent = {}
local OverrideBaleSizeEvent_mt = Class(OverrideBaleSizeEvent, Event)

InitEventClass(OverrideBaleSizeEvent, "OverrideBaleSizeEvent")

---Creates a new empty event
---@return table @The new instance
function OverrideBaleSizeEvent.emptyNew()
	return Event.new(OverrideBaleSizeEvent_mt)
end

---Creates a new event
---@param baler Baler @The affected baler
---@param fillLevel number @The fill level to be set
---@return OverrideBaleSizeEvent @The new instance
function OverrideBaleSizeEvent.new(baler, fillLevel)
	local self = OverrideBaleSizeEvent.emptyNew()
	self.baler = baler
	self.fillLevel = fillLevel
	return self
end

local debugMp = false
local function dbgPrintMp(text)
	if debugMp then
		print(MOD_NAME .. ": " .. text)
	end
end

---This will be executed on the clients if a server sends an OverrideBaleSizeEvent Event
---@param streamId any @The ID of the stream to read from.
---@param connection any @The connection which sent the event.
function OverrideBaleSizeEvent:readStream(streamId, connection)
	dbgPrintMp("Receiving OverrideBaleSizeEvent")
	if connection:getIsServer() then
		dbgPrintMp("Running OverrideBaleSizeEvent")
		self.baler = NetworkUtil.readNodeObject(streamId)
		self.fillLevel = streamReadFloat32(streamId)
		-- We are a client => Execute the same code as the server
		EarlyUnloadHandler.scaleBaleToMax(self.baler, self.fillLevel)
		dbgPrintMp("Done running OverrideBaleSizeEvent")
	else
		Logging.error("%s: OverrideBaleSizeEvent is a server-to-client-only event.", MOD_NAME)
	end
	dbgPrintMp("Done receiving OverrideBaleSizeEvent")
end

---Asks the server to trigger an early overload for the baler stored in the event.
---@param streamId any @The stream ID.
---@param connection any @The connection to use.
function OverrideBaleSizeEvent:writeStream(streamId, connection)
	dbgPrintMp("Sending OverrideBaleSizeEvent")
	if not connection:getIsServer() then
		-- Connected to a server: Tell the server which baler shall be affected
		NetworkUtil.writeNodeObject(streamId, self.baler)
		streamWriteFloat32(streamId, self.fillLevel)
	else
		Logging.error("%s: OverrideBaleSizeEvent is a server-to-client-only event.", MOD_NAME)
	end
	dbgPrintMp("Done sending OverrideBaleSizeEvent")
end