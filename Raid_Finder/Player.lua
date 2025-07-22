-- namespace
local _, ns = ...;
-- imports
local utils = ns.utils

local Player = {
    name,
    -- the class of the player
    class,
    -- the level of the player
    level,
    -- the roles that the player has selected
    roles,
    -- the dungeons the player is looking for a group
    dungeons
}
Player.__index = Player
ns.Player = Player

function Player.of(playerInfo)
    return setmetatable(playerInfo, Player)
end

function Player.new(name, class, level, roles, dungeons)
    local self = setmetatable({}, Player)
    self.name = name
    self.class = class
    self.level = level
    self.roles = roles or {}
    self.dungeons = dungeons or {}
    return self
end

-- TODO the roles needs to be saved
function Player.current()
    local name = UnitName("player")
    local _, class = UnitClass("player")
    local level = UnitLevel("player")
    return Player.new(name, class, level)
end

function Player:isLookingForDungeon(dungeon)
    if (dungeon) then
        local player = self
        return self.dungeons[dungeon.name]
    end
end

function Player:setLookingForDungeon(dungeon, enabled)
    if (dungeon) then
        local player = self    
        if (enabled) then
            player.dungeons[dungeon.name] = true
        else
            player.dungeons[dungeon.name] = nil
        end
    end
end

function Player:clearLookingForDungeon()
    local player = self
    player.dungeons = {}
end

function Player:hasRole(role)
    if (role) then
        local player = self
        return player.roles[role]
    end
end

function Player:setRole(role, enabled)
    if (role) then
        local player = self
        if (enabled) then
            player.roles[role] = true
        else
            player.roles[role] = nil
        end
    end
end

function Player:isLFGReady()
    local player = self
    local hasRole, hasDungeon
    for _ in pairs(player.roles) do
        hasRole = true
        break
    end
    for _ in pairs(player.dungeons) do
        hasDungeon = true
        break
    end
    return (hasRole and hasDungeon)
end

function Player:encode()
    local player = self
    
    local roles = utils.toCSV(player.roles, function(k,v) return k end)
    local dungeons = utils.toCSV(player.dungeons, function(k,v) return k end)
    
    -- update level
    player.level = UnitLevel("player")
    local list = {
        player.name,
        player.class,
        tostring(player.level),
        roles,
        dungeons
    }
    return utils.toCSV(list, function(k, v) return v end, ";")
end

function Player.decode(encoded)
    if (encoded) then
        
        local list = utils.fromCSV(encoded, function(list, element)
            table.insert(list, element)
        end, ";")
        
        local name = list[1]
        local class = list[2]
        local level = tonumber(list[3])
        local roles = list[4]
        local dungeons = list[5]
        
        -- decode the roles and dungeons
        roles = utils.fromCSV(roles, function(list, element)
            list[element] = true
        end)
        dungeons = utils.fromCSV(dungeons, function(list, element)
            list[element] = true
        end)
        
        return Player.new(name, class, level, roles, dungeons)
    end
end
