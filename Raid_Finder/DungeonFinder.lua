-- namespace
local _, ns = ...;
-- imports
local playerLocale= LibStub("AceLocale-3.0"):GetLocale("DungeonFinder")
local AddonMessage= ns.AddonMessage
local Broadcast = ns.Broadcast
local Group= ns.Group
local Player= ns.Player
local ScrollList= ns.ScrollList
local utils= ns.utils
local utilsUI= ns.utilsUI

local DUNGEON_LIST= ns.DUNGEON_LIST
local DUNGEON_SET= ns.DUNGEON_SET

-- constants
local ROLE_TANK= "TANK"
local ROLE_HEALER= "HEALER"
local ROLE_DAMAGER= "DAMAGER"

local CLASS_WARRIOR= "WARRIOR"
local CLASS_PALADIN= "PALADIN"
local CLASS_HUNTER= "HUNTER"
local CLASS_ROGUE= "ROGUE"
local CLASS_PRIEST= "PRIEST"
local CLASS_SHAMAN= "SHAMAN"
local CLASS_MAGE= "MAGE"
local CLASS_WARLOCK= "WARLOCK"
local CLASS_DRUID= "DRUID"

local RAID_ROLES = {
    [CLASS_WARRIOR]= ROLE_TANK,
    [CLASS_PALADIN]= ROLE_HEALER,
    [CLASS_HUNTER]= ROLE_DAMAGER,
    [CLASS_ROGUE]= ROLE_DAMAGER,
    [CLASS_PRIEST]= ROLE_HEALER,
    [CLASS_SHAMAN]= ROLE_HEALER,
    [CLASS_MAGE]= ROLE_DAMAGER,
    [CLASS_WARLOCK]= ROLE_DAMAGER,
    [CLASS_DRUID]= ROLE_HEALER
}

-- communication
local ADDON_CHANNEL= "DungeonFinder"
local EVENT_LFM= "DF_LFM"
local EVENT_LFG= "DF_LFG"
local EVENT_CANCEL= "DF_CANCEL"

-- UI
local WINDOW_WIDTH = 350
local WINDOW_HEIGHT = 450

local UIFrame = CreateFrame("Frame", "DungeonFinderIU", UIParent, "UIPanelDialogTemplate")
UIFrame:SetAttribute("UIPanelLayout-defined", true)
UIFrame:SetAttribute("UIPanelLayout-enabled", true)
UIFrame:SetAttribute("UIPanelLayout-area", "left")
UIFrame:SetAttribute("UIPanelLayout-pushable", 5)
UIFrame:SetAttribute("UIPanelLayout-width", WINDOW_WIDTH)
UIFrame:SetAttribute("UIPanelLayout-whileDead", true)
UIFrame:SetSize(WINDOW_WIDTH, WINDOW_HEIGHT)
UIFrame:SetPoint("CENTER")
UIFrame.Title:SetText(playerLocale["Dungeon Finder"])
HideUIPanel(UIFrame)

-- create tabs
local tabs = utilsUI.createTabs(UIFrame, { "LFG", "LFM" })
local lfgTabFrame = tabs[1].contentFrame
local lfgDungeonFrame
local lfgGroupFrame
lfgTabFrame:SetScript("OnShow", function()
    if (ns.DB.lfg) then
        lfgDungeonFrame:Hide()
        lfgGroupFrame:Show()
    else
        lfgDungeonFrame:Show()
        lfgGroupFrame:Hide()
    end
end)

--
-- THE LFG DUNGEON FRAME
--
lfgDungeonFrame = CreateFrame("Frame", nil, lfgTabFrame)
lfgDungeonFrame:SetAllPoints()

local roleInset = CreateFrame("Frame", nil, lfgDungeonFrame, "InsetFrameTemplate")
roleInset:SetPoint("TOPLEFT", lfgDungeonFrame, "TOPLEFT", 0, 0)
roleInset:SetPoint("BOTTOMRIGHT", lfgDungeonFrame, "TOPRIGHT", 0, -75)

local tankRoleButton = CreateFrame("Button", nil, roleInset, "DungeonFinderRoleButtonTemplate")
tankRoleButton:SetPoint("TOPLEFT", lfgDungeonFrame, "TOPLEFT", 60, -15)
tankRoleButton.role = ROLE_TANK
--tankRoleButton.background:SetTexCoord(GetBackgroundTexCoordsForRole(ROLE_TANK))
tankRoleButton:GetNormalTexture():SetTexCoord(GetTexCoordsForRole(ROLE_TANK));
tankRoleButton.checkButton:SetScript("OnClick", function()
    ns.DB.player:setRole(ROLE_TANK, tankRoleButton.checkButton:GetChecked())
end)
tankRoleButton:SetScript("OnShow", function()
    tankRoleButton.checkButton:SetChecked(ns.DB.player:hasRole(ROLE_TANK))
end)

local healerRoleButton = CreateFrame("Button", nil, roleInset, "DungeonFinderRoleButtonTemplate")
healerRoleButton:SetPoint("LEFT", tankRoleButton, "RIGHT", 45, 0)
healerRoleButton.role = ROLE_HEALER
--healerRoleButton.background:SetTexCoord(GetBackgroundTexCoordsForRole(ROLE_HEALER))
healerRoleButton:GetNormalTexture():SetTexCoord(GetTexCoordsForRole(ROLE_HEALER));
healerRoleButton.checkButton:SetScript("OnClick", function()
    ns.DB.player:setRole(ROLE_HEALER, healerRoleButton.checkButton:GetChecked())
end)
healerRoleButton:SetScript("OnShow", function()
    healerRoleButton.checkButton:SetChecked(ns.DB.player:hasRole(ROLE_HEALER))
end)

local damagerRoleButton = CreateFrame("Button", nil, roleInset, "DungeonFinderRoleButtonTemplate")
damagerRoleButton:SetPoint("LEFT", healerRoleButton, "RIGHT", 45, 0)
damagerRoleButton.role = ROLE_DAMAGER
--damagerRoleButton.background:SetTexCoord(GetBackgroundTexCoordsForRole(ROLE_DAMAGER))
damagerRoleButton:GetNormalTexture():SetTexCoord(GetTexCoordsForRole(ROLE_DAMAGER));
damagerRoleButton.checkButton:SetScript("OnClick", function()
    ns.DB.player:setRole(ROLE_DAMAGER, damagerRoleButton.checkButton:GetChecked())
end)
damagerRoleButton:SetScript("OnShow", function()
    damagerRoleButton.checkButton:SetChecked(ns.DB.player:hasRole(ROLE_DAMAGER))
end)

local dungeonInset = CreateFrame("Frame", nil, lfgDungeonFrame, "InsetFrameTemplate")
dungeonInset:SetPoint("TOPLEFT", roleInset, "BOTTOMLEFT", 0, 0)
dungeonInset:SetPoint("BOTTOMRIGHT", lfgDungeonFrame, "BOTTOMRIGHT", 0, 33)

local categoryFilters = {}
local dungeonScrollList = ScrollList.new("DungeonFinderDungeonScrollList", dungeonInset, 18, "DungeonFinderSpecificChoiceTemplate")
dungeonScrollList:SetPoint("TOPLEFT", dungeonInset, "TOPLEFT", 0, -6)
dungeonScrollList:SetPoint("BOTTOMRIGHT", dungeonInset, "BOTTOMRIGHT", -26, 6)
dungeonScrollList:SetWidth(300)
dungeonScrollList:SetButtonHeight(16)
dungeonScrollList:SetContentProvider(function() return DUNGEON_LIST end)
dungeonScrollList:SetLabelProvider(function(index, dungeon, button)
    local playerLevel = UnitLevel("player")

    button.dungeon = dungeon
    button.instanceName:SetText(playerLocale[dungeon.name])
    if (dungeon.category) then
        -- a dungeon or raid
        button.expandOrCollapseButton:Hide()
        button.isCollapsed = false
        -- button.instanceName:SetFontObject("GameFontNormalLeft");

        -- check the required level of the player
        if (playerLevel < dungeon.requiredLevel) then
            button.lockedIndicator:Show()
            --            button:SetScript("OnEnter", function()
            --                GameTooltip:ClearLines()
            --                GameTooltip:SetOwner(button, "ANCHOR_CURSOR")
            --                GameTooltip:AddLine("Requires Level "..dungeon.requiredLevel..".")
            --                GameTooltip:Show()
            --            end)
            --            button:SetScript("OnLeave", function()
            --                GameTooltip:Hide()
            --            end)
            button.enableButton:Disable()
            button.enableButton:Hide()
        else
            button.lockedIndicator:Hide()
            button.enableButton:Enable()
            button.enableButton:Show()
        end

        -- set checked status
        button.enableButton:SetChecked(ns.DB.player:isLookingForDungeon(dungeon))
        button.enableButton:SetScript("OnClick", function()
            if (dungeon.category) then
                ns.DB.player:setLookingForDungeon(dungeon, button.enableButton:GetChecked())
            end
            dungeonScrollList:Update()
        end)

        -- the level range
        button.level:Show()
        local levelText
        if (dungeon.minimumLevel == dungeon.maximumLevel) then
            levelText = tostring(dungeon.minimumLevel)
        else
            levelText = dungeon.minimumLevel.." - "..dungeon.maximumLevel
        end
        button.level:SetText("("..levelText..")")

        -- the color for the level range
        local levelCompare
        if (playerLevel < dungeon.minimumLevel) then
            levelCompare = dungeon.minimumLevel
        elseif (playerLevel > dungeon.maximumLevel) then
            levelCompare = dungeon.maximumLevel
        else
            levelCompare = playerLevel
        end
        -- TODO set the color for the dungeon text as well
        local difficultyColor = GetQuestDifficultyColor(levelCompare)
        button.level:SetFontObject(difficultyColor.font)
        button.instanceName:SetFontObject(difficultyColor.font)

    else
        local category = dungeon.name
        -- returns 0 for no dungeons, 1 for at least 1 dungeon, 2 for all dungeons
        local function dungeonsSelected()
            local oneDungeonSelected = false
            local allDungeonsSelected = true
            for i, d in ipairs(DUNGEON_LIST) do
                if (d.category and d.category == category and playerLevel >= d.requiredLevel) then
                    if (ns.DB.player:isLookingForDungeon(d)) then
                        oneDungeonSelected = true
                    else
                        allDungeonsSelected = false
                    end
                end
            end
            if (allDungeonsSelected and oneDungeonSelected) then
                return 2
            elseif (oneDungeonSelected) then
                return 1
            else
                return 0
            end
        end

        -- simply a category
        button.instanceName:SetFontObject("GameFontHighlightLeft");
        button.level:Hide()
        button.lockedIndicator:Hide()

        -- enable expand / collapse
        button.expandOrCollapseButton:Show()
        button.expandOrCollapseButton:SetScript("OnClick", function()
            local state = categoryFilters[category]
            if (state) then
                categoryFilters[category] = nil
            else
                categoryFilters[category] = true
            end
            dungeonScrollList:Update()
        end)
        if (categoryFilters[category]) then
            button.expandOrCollapseButton:SetNormalTexture("Interface\\Buttons\\UI-PlusButton-UP")
        else
            button.expandOrCollapseButton:SetNormalTexture("Interface\\Buttons\\UI-MinusButton-UP")
        end

        -- enable select/deselect all
        button.enableButton:Enable()
        button.enableButton:Show()
        button.enableButton:SetScript("OnClick", function()
            -- if at least one dungeon is select, we deselect all
            if (dungeonsSelected() > 0) then
                ns.DB.player:clearLookingForDungeon()
            else
                for i, d in ipairs(DUNGEON_LIST) do
                    if (d.category and d.category == category and playerLevel >= d.requiredLevel) then
                        ns.DB.player:setLookingForDungeon(d, true)
                    end
                end
            end
            dungeonScrollList:Update()
        end)
        local selection = dungeonsSelected()
        if (selection == 2) then
            button.enableButton:SetChecked(true)
            button.enableButton:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check");
            button.enableButton:SetDisabledCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check-Disabled");
        elseif (selection == 1) then
            button.enableButton:SetChecked(true)
            button.enableButton:SetCheckedTexture("Interface\\Buttons\\UI-MultiCheck-Up");
            button.enableButton:SetDisabledCheckedTexture("Interface\\Buttons\\UI-MultiCheck-Disabled");
        else
            button.enableButton:SetChecked(false)
            button.enableButton:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check");
            button.enableButton:SetDisabledCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check-Disabled");
        end
    end
    -- show heroic icon if the dungeon's minimum level is higher than the player level
    if (dungeon.category and playerLevel < dungeon.minimumLevel and playerLevel >= dungeon.requiredLevel) then
        button.heroicIcon:Show()
    else
        button.heroicIcon:Hide()
    end
end)
dungeonScrollList:SetFilter(function(index, dungeon)
    if (not dungeon.category or not categoryFilters[dungeon.category]) then
        return true
    end
end)
dungeonScrollList:Update()

local findGroupButton = CreateFrame("Button", nil, lfgDungeonFrame, "GameMenuButtonTemplate")
findGroupButton:SetPoint("BOTTOM", lfgDungeonFrame, "BOTTOM", 0, 6)
findGroupButton:SetSize(155, 20)
findGroupButton:SetText(playerLocale["Find Group"])
findGroupButton:SetNormalFontObject("GameFontNormal")
findGroupButton:SetScript("OnClick", function()
    if (ns.DB.player:isLFGReady()) then
        Broadcast.lfg()
        PlaySound(SOUNDKIT.PVP_ENTER_QUEUE)
        lfgDungeonFrame:Hide()
        lfgGroupFrame:Show()
    else
        PlaySound(SOUNDKIT.LFG_DENIED)
    end
end)


--
-- THE LFG GROUP FRAME
--
lfgGroupFrame = CreateFrame("Frame", nil, lfgTabFrame)
lfgGroupFrame:SetAllPoints()
if (not ns.DB.lfg) then
    lfgGroupFrame:Hide() -- only show the first frame
end

local lfgGroupLabel = lfgGroupFrame:CreateFontString(nil, "ARTWORK", "MailFont_Large")
lfgGroupLabel:SetPoint("TOPLEFT", lfgGroupFrame, "TOPLEFT", 12, -15)
lfgGroupLabel:SetText(playerLocale["Dungeon Groups"])
lfgGroupLabel:SetTextColor(1, 0.82, 0)

local lfgRefreshButton = CreateFrame("Button", nil, lfgGroupFrame, "DungeonFinderRefreshButtonTemplate")
lfgRefreshButton:SetSize(32, 32)
lfgRefreshButton:SetPoint("TOPRIGHT", lfgGroupFrame, "TOPRIGHT", -6, -6)
lfgRefreshButton:SetScript("OnClick", function()
    Broadcast.lfg()
    PlaySound(SOUNDKIT.PVP_ENTER_QUEUE)
    ns.refeshLFGFields()
end)

--local refreshButtonTexture = lfgRefreshButton:CreateTexture(nil, "ARTWORK")
--refreshButtonTexture:SetSize(16, 16)
--refreshButtonTexture:SetPoint("CENTER", lfgRefreshButton, "CENTER", -1, 0)
--refreshButtonTexture:SetTexture("Interface\\Buttons\\UI-RefreshButton")

local lfgGroupSearchBox = CreateFrame("EditBox", nil, lfgGroupFrame, "SearchBoxTemplate")
lfgGroupSearchBox:SetPoint("TOP", lfgGroupLabel, "BOTTOM", 0, -12)
lfgGroupSearchBox:SetPoint("LEFT", lfgGroupFrame, "LEFT", 12, 0)
lfgGroupSearchBox:SetPoint("RIGHT", lfgGroupFrame, "RIGHT", -12, 0)
lfgGroupSearchBox:SetPoint("BOTTOM", lfgGroupLabel, "BOTTOM", 0, -30)

local lfgGroupInset = CreateFrame("Frame", nil, lfgGroupFrame, "InsetFrameTemplate")
lfgGroupInset:SetPoint("TOP", lfgGroupSearchBox, "BOTTOM", 0, -12)
lfgGroupInset:SetPoint("LEFT", lfgGroupFrame, "LEFT", 0, 0)
lfgGroupInset:SetPoint("RIGHT", lfgGroupFrame, "RIGHT", 0, 0)
lfgGroupInset:SetPoint("BOTTOM", lfgGroupFrame, "BOTTOM", 0, 33)

local groupScrollList = ScrollList.new("DungeonFinderGroupScrollList", lfgGroupInset, 8, "DungeonFinderGroupButtonTemplate")
groupScrollList:SetPoint("TOPLEFT", lfgGroupInset, "TOPLEFT", 6, -6)
groupScrollList:SetPoint("BOTTOMRIGHT", lfgGroupInset, "BOTTOMRIGHT", -26, 6)
groupScrollList:SetWidth(300)
groupScrollList:SetButtonHeight(36)
groupScrollList:SetContentProvider(function()
    return ns.DB.dungeonGroups
end)
groupScrollList:SetLabelProvider(function(name, group, button)
    button.Name:SetText((playerLocale[group.name] or group.name) or "")
    button.ActivityName:SetText((playerLocale[group.dungeon] or group.dungeon) or "")

    -- role or class list
    if (group.dungeon) then
        local dungeon = DUNGEON_SET[group.dungeon]
        if (dungeon) then
            if (dungeon.maxPlayers > 5) then
                -- show the roles
                button.RoleDisplay:Show()
                button.ClassDisplay:Hide()

                -- count the roles
                local roleCount = {}
                for class, count in pairs(group.members) do
                    local role = RAID_ROLES[class]
                    if (role) then
                        local rc = roleCount[role] or 0
                        rc = rc + count
                        roleCount[role] = rc
                    end
                end
                button.RoleDisplay.TankCount:SetText(tostring(roleCount[ROLE_TANK] or 0))
                button.RoleDisplay.HealerCount:SetText(tostring(roleCount[ROLE_HEALER] or 0))
                button.RoleDisplay.DamagerCount:SetText(tostring(roleCount[ROLE_DAMAGER] or 0))
            else
                -- show the classes
                button.RoleDisplay:Hide()
                button.ClassDisplay:Show()
                local classIndex = 1
                for class, count in pairs(group.members) do
                    for i = 1, count do
                        local classIcon = button.ClassDisplay.classIcons[classIndex]
                        local coords = CLASS_ICON_TCOORDS[class]
                        if (coords) then
                            classIcon:Show()
                            classIcon:SetTexCoord(unpack(coords))
                        else
                            classIcon:Hide()
                        end
                        classIndex = classIndex + 1
                        if (classIndex > 5) then classIndex = 5 end
                    end
                end
                -- hide all the other textures
                for i = classIndex, 5 do
                    local classIcon = button.ClassDisplay.classIcons[i]
                    classIcon:Hide()
                end
            end
        else
            button.RoleDisplay:Hide()
            button.ClassDisplay:Hide()
        end
    end

    -- add script to whisper the leader
    button:SetScript("OnClick", function()
        ChatFrame_SendTell(group.leader)
    end)
end)

local cancelFindGroupButton = CreateFrame("Button", nil, lfgGroupFrame, "GameMenuButtonTemplate")
cancelFindGroupButton:SetPoint("BOTTOM", lfgGroupFrame, "BOTTOM", 0, 6)
cancelFindGroupButton:SetSize(155, 20)
cancelFindGroupButton:SetText(playerLocale["Cancel"])
cancelFindGroupButton:SetNormalFontObject("GameFontNormal")
cancelFindGroupButton:SetScript("OnClick", function()
    lfgDungeonFrame:Show()
    lfgGroupFrame:Hide()
    -- send cancel group message
    Broadcast.lfgc()
    PlaySound(SOUNDKIT.LFG_DENIED)
end)

--{"groupfinder-icon-role-large-dps", [[Interface\LFGFrame\GroupFinder.BLP]], 29, 29, 0.6591796875, 0.6875, 0.1123046875, 0.140625, false, false},
--{"groupfinder-icon-role-large-heal", [[Interface\LFGFrame\GroupFinder.BLP]], 29, 29, 0.6455078125, 0.673828125, 0.0751953125, 0.103515625, false, false},
--{"groupfinder-icon-role-large-tank", [[Interface\LFGFrame\GroupFinder.BLP]], 29, 29, 0.62890625, 0.6572265625, 0.1123046875, 0.140625, false, false},

local lfmTabFrame = tabs[2].contentFrame
local lfmCreateFrame
local lfmInviteFrame
lfmTabFrame:SetScript("OnShow", function()
    if (ns.DB.lfm) then
        lfmCreateFrame:Hide()
        lfmInviteFrame:Show()
    else
        lfmCreateFrame:Show()
        lfmInviteFrame:Hide()
    end
end)

--
-- THE LFM CREATE GROUP FRAME
--
lfmCreateFrame = CreateFrame("Frame", nil, lfmTabFrame)
lfmCreateFrame:SetAllPoints()

local lfmGroupLabel = lfmCreateFrame:CreateFontString(nil, "ARTWORK", "MailFont_Large")
lfmGroupLabel:SetPoint("TOPLEFT", lfmCreateFrame, "TOPLEFT", 12, -15)
lfmGroupLabel:SetText(playerLocale["Create Group"])
lfmGroupLabel:SetTextColor(1, 0.82, 0)

local lfmCreateGroupInset = CreateFrame("Frame", nil, lfmCreateFrame, "InsetFrameTemplate")
lfmCreateGroupInset:SetPoint("TOP", lfmGroupLabel, "BOTTOM", 0, -12)
lfmCreateGroupInset:SetPoint("LEFT", lfmCreateFrame, "LEFT", 0, 0)
lfmCreateGroupInset:SetPoint("RIGHT", lfmCreateFrame, "RIGHT", 0, 0)
lfmCreateGroupInset:SetPoint("BOTTOM", lfmCreateFrame, "BOTTOM", 0, 33)

local lfmDungeonLabel = lfmCreateFrame:CreateFontString(nil, "ARTWORK")
lfmDungeonLabel:SetPoint("TOPLEFT", lfmCreateGroupInset, "TOPLEFT", 12, -12)
lfmDungeonLabel:SetFontObject("GameFontNormalLEFT")
lfmDungeonLabel:SetText(playerLocale["Dungeon"])

local lfmSelectDungeonDropDown = CreateFrame("Frame", nil, lfmCreateGroupInset, "UIDropDownMenuTemplate")
lfmSelectDungeonDropDown:SetPoint("TOP", lfmDungeonLabel, "BOTTOM", 0, -6)
lfmSelectDungeonDropDown:SetPoint("LEFT", lfmCreateGroupInset, "LEFT", 0, 0)
lfmSelectDungeonDropDown:SetPoint("RIGHT", lfmCreateGroupInset, "RIGHT", -12, 0)
lfmSelectDungeonDropDown:SetScript("OnShow", function()
    UIDropDownMenu_SetWidth(lfmSelectDungeonDropDown, 284) -- Use in place :SetWidth
    UIDropDownMenu_Initialize(lfmSelectDungeonDropDown, function(self, level, menuList)
        for index, dungeon in ipairs(DUNGEON_LIST) do
            if (dungeon.category) then
                local menuItem = UIDropDownMenu_CreateInfo()
                menuItem.text = playerLocale[dungeon.name] or dungeon.name
                menuItem.func = function()
                    lfmSelectDungeonDropDown.value = dungeon.name
                    UIDropDownMenu_SetText(lfmSelectDungeonDropDown, playerLocale[dungeon.name] or dungeon.name)
                end
                UIDropDownMenu_AddButton(menuItem, level)
            end
        end
    end)
end)


local lfmNameLabel = lfmCreateFrame:CreateFontString(nil, "ARTWORK")
lfmNameLabel:SetPoint("TOP", lfmSelectDungeonDropDown, "BOTTOM", 0, -6)
lfmNameLabel:SetPoint("LEFT", lfmCreateGroupInset, "LEFT", 12, 0)
lfmNameLabel:SetHeight(20)
lfmNameLabel:SetFontObject("GameFontNormalLEFT")
lfmNameLabel:SetText(playerLocale["Name"])

local lfmNameEditBox = CreateFrame("Editbox", nil, lfmCreateGroupInset, "InputBoxInstructionsTemplate")
lfmNameEditBox:SetPoint("TOPLEFT", lfmNameLabel, "BOTTOMLEFT", 12, 0)
lfmNameEditBox:SetSize(292, 25)
lfmNameEditBox:SetAutoFocus(false)
lfmNameEditBox:ClearFocus()

local lfmCommentLabel = lfmCreateFrame:CreateFontString(nil, "ARTWORK")
lfmCommentLabel:SetPoint("TOP", lfmNameEditBox, "BOTTOM", 0, -6)
lfmCommentLabel:SetPoint("LEFT", lfmCreateGroupInset, "LEFT", 12, 0)
lfmCommentLabel:SetHeight(20)
lfmCommentLabel:SetFontObject("GameFontNormalLEFT")
lfmCommentLabel:SetText(playerLocale["Comment"])

local lfmCommentEditBox = CreateFrame("Editbox", nil, lfmCreateGroupInset, "InputBoxInstructionsTemplate")
lfmCommentEditBox:SetPoint("TOPLEFT", lfmCommentLabel, "BOTTOMLEFT", 12, 0)
lfmCommentEditBox:SetSize(292, 25)
lfmCommentEditBox:SetAutoFocus(false)
lfmCommentEditBox:ClearFocus()

local lfmRoleLabel = lfmCreateFrame:CreateFontString(nil, "ARTWORK")
lfmRoleLabel:SetPoint("TOP", lfmCommentEditBox, "BOTTOM", 0, -6)
lfmRoleLabel:SetPoint("LEFT", lfmCreateGroupInset, "LEFT", 12, 0)
lfmRoleLabel:SetHeight(20)
lfmRoleLabel:SetFontObject("GameFontNormalLEFT")
lfmRoleLabel:SetText(playerLocale["Roles"])

local lfmRolesFrame = CreateFrame("Frame", nil, lfmCreateGroupInset, "DungeonFinderRoleSelectionFrameTemplate")
lfmRolesFrame:SetPoint("CENTER", lfmCreateGroupInset, "CENTER", 0, 0)
lfmRolesFrame:SetPoint("TOP", lfmCommentEditBox, "BOTTOM", 0, -18)

local lfmClassLabel = lfmCreateFrame:CreateFontString(nil, "ARTWORK")
lfmClassLabel:SetPoint("TOP", lfmRolesFrame, "BOTTOM", 0, -6)
lfmClassLabel:SetPoint("LEFT", lfmCreateGroupInset, "LEFT", 12, 0)
lfmClassLabel:SetHeight(20)
lfmClassLabel:SetFontObject("GameFontNormalLEFT")
lfmClassLabel:SetText(playerLocale["Classes"])

local lfmClassesFrame = CreateFrame("Frame", nil, lfmCreateFrame, "DungeonFinderClassFrameTemplate")
lfmClassesFrame:SetPoint("CENTER", lfmCreateGroupInset, "CENTER", 0, 0)
lfmClassesFrame:SetPoint("TOP", lfmRolesFrame, "BOTTOM", 0, -28)

local createGroupButton = CreateFrame("Button", nil, lfmCreateFrame, "GameMenuButtonTemplate")
createGroupButton:SetPoint("BOTTOM", lfmCreateFrame, "BOTTOM", 0, 6)
createGroupButton:SetSize(155, 20)
createGroupButton:SetText(playerLocale["Create Group"])
createGroupButton:SetNormalFontObject("GameFontNormal")
createGroupButton:SetScript("OnClick", function()
    -- check that all necessary fields are set
    local dungeonName = lfmSelectDungeonDropDown.value
    local groupName = lfmNameEditBox:GetText()
    local roles = {}
    for _, button in pairs(lfmRolesFrame.roleButtons) do
        if (button.checkButton:GetChecked()) then
            roles[button:GetAttribute("role")] = true
        end
    end
    local classes = {}
    for _, button in pairs(lfmClassesFrame.classButtons) do
        if (button.checkButton:GetChecked()) then
            classes[button:GetAttribute("class")] = true
        end
    end
    local comment = lfmCommentEditBox:GetText()

    if (groupName and strlen(groupName) > 0
        and dungeonName and strlen(dungeonName) > 0
        and utils.tblsize(roles) > 0
        and utils.tblsize(classes) > 0) then
        ns.DB.group = Group.new(groupName, dungeonName,
            roles, classes, nil, comment, nil, nil)
        -- send group info
        Broadcast.lfm()
        PlaySound(SOUNDKIT.PVP_ENTER_QUEUE)
        lfmCreateFrame:Hide()
        lfmInviteFrame:Show()
    else
        PlaySound(SOUNDKIT.LFG_DENIED)
    end
end)

--
-- THE LFM INVITE MEMBERS FRAME
--
lfmInviteFrame = CreateFrame("Frame", nil, lfmTabFrame)
lfmInviteFrame:SetAllPoints()
lfmInviteFrame:Hide()

local lfmDungeonNameLabel = lfmInviteFrame:CreateFontString(nil, "ARTWORK", "MailFont_Large")
lfmDungeonNameLabel:SetPoint("TOPLEFT", lfmInviteFrame, "TOPLEFT", 12, -15)
lfmDungeonNameLabel:SetText(playerLocale["Dungeon Name"])
lfmDungeonNameLabel:SetTextColor(1, 0.82, 0)

local lfmGroupNameLabel = lfmInviteFrame:CreateFontString(nil, "ARTWORK")
lfmGroupNameLabel:SetPoint("TOPLEFT", lfmDungeonNameLabel, "BOTTOMLEFT", 0, -6)
lfmGroupNameLabel:SetFontObject("GameFontHighlightLEFT")
lfmGroupNameLabel:SetText(playerLocale["Group Name"])

local lfmGroupCommentLabel = lfmInviteFrame:CreateFontString(nil, "ARTWORK")
lfmGroupCommentLabel:SetPoint("TOPLEFT", lfmGroupNameLabel, "BOTTOMLEFT", 0, -6)
lfmGroupCommentLabel:SetFontObject("GameFontDisableSmallLEFT")
lfmGroupCommentLabel:SetText(playerLocale["Comment"])

local lfmRefreshButton = CreateFrame("Button", nil, lfmInviteFrame, "DungeonFinderRefreshButtonTemplate")
lfmRefreshButton:SetSize(32, 32)
lfmRefreshButton:SetPoint("TOPRIGHT", lfmInviteFrame, "TOPRIGHT", -6, -6)
lfmRefreshButton:SetScript("OnClick", function()
    Broadcast.lfm()
    ns.refreshLFMFields()
    PlaySound(SOUNDKIT.PVP_ENTER_QUEUE)
end)

-- TODO show member count
--local lfmGroupMemberCountFrame = CreateFrame("Frame", nil, lfmInviteFrame, "DungeonFinderGroupDataDisplayTemplate")
--lfmGroupMemberCountFrame:SetPoint("TOPRIGHT", lfmRefreshButton, "BOTTOMRIGHT", 0, -6)

local lfmInviteInset = CreateFrame("Frame", nil, lfmInviteFrame, "InsetFrameTemplate")
lfmInviteInset:SetPoint("TOP", lfmGroupCommentLabel, "BOTTOM", 0, -12)
lfmInviteInset:SetPoint("LEFT", lfmInviteFrame, "LEFT", 0, 0)
lfmInviteInset:SetPoint("RIGHT", lfmInviteFrame, "RIGHT", 0, 0)
lfmInviteInset:SetPoint("BOTTOM", lfmInviteFrame, "BOTTOM", 0, 33)

local lfmMemberScrollList = ScrollList.new("DungeonFinderApplicantScrollList", lfmInviteInset, 8, "DungeonFinderApplicantButtonTemplate")
lfmMemberScrollList:SetPoint("TOPLEFT", lfmInviteInset, "TOPLEFT", 6, -6)
lfmMemberScrollList:SetPoint("BOTTOMRIGHT", lfmInviteInset, "BOTTOMRIGHT", -26, 6)
lfmMemberScrollList:SetWidth(300)
lfmMemberScrollList:SetButtonHeight(36)
lfmMemberScrollList:SetContentProvider(function()
    return ns.DB.applicants
end)
lfmMemberScrollList:SetLabelProvider(function(name, player, button)
    button.PlayerName:SetText(player.name)
    button.ClassName:SetText(playerLocale[player.class] or player.class)
    button.Level:SetText(tostring(player.level))

    -- adjust role buttons
    for i, role in ipairs({ ROLE_DAMAGER, ROLE_HEALER, ROLE_TANK }) do
        local roleIcon = button.roleIcons[i]
        if (player.roles[role]) then
            roleIcon:Show()
        else
            roleIcon:Hide()
        end
    end

    -- add script to whisper the player
    button:SetScript("OnClick", function()
        ChatFrame_SendTell(player.name)
    end)
    button.InviteButton:SetScript("OnClick", function()
        InviteUnit(player.name)
    end)
    button.DeclineButton:SetScript("OnClick", function()
        -- remove the player from the list
        ns.DB.applicants[name] = nil
        ns.refreshLFMFields()
    end)
end)
lfmMemberScrollList:Update()

local cancelCreateGroupButton = CreateFrame("Button", nil, lfmInviteFrame, "GameMenuButtonTemplate")
cancelCreateGroupButton:SetPoint("BOTTOM", lfmInviteFrame, "BOTTOM", 0, 6)
cancelCreateGroupButton:SetSize(155, 20)
cancelCreateGroupButton:SetText(playerLocale["Cancel"])
cancelCreateGroupButton:SetNormalFontObject("GameFontNormal")
cancelCreateGroupButton:SetScript("OnClick", function()
    lfmCreateFrame:Show()
    lfmInviteFrame:Hide()
    -- send cancel group message
    Broadcast.lfmc()
    PlaySound(SOUNDKIT.LFG_DENIED)
end)
-- update the dungeon info in the label frames
lfmInviteFrame:SetScript("OnShow", function()
    lfmDungeonNameLabel:SetText(playerLocale[ns.DB.group.dungeon] or ns.DB.group.dungeon)
    lfmGroupNameLabel:SetText(ns.DB.group.name)
    lfmGroupCommentLabel:SetText(ns.DB.group.comment)
end)

ns.refeshLFGFields = function()
    groupScrollList:Update()
end

ns.refreshLFMFields = function()
    lfmMemberScrollList:Update()
end
-- TODO add notifications

--lfmCreateFrame:Hide()
--lfmInviteFrame:Show()

SLASH_DungeonFinder1 = "/lfg"
SLASH_DungeonFinder2 = "/lfm"
SLASH_DungeonFinder3 = "/dungeonfinder"
SlashCmdList["DungeonFinder"] = function(s)
--    if (not UnitAffectingCombat("player")) then
        JoinChannelByName(ADDON_CHANNEL)
        if (UIFrame:IsShown()) then
            HideUIPanel(UIFrame)
        else
            ShowUIPanel(UIFrame)
        end
--    end
end


local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("VARIABLES_LOADED")
--eventFrame:RegisterEvent("CHAT_MSG_SYSTEM")
C_ChatInfo.RegisterAddonMessagePrefix(EVENT_LFM)
C_ChatInfo.RegisterAddonMessagePrefix(EVENT_LFG)
C_ChatInfo.RegisterAddonMessagePrefix(EVENT_CANCEL)
eventFrame:SetScript("OnEvent", function(self, event, arg1, arg2, arg3, arg4)
    if (event == "VARIABLES_LOADED") then
        ns.loadSavedVariables()
    elseif (event == "CHAT_MSG_SYSTEM") then
        -- when joining a group, cancel the LFG
--        if (IsInGroup() and ns.DB.lfg) then
--            LFGCancel()
--            lfgDungeonFrame:Show()
--            lfgGroupFrame:Hide()
--        end
        -- update the lfm status when members join
--        if (IsInGroup() and ns.DB.lfm) then
--            LFMBroadcast()
--        end
    end
end)

print("Addon loaded... DungeonFinder "..GetAddOnMetadata("DungeonFinder", "Version"))
