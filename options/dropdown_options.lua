local _, ICT = ...

local DDM = LibStub("LibUIDropDownMenu-4.0")
local L = LibStub("AceLocale-3.0"):GetLocale("AltAnon")
local Expansion = ICT.Expansion
local log = ICT.log
local Options = ICT.Options
local Player = ICT.Player
local Tooltips = ICT.Tooltips
local UI = ICT.UI
ICT.DropdownOptions = {}
local DropdownOptions = ICT.DropdownOptions

local function createInfo(text)
    local info = DDM:UIDropDownMenu_CreateInfo()
    info.text = text
    -- It seems you can't simply do not self.checked if keepShownOnClick is true
    -- otherwise on the first click the menu gets confused...
    info.keepShownOnClick = true
    return info
end

local function isVisible(v) return v.isVisible and v:isVisible() end

local function addAllPlayerOptions(name, func, level)
    local check = function()
        local wasChecked = true
        for _, player in ICT:nspairsByValue(ICT.db.players, Player.isVisible) do
            wasChecked = wasChecked and ICT:containsAllValues(func(player), isVisible)
        end
        return wasChecked
    end
    local info = createInfo(name)
    info.checked = check()
    info.menuList = info.text
    info.hasArrow = true
    info.func = function(self)
        local wasChecked = check()
        for _, player in ICT:nspairsByValue(ICT.db.players, Player.isVisible) do
            for _, pet in pairs(player:getPets()) do
                pet:setVisible(not wasChecked)
            end
        end
        UI:PrintPlayers()
    end
    DDM:UIDropDownMenu_AddButton(info, level)
end

function DropdownOptions:addPlayerOptions(func, level)
    for _, player in ICT:nspairsByValue(ICT.db.players, Player.isVisible) do
        if ICT:size(func(player)) > 0 then
            local info = createInfo(player:getName())
            info.checked = ICT:containsAllValues(func(player), isVisible)
            info.menuList = player:getFullName()
            info.hasArrow = true

            info.func = function(self)
                local wasChecked = ICT:containsAllValues(func(player), isVisible)
                for _, o in ICT:fpairsByValue(func(player), function(v) return v:fromPlayer(player) end ) do
                    o:setVisible(not wasChecked)
                end
                UI:PrintPlayers()
            end
            DDM:UIDropDownMenu_AddButton(info, level)
        end
    end
end

function DropdownOptions:addObjectOption(o, level)
    local info = createInfo(o:getName())
    info.checked = o:isVisible()
    info.value = o.getFullName and o:getFullName() or o:getName()
    info.func = function(self)
        o:setVisible(not o:isVisible())
        UI:PrintPlayers()
    end
    DDM:UIDropDownMenu_AddButton(info, level)
end

function DropdownOptions:addExpansionOptions(objects, level)
    for expansion, name in ICT:rspairs(ICT.Expansions) do
        if Expansion.active(expansion) then
            local info = createInfo(name)
            local contains = function(v)
                -- v is visible or it's not from that expansion.
                return v:isVisible() or not v:fromExpansion(expansion)
            end
            info.checked = ICT:containsAllValues(objects, contains)
            info.menuList = expansion
            info.hasArrow = true

            info.func = function(self)
                local wasChecked = ICT:containsAllValues(objects, contains)
                for _, o in ICT:fpairsByValue(objects, function(v) return v:fromExpansion(expansion) end) do
                    o:setVisible(not wasChecked)
                end
                UI:PrintPlayers()
            end
            DDM:UIDropDownMenu_AddButton(info, level)
        end
    end
end

function DropdownOptions:addOptions(options, group, level)
    for _, v in pairs(options) do
        if v.predicate == nil or v.predicate() then
            local info = createInfo(v.name)
            info.checked = ICT.db.options[group][v.key]
            info.func = function(self)
                ICT.db.options[group][v.key] = not ICT.db.options[group][v.key]
                if v.func then
                    v.func()
                end
                UI:PrintPlayers()
            end
            if v.tooltip then
                info.tooltipTitle = v.name
                info.tooltipOnButton = true
                info.tooltipText = v.tooltip
            end
            DDM:UIDropDownMenu_AddButton(info, level)
        end
    end
end

function DropdownOptions:logLevels(frame)
    local dropdown = DDM:Create_UIDropDownMenu("ICTLogLevel", frame)
    ICT.db.logLevel = ICT.db.logLevel or "error"
    dropdown:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 4)
    Tooltips:new(L["Log Level"], L["LogLevelTooltip"]):attachFrame(dropdown)
    DDM:UIDropDownMenu_SetWidth(dropdown, 90)
    DDM:UIDropDownMenu_Initialize(
        dropdown,
        function(self, level, menuList)
            if (level or 1) == 1 then
                for _, v in pairs(log.modes) do
                    local info = createInfo(WrapTextInColorCode(v.name, v.color))
                    info.checked = ICT.db.logLevel == v.name
                    if info.checked then
                        DDM:UIDropDownMenu_SetText(dropdown, info.text)
                    end
                    info.func = function(self)
                        ICT.db.logLevel = v.name
                        DDM:UIDropDownMenu_SetText(dropdown, info.text)
                    end
                    info.keepShownOnClick = false
                    DDM:UIDropDownMenu_AddButton(info, level)
                end
            end
        end
    )
end

function DropdownOptions:setPlayer(player)
    DDM:UIDropDownMenu_SetText(ICT.frame.playerDropdown, player:getName())
end

function DropdownOptions:createPlayer()
    local playerDropdown = DDM:Create_UIDropDownMenu("ICTPlayerSelection", ICT.frame)
    ICT.frame.playerDropdown = playerDropdown
    playerDropdown:SetPoint("TOP", ICT.frame, 0, -30)
    playerDropdown:SetAlpha(1)
    playerDropdown:SetIgnoreParentAlpha(true)
    -- Width set to slightly smaller than parent frame.
    DDM:UIDropDownMenu_SetWidth(playerDropdown, 160)

    DDM:UIDropDownMenu_Initialize(
        playerDropdown,
        function()
            local info = DDM:UIDropDownMenu_CreateInfo()
            for _, player in ICT:nspairsByValue(ICT.db.players, Player.isPlayerEnabled) do
                info.text = player:getNameWithIcon()
                info.value = player:getFullName()
                info.checked = ICT.selectedPlayer == player:getFullName()
                info.func = function(self)
                    ICT.selectedPlayer = self.value
                    DDM:UIDropDownMenu_SetText(playerDropdown, player:getName())
                    UI:PrintPlayers()
                end
                DDM:UIDropDownMenu_AddButton(info)
            end
        end
    )
    Options.flipPlayerDropdown()
end