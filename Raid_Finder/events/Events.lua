-- namespace
local _, ns = ...;
-- imports
local AddonMessage = ns.AddonMessage

-- the addon message prefix - not the event prefix
local EVENT_MESSAGE = "RF_EVENT_MSG"

---
-- Contains utility methods to send and receive event messages.
-- 
local Events = {}
ns.Events = Events

---
-- Sends the given event.
-- 
-- @param #Event event
--          the event to be sent
-- 
Events.sent = function(event)
    local message = event:encode()
    AddonMessage.Send(EVENT_MESSAGE, event.eventId.."#"..message, "WHISPER", event.receiver)
end

-- the event handlers that will be called to handle the event message
ns.eventHandler = {}

-- the event frame where the event is registered to
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("CHAT_MSG_ADDON")
-- Register addon message prefix for WotLK compatibility
local function RegisterAddonMessagePrefix(prefix)
    if RegisterAddonMessagePrefix then
        RegisterAddonMessagePrefix(prefix)
    elseif C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then
        C_ChatInfo.RegisterAddonMessagePrefix(prefix)
    end
end
RegisterAddonMessagePrefix(EVENT_MESSAGE)
eventFrame:SetScript("OnEvent", function(frame, event, arg1, arg2, arg3, arg4)
    if (event == "CHAT_MSG_ADDON" and arg1 == EVENT_MESSAGE) then
        AddonMessage.Receive(arg1, arg2, arg3, arg4, function(prefix, message, type, sender)
            -- remove realm suffix
            sender = strsplit("-", sender, 2)
            if (sender and message) then
                prefix, message = strsplit("#", message, 2)
                local handler = ns.eventHandler[prefix]
                if (handler and message) then
                    handler(message, sender)
                end
            end
        end)
    end
end)