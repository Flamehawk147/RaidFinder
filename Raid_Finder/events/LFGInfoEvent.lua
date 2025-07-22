-- namespace
local _, ns = ...;

-- imports
local Events = ns.Events
local Player = ns.Player

local EVENT_ID = "LFGInfoEvent"

local LFGInfoEvent = {
    -- the eventId to identify the event type
    eventId = EVENT_ID,
    -- the receiver of the event message
    receiver,
    -- the player info
    player,
    -- if the event should trigger a response
    response
}
LFGInfoEvent.__index = LFGInfoEvent
ns.LFGInfoEvent = LFGInfoEvent

function LFGInfoEvent.new(receiver, player, response)
    local self = setmetatable({}, LFGInfoEvent)
    self.receiver = receiver
    self.player = player
    self.response = response or false
    return self
end

function LFGInfoEvent:encode()
    local event = self
    local resp
    if (event.response) then
        resp = "1"
    else
        resp = "0"
    end
    return resp.."-"..event.player:encode()
end

function LFGInfoEvent.decode(encoded)
    if (encoded) then
        local response, encodedPlayer = strsplit("-", encoded, 2)
        local player = Player.decode(encodedPlayer)
        if (player) then
            return LFGInfoEvent.new(nil , player, response == "1")
        end
    end
end

function LFGInfoEvent.send(receiver, response)
    if (receiver) then
        Events.sent(LFGInfoEvent.new(receiver, ns.DB.player, response))
    end
end

ns.eventHandler[EVENT_ID] = function(message, sender)
    if (message) then
        local event = LFGInfoEvent.decode(message)
        if (event) then
            local player = event.player
            -- filter the players according to our group selection
            if (ns.DB.group:needsPlayer(player)) then
                ns.DB.applicants[sender] = player
                ns.refreshLFMFields()
                
                if (event.response) then
                    ns.LFMInfoEvent.send(sender)
                end
            end
        end
    end
end
