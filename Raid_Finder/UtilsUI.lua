-- namespace
local _, ns = ...;
local utilsUI = {}

-- layout constants
utilsUI.COLUMN_WIDTH = 155
utilsUI.TEXT_FIELD_HEIGHT = 20
utilsUI.ITEM_BUTTON_HEIGHT = 41
utilsUI.WINDOW_WIDTH = 410
utilsUI.WINDOW_HEIGHT = 485
utilsUI.MARGIN = 12
utilsUI.SPACING = 6

utilsUI.createTabs = function(parentFrame, tabLabels)
    local tabs = {}
    local numTabs = #tabLabels
    parentFrame.numTabs = numTabs
    for tabIndex = 1, numTabs do
        local tabButton = CreateFrame("Button", parentFrame:GetName().."Tab"..tabIndex, parentFrame, "CharacterFrameTabButtonTemplate")
        local tabFrame = CreateFrame("Frame", nil, parentFrame)
        tabButton.contentFrame = tabFrame
        tabButton:SetText(tabLabels[tabIndex])
        tabs[tabIndex] = tabButton

        tabButton:SetID(tabIndex)
        tabButton:SetScript("OnClick", function()
            PanelTemplates_SetTab(parentFrame, tabIndex)
            for index, tab in pairs(tabs) do
                if (index == tabIndex) then
                    tab.contentFrame:Show()
                else
                    tab.contentFrame:Hide()
                end
            end
        end)
        if (tabIndex == 1) then
            tabButton:SetPoint("TOPLEFT", parentFrame, "BOTTOMLEFT", 5, 7)
        else
            tabButton:SetPoint("TOPLEFT", tabs[tabIndex - 1], "TOPRIGHT", -14, 0)
        end

        tabFrame:SetPoint("TOPLEFT", parentFrame:GetName().."DialogBG", "TOPLEFT", 0, 0)
        tabFrame:SetPoint("BOTTOMRIGHT", parentFrame:GetName().."DialogBG", "BOTTOMRIGHT", 0, 0)
        if (tabIndex ~= 1) then tabFrame:Hide() end
    end
    PanelTemplates_SetTab(parentFrame, 1)
    return tabs
end

---
-- Toggles the given frame, thus shows or hides it depending on if it is
-- currently shown. Note that this just works outside of combat.
--
-- @param #Frame frame
--          the frame to show/hide
--
utilsUI.toggleUI = function(frame)
    if (not UnitAffectingCombat("player")) then
        if (frame:IsShown()) then
            HideUIPanel(frame)
        else
            ShowUIPanel(frame)
        end
    end
end

---
-- Creates a border around the given frame.
--
-- @param #Frame frame
--          the frame to create the border for
--
utilsUI.createBorder = function(frame)
    CreateFrame("Frame", nil, frame, "InsetFrameTemplate"):SetAllPoints()
end

---
-- Hides the GameTooltip.
--
utilsUI.hideTooltip = function()
    GameTooltip:ClearLines()
    GameTooltip:Hide()
end

---
-- Shows a tooltip for the given player name.
--
-- @param #Frame owner
--          defines the element where the tooltip is centered on
-- @param #string playerName
--          the name of the player
--
utilsUI.showPlayerTooltip = function(owner, playerName)
    local unitName = playerName
    local name, realm = UnitName(playerName)
    if (name and realm) then
        unitName = name.."-"..realm
    end
    GameTooltip:SetOwner(owner, "ANCHOR_BOTTOMRIGHT")
    GameTooltip:SetUnit(unitName)
end

utilsUI.showItemTooltip = function(owner, itemId)
    GameTooltip:SetOwner(owner, "ANCHOR_BOTTOMRIGHT")
    GameTooltip:SetItemByID(itemId)
end

ns.utilsUI = utilsUI
