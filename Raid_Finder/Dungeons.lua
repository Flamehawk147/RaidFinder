-- namespace
local _, ns = ...;

-- constants
local CATEGORY_RAID = "Raids"

local RAIDS = {
    {
        name = "Naxxramas (10)",
        category = CATEGORY_RAID,
        maxPlayers = 10,
        requiredLevel = 80,
        minimumLevel = 80,
        maximumLevel = 80
    },
    {
        name = "Obsidian Sanctum (10)",
        category = CATEGORY_RAID,
        maxPlayers = 10,
        requiredLevel = 80,
        minimumLevel = 80,
        maximumLevel = 80
    },
    {
        name = "Ulduar (10)",
        category = CATEGORY_RAID,
        maxPlayers = 10,
        requiredLevel = 80,
        minimumLevel = 80,
        maximumLevel = 80
    },
    {
        name = "Trial of the Crusader (10)",
        category = CATEGORY_RAID,
        maxPlayers = 10,
        requiredLevel = 80,
        minimumLevel = 80,
        maximumLevel = 80
    },
    {
        name = "Icecrown Citadel (10)",
        category = CATEGORY_RAID,
        maxPlayers = 10,
        requiredLevel = 80,
        minimumLevel = 80,
        maximumLevel = 80
    },
    {
        name = "Eye of Eternity (10)",
        category = CATEGORY_RAID,
        maxPlayers = 10,
        requiredLevel = 80,
        minimumLevel = 80,
        maximumLevel = 80
    },
    {
        name = "Vault of Archavon (10)",
        category = CATEGORY_RAID,
        maxPlayers = 10,
        requiredLevel = 80,
        minimumLevel = 80,
        maximumLevel = 80
    },
    {
        name = "Onyxia's Lair (10)",
        category = CATEGORY_RAID,
        maxPlayers = 10,
        requiredLevel = 80,
        minimumLevel = 80,
        maximumLevel = 80
    }
}
ns.RAIDS = RAIDS

local DUNGEON_LIST = {}
local DUNGEON_SET = {}
table.insert(DUNGEON_LIST, { name = CATEGORY_RAID })
for i, raid in ipairs(RAIDS) do
    table.insert(DUNGEON_LIST, raid)
    DUNGEON_SET[raid.name] = raid
end
ns.DUNGEON_LIST = DUNGEON_LIST
ns.DUNGEON_SET = DUNGEON_SET
