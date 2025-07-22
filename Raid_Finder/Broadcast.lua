-- namespace
local _, ns = ...;

---
-- In classic, sending messages to custom channels via "SendAddonMessage"
-- does not work. However, sending normal messages to custom channels can still
-- be done via "SendChatMessage". To ensure a working communication of the addon
-- we will send a broadcast "trigger" to the custom channel and any receiver
-- will then send a "CHAT_MSG_ADDON" whisper to request the status of the
-- LFG/LFM.
---
local Broadcast = {}
ns.Broadcast = Broadcast

local ADDON_CHANNEL= "DungeonFinder"
local CMD_LFM = "!lfm"
local CMD_LFMC = "!lfmc"
local CMD_LFG = "!lfg"
local CMD_LFGC = "!lfgc"

---
-- Sends the given message to the addon channel.
--
-- @param #string msg
--          the message to be sent
--
local function sendChatMessage(msg)
    local channelId = GetChannelName(ADDON_CHANNEL)
    SendChatMessage(msg, "CHANNEL", nil, channelId)
end

Broadcast.lfg = function()
    ns.DB.lfg = true
    ns.DB.dungeonGroups = {}
    sendChatMessage(CMD_LFG)
end

Broadcast.lfgc = function()
    ns.DB.lfg = false
    ns.DB.dungeonGroups = {}
    sendChatMessage(CMD_LFGC)
end

Broadcast.lfm = function()
    ns.DB.lfm = true
    ns.DB.applicants = {}
    ns.DB.group:updateMembers()
    sendChatMessage(CMD_LFM)
end

Broadcast.lfmc = function()
    ns.DB.lfm = false
    ns.DB.applicants = {}
    sendChatMessage(CMD_LFMC)
end

local cmdHandlers = {}
cmdHandlers[CMD_LFG] = function(sender)
    if (ns.DB.lfm) then
        ns.LFMInfoEvent.send(sender, true)
    end
end
cmdHandlers[CMD_LFM] = function(sender)
    if (ns.DB.lfg) then
        ns.LFGInfoEvent.send(sender, true)
    end
end
cmdHandlers[CMD_LFGC] = function(sender)
    if (ns.DB.applicants[sender]) then
        ns.DB.applicants[sender] = nil
        ns.refreshLFMFields()
    end
end
cmdHandlers[CMD_LFMC] = function(sender)
    if (ns.DB.dungeonGroups[sender]) then
        ns.DB.dungeonGroups[sender] = nil
        ns.refeshLFGFields()
    end
end

-- the event frame to receive the addon channel messages
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("CHAT_MSG_CHANNEL")
eventFrame:SetScript("OnEvent", function(frame, event, ...)
    local channel = select(9, ...)
    if (channel == ADDON_CHANNEL) then
        local msg = select(1, ...)
        local handler = cmdHandlers[msg]
        if (handler) then
            -- remove realm suffix
            local sender = select(2, ...)
            sender = strsplit("-", select(2, ...), 2)
            handler(sender)
        end
    end
end)
