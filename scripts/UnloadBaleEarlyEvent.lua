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

---Reads settings which were sent by another network participant and then applies them locally
---@param streamId any @The ID of the stream to read from.
---@param connection any @The connection which sent the event.
function UnloadBaleEarlyEvent:readStream(streamId, connection)
    print(MOD_NAME .. ": Receiving UnloadBaleEarlyEvent")
    if not connection:getIsServer() then
        print(MOD_NAME .. ": Running UnloadBaleEarlyEvent")
        -- We are the server: Act as if the event was triggered on the server, this should trigger all necessary client actions on the way
        self.baler = NetworkUtil.readNodeObject(streamId)
        self.baler:handleUnloadingBaleEvent()
        print(MOD_NAME .. ": Done running UnloadBaleEarlyEvent")
    else
        Logging.error("%s: UnloadBaleEarlyEvent is a client-to-server-only event.", MOD_NAME)
    end
    print(MOD_NAME .. ": Done receiving UnloadBaleEarlyEvent")
end

---Sends event data, in this case exclusively from the client to the server
---@param streamId any @The stream ID.
---@param connection any @The connection to use.
function UnloadBaleEarlyEvent:writeStream(streamId, connection)
    print(MOD_NAME .. ": Sending UnloadBaleEarlyEvent")
    if connection:getIsServer() then
        -- Connected to a server: Tell the server which baler to unload
        NetworkUtil.writeNodeObject(streamId, self.baler)
    else
        Logging.error("%s: UnloadBaleEarlyEvent is a client-to-server-only event.", MOD_NAME)
    end
    print(MOD_NAME .. ": Done sending UnloadBaleEarlyEvent")
end