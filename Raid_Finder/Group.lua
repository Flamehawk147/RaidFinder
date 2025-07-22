-- namespace
local _, ns = ...;
-- imports
local utils = ns.utils

local Group = {
    name,
    dungeon,
    -- a set of roles that are searched for the group
    roles,
    -- a set of classes that are searched for the group
    classes,
    created,
    comment,
    leader,
    -- map class - count
    members
}
Group.__index = Group
ns.Group = Group

function Group.of(groupInfo)
    return setmetatable(groupInfo, Group)
end

function Group.new(name, dungeon, roles, classes, created, comment, leader, members)
    local self = setmetatable({}, Group)
    self.name = name or ""
    self.dungeon = dungeon or ""
    self.roles = roles or {}
    self.classes = classes or {}
    self.created = created or time()
    self.comment = comment or ""
    self.leader = leader or UnitName("player")
    self.members = members or {}
    return self
end

function Group:needsPlayer(player)
    local group = self
    -- check that the player has the correct role
    local hasRole = false
    for role in pairs(group.roles) do
        if (player.roles[role]) then
            hasRole = true
            break;
        end
    end
    if (not hasRole) then return false end
    
    -- check that the player has the correct class
    if (not group.classes[player.class]) then return false end
    
    -- check that the player is looking for the dungeon
    if (not player.dungeons[group.dungeon]) then return false end
    
    return true
end

function Group:updateMembers()
    local group = self
    local members = {}
    utils.forEachRaidMember(function(name, rank, level, class)
        local count = members[class] or 0
        count = count + 1
        members[class] = count
    end)
    group.members = members
end

function Group:encode()
    local group = self
    local roles = utils.toCSV(group.roles, function(k,v) return k end)
    local classes = utils.toCSV(group.classes, function(k,v) return k end)
    local members = utils.toCSV(group.members, function(class, count)
        return class..":"..tostring(count)
    end)

    local list = {
        group.name,
        group.dungeon,
        roles,
        classes,
        tostring(group.created),
        group.comment,
        group.leader,
        members
    }
    return utils.toCSV(list, function(k, v) return v end, ";")
end

function Group.decode(encoded)
    if (encoded) then

        local list = utils.fromCSV(encoded, function(list, element)
            table.insert(list, element)
        end, ";")
        
        local name = list[1]
        local dungeon = list[2]
        local roles = list[3]
        local classes = list[4]
        local created = tonumber(list[5])
        local comment = list[6]
        local leader = list[7]
        local members = list[8]
        
        -- decode the roles and classes
        roles = utils.fromCSV(roles, function(list, element)
            list[element] = true
        end)
        classes = utils.fromCSV(classes, function(list, element)
            list[element] = true
        end)
        members = utils.fromCSV(members, function(list, element)
            local class, count = strsplit(":", element, 2)
            count = tonumber(count)
            if (class and count) then
                list[class] = count
            end
        end)
        
        return Group.new(name, dungeon, roles, classes, created, comment, leader, members)
    end
end
