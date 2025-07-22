-- namespace
local _, ns = ...;
local utils = {}

---
-- Returns the size of the given table. Returns 0 if the table is nil.
--
-- @param #table tbl
--          the table to compute the size for
--
-- @return #number
--          the size of the table
--
utils.tblsize = function(tbl)
    local size = 0
    if (tbl) then
        for _ in pairs(tbl) do
            size = size + 1
        end
    end
    return size
end

---
-- Copies the key-value pairs from the given table into a new table. Note that
-- the returned table is not a deep copy of the given table! Returns nil if the
-- given table is nil.
--
-- @param #table tbl
--          the table to be copied
--
-- @return #table
--          the copy of the table or nil
--
utils.copy = function(tbl)
    if (tbl) then
        local copy = {}
        for k,v in pairs(tbl) do
            copy[k] = v
        end
        return copy
    end
end

---
-- Returns a list containing the elements of the given list in random order.
--
-- @param #table list
--          a list with the elements to be shuffled
--
-- @return #table
--          a new list containing the shuffled elements
--
utils.shuffle = function(list)
    local shuffled = {}
    for i, v in ipairs(list) do
        local pos = math.random(1, #shuffled+1)
        table.insert(shuffled, pos, v)
    end
    return shuffled
end

---
-- Returns a comma-separated list string containing the elements of the given
-- list. The elements are passed as key-value pairs to the encoding function to
-- provide a string representation.
--
-- If the given delimiter is nil, the default comma ',' will be used.
--
-- @param #table list
--          the list to iterate over
-- @param #function enc
--          a function(key, value) return a string
-- @param #string delimiter
--          the delimiter, may be nil
--
-- @return #string
--          the comma-separated string list, not nil
--
utils.toCSV = function(list, enc, delimiter)
    local csv = ""
    delimiter = delimiter or ","
    if (list) then
        local key, value = next(list)
        if (key) then csv = enc(key, value) end
        for key, value in next, list, key do
            csv = csv..delimiter..enc(key, value)
        end
    end
    return csv
end

---
-- Returns a list containing the elements read from the given comma-separated
-- list string. The elements are passed to the decoding function that will
-- insert the element into the list.
--
-- If the given delimiter is nil, the default comma ','  will be used.
--
-- @param #string csv
--          the comma-separated string list
-- @param #function dec
--          a function(list, element) that inserts the element into the list
-- @param #string delimiter
--          the delimiter, may be nil
--
-- @return #table
--          the table containing the elements, not nil
--
utils.fromCSV = function(csv, dec, delimiter)
    local list = {}
    if (csv) then
        local split = { strsplit(delimiter or ",", csv) }
        for _, element in pairs(split) do
            dec(list, element)
        end
    end
    return list
end

CLASS_NAMES_MALE = {}
CLASS_NAMES_FEMALE = {}
FillLocalizedClassList(CLASS_NAMES_MALE, false)
FillLocalizedClassList(CLASS_NAMES_FEMALE, true)
utils.toEnglishClass = function(localizedClass)
    if (localizedClass) then
        for englishClass, className in pairs(CLASS_NAMES_MALE) do
            if (className == localizedClass) then
                return englishClass
            end
        end
        for englishClass, className in pairs(CLASS_NAMES_FEMALE) do
            if (className == localizedClass) then
                return englishClass
            end
        end
    end
    return localizedClass
end

---
-- Iterates over each raid member that is currently online and calls the given
-- action with the raid member name.
--
-- Note that even in case the player is not in a group, the action is always
-- called with the player name.
--
-- @param #function action
--          a function(name) that is called for each raid member
--
utils.forEachRaidMember = function(action)
    if (action) then
        local playerName = UnitName("player")
        local memberCount = GetNumGroupMembers()
        if (memberCount > 0) then
            for index = 1, memberCount do
                local name, rank, subgroup, level, class, fileName,
                    zone, online, isDead, role, isML = GetRaidRosterInfo(index)
                -- the class is localized, we need to convert it to the english name
                class = utils.toEnglishClass(class)
                action(name, rank, level, class)
            end
        else
            -- if we are not in a group, we still execute the action on ourselves
            local _, class = UnitClass("player")
            action(playerName, 0, UnitLevel("player"), class)
        end
    end
end

ns.utils = utils


-- UNIT TESTS
local function assertEquals(arg1, arg2)
    if (arg1 ~= arg2) then error("'"..tostring(arg1).."' ~= '"..tostring(arg2).."'", 2) end
end
local function tests()
    assertEquals(utils.tblsize({ 1, 2, 3 }), 3)
    assertEquals(utils.tblsize({ 1 }), 1)
    assertEquals(utils.tblsize({}), 0)
    assertEquals(utils.tblsize(nil), 0)

    assertEquals(utils.toCSV({ "a", "b", "c" }, function(k,v) return v end), "a,b,c")
end

local status, result = pcall(tests)
if not status then print("Test failures: "..result) end
