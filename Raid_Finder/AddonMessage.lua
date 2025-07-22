-- namespace
local _, ns = ...;

---
-- The AddonMessage contains methods to send and receive messages between
-- addons. Since the game client has some limitations concerning the amount of
-- messages and their size, special care has to be taken when sending data via
-- the default API SendAddonMessage(). The methods of this class are supposed
-- to throttle the amount of messages sent within a certain time frame and also
-- to get rid of the message size limit.
-- 
-- In order to send a message, simply call the Send function.
-- To receive a message, one must register the event type using
-- frame:RegisterEvent("CHAT_MSG_ADDON"), but also the expected message prefix
-- via C_ChatInfo.RegisterAddonMessagePrefix(prefix).
-- 
local AddonMessage = {}
AddonMessage.__index = AddonMessage
ns.AddonMessage = AddonMessage

local messageId = 0
local messages = {}

---
-- Sends the given message text to a hidden addon channel.
-- 
-- The prefix is used to filter messages. The receiver must have this prefix
-- registered via C_ChatInfo.RegisterAddonMessagePrefix(prefix) in order to
-- receive the message.
-- 
-- Valid types are "PARTY", "RAID", "GUILD", "OFFICER", "BATTLEGROUND" and
-- "WHISPER".
-- 
-- @param #string prefix
--          message prefix, which serves as an identifier for the addon
-- @param #string text
--          the message to be sent
-- @param #string type
--          the addon channel to sent to
-- @param #string target
--          the receiver in case of type WHISPER
--  
function AddonMessage.Send(prefix, text, type, target)
    -- increment the messageId
    messageId = messageId + 1
    if (messageId > 9999) then messageId = 0 end

    local message = text
    local packets = {}

    while message do
        local part
        if (strlen(message) > 245) then
            part = strsub(message, 1, 240)
            message = strsub(message, 241)
        else
            part = message
            message = nil
        end
        local packet = messageId.."#"..part
        table.insert(packets, packet)
    end
    -- terminal packet
    table.insert(packets, messageId.."#")

    -- send each packet
    for i, packet in ipairs(packets) do
        ChatThrottleLib:SendAddonMessage("NORMAL", prefix, packet, type, target)
    end
end

---
-- This method has to be called whenever an addon message was received. One
-- must register the event type using frame:RegisterEvent("CHAT_MSG_ADDON"),
-- but also the expected message prefix via
-- C_ChatInfo.RegisterAddonMessagePrefix(prefix) in order to receive messages.
-- To handle the message, an action function can be passed to this method that
-- will be called with the complete message text when the message was fully
-- processed, thus all parts arrived.
-- 
-- @param #string prefix
--          the message prefix
-- @param #string text
--          the message text that was received
-- @param #string type
--          the type of addon channel where this message was received
-- @param #string sender
--          the sender of the message
-- @param #function action
--          the action that will be called with all arguments but with the full
--          message when all parts did arrive          
-- 
function AddonMessage.Receive(prefix, text, type, sender, action)
    local messageId, part = strsplit("#", text, 2)
    if (messageId) then
        if ((not part) or strlen(part) == 0) then
            -- the terminal packet
            local message = messages[messageId]
            if (message) then
                messages[messageId] = nil -- clear the message
                action(prefix, message, type, sender)
            end
        else
            -- append the message
            local message = messages[messageId] or ""
            message = message..part
            messages[messageId] = message
        end
    end
end
