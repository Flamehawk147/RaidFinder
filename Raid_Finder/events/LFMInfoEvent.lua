-- namespace
local _, ns = ...;

-- imports
local Events = ns.Events
local Group = ns.Group

local EVENT_ID = "LFMInfoEvent"

local LFMInfoEvent = {
    -- the eventId to identify the event type
    eventId = EVENT_ID,
    -- the receiver of the event message
    receiver,
    -- the group info
    group,
    -- if the event should trigger a response
    response
}
LFMInfoEvent.__index = LFMInfoEvent
ns.LFMInfoEvent = LFMInfoEvent

function LFMInfoEvent.new(receiver, group, response)
    local self = setmetatable({}, LFMInfoEvent)
    self.receiver = receiver
    self.group = group
    self.response = response or false
    return self
end

function LFMInfoEvent:encode()
    local event = self
    local resp
    if (event.response) then
        resp = "1"
    else
        resp = "0"
    end
    return resp.."-"..event.group:encode()
end

function LFMInfoEvent.decode(encoded)
    if (encoded) then
        local response, encodedGroup = strsplit("-", encoded, 2)
        local group = Group.decode(encodedGroup)
        if (group) then
            return LFMInfoEvent.new(nil , group, response == "1")
        end
    end
end

function LFMInfoEvent.send(receiver, response)
    if (receiver) then
        ns.DB.group:updateMembers()
        Events.sent(LFMInfoEvent.new(receiver, ns.DB.group, response))
    end
end

ns.eventHandler[EVENT_ID] = function(message, sender)
    if (message) then
        local event = LFMInfoEvent.decode(message)
        if (event) then
            local group = event.group
            -- filter the message if we actually need it
            if (group:needsPlayer(ns.DB.player)) then
                ns.DB.dungeonGroups[sender] = group
                ns.refeshLFGFields()
                
                if (event.response) then
                    ns.LFGInfoEvent.send(sender)
                end
            end
        end
    end
end
