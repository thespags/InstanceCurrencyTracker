local _, ICT = ...

local DDM = LibStub("LibUIDropDownMenu-4.0")
local L = LibStub("AceLocale-3.0"):GetLocale("AltAnon")
local Instances = ICT.Instances
local Options = ICT.Options
local Player = ICT.Player
local Tooltips = ICT.Tooltips
local UI = ICT.UI
local DisplayOptions = {}
ICT.DisplayOptions = DisplayOptions

local fontSize = 26
local scrollWidth = 170
local scrollHeight = fontSize
local ReturnTrue = ICT:returnX(true)

local function objectsSelected(objects, filter)
    filter = filter or ReturnTrue
    local contains = function(v) return filter(v) and v:isVisible() end
    return function() return ICT:containsAllValues(objects, contains) end
end

local function flipObjects(objects, filter)
    filter = filter or ReturnTrue
    local contains = function(v) return filter(v) and v:isVisible() end
    return function()
        local wasChecked = ICT:containsAllValues(objects, contains)
        for _, o in ICT:fpairsByValue(objects, filter) do
            o:setVisible(not wasChecked)
        end
        UI:PrintPlayers()
    end
end

local function optionsSelected(options)
    return function() return ICT:containsAllValues(options) end
end

local function flipOptions(options)
    return function()
        local wasChecked = ICT:containsAllValues(options)
        for k, _ in pairs(options) do
            options[k] = not wasChecked
        end
        UI:PrintPlayers()
    end
end

function DisplayOptions:addDropdown(cell, dropdown)
    local frame = DDM:Create_UIDropDownMenu(nil, cell.frame)
    frame:SetPoint("TOPRIGHT", cell.frame, "TOPRIGHT")
    DDM:UIDropDownMenu_SetWidth(frame, 90)
    DDM:UIDropDownMenu_SetText(frame, dropdown.name)
    DDM:UIDropDownMenu_Initialize(frame, dropdown.func)
    _ = dropdown.tooltip and dropdown.tooltip:attachFrame(frame)
    if dropdown.flip then
        local button = cell:attachCheckButton("ICT" .. dropdown.name .. "FlipOptions")
        _ = dropdown.isChecked and button:SetChecked(dropdown.isChecked())
        button:SetScript("OnClick", dropdown.flip)
    end
end


function DisplayOptions:addDropdowns(parent)
    local frame = CreateFrame("Frame", "ICTOptionsDisplay", parent, "BackdropTemplate")
    frame:SetSize(scrollWidth, 100)
    frame:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, -30)
    local cells = ICT.Cells:new(frame, fontSize, scrollWidth, scrollHeight)
    local y = 1
    local x = 1
    Tooltips:info(parent, L["Flip Options"], L["Flip Options Tooltip"])
    :SetPoint("TOPLEFT", parent, "TOPLEFT", 3, -3)
    for _, dropdown in pairs(self.dropdowns) do
        local filter = dropdown.filter or ReturnTrue
        if filter() then
            self:addDropdown(cells(x, y), dropdown)
            y = y + 1
        end
        if y > 5 then
            x = x + 1
            y = 1
        end
    end
end

function DisplayOptions:init(parent)
    self.frame = CreateFrame("Frame", "ICTOptionsMainTab", parent)
    self.frame:SetAllPoints(parent)
    self.dropdowns = {
        {
            name = L["Characters"] ,
            func = function(_, level, _)
                for _, player in ICT:nspairsByValue(ICT.db.players, Player.isLevelVisible) do
                    ICT.DropdownOptions:addObjectOption(player, level)
                end
            end,
            tooltip = Tooltips:new(L["Characters"], L["Characters Tooltip"]),
            flip = flipObjects(ICT.db.players, Player.isLevelVisible),
            isChecked = objectsSelected(ICT.db.players, Player.isLevelVisible),
        },
        {
            name = L["Character Info"],
            func = function(_, level, _)
                ICT.DropdownOptions:addOptions(Options.player, "player", level)
            end,
            tooltip = Tooltips:new(L["Character Info"], L["Character Info Tooltip"]),
            flip = flipOptions(ICT.db.options.player),
            isChecked = optionsSelected(ICT.db.options.player),
        },
        {
            name =  L["Gear Info"],
            func = function(_, level, _)
                ICT.DropdownOptions:addOptions(Options.gear, "gear", level)
            end,
            tooltip = Tooltips:new(L["Gear Info"], L["Gear Info Tooltip"]),
            flip = flipOptions(ICT.db.options.gear),
            isChecked = optionsSelected(ICT.db.options.gear),
        },
        {
            name = L["Reset Timers"],
            func = function(_, level, _)
                for _, v in ICT:spairs(ICT.Resets) do
                    ICT.DropdownOptions:addObjectOption(v, level)
                end
            end,
            tooltip = Tooltips:new(L["Reset Timers"], L["Reset Timers Tooltip"]),
            flip = flipObjects(ICT.Resets),
            isChecked = objectsSelected(ICT.Resets),
        },
        {
            name = L["Professions"],
            func = function(_, level, _)
                ICT.DropdownOptions:addOptions(Options.professions, "professions", level)
            end,
            tooltip = Tooltips:new(L["Professions"], L["Professions Tooltip"]),
            flip = flipOptions(ICT.db.options.professions),
            isChecked = optionsSelected(ICT.db.options.professions),
        },
        {
            name = L["Instances"],
            func = function(_, level, menuList)
                if Expansion.isVanilla() or level == 2 then
                    local expansion = menuList and tonumber(menuList) or ICT.Vanilla
                    local lastSize
                    for _, v in ICT:spairsByValue(Instances.infos(), ICT.InstanceOptionSort, ICT:fWith(ICT.Instance.fromExpansion, expansion)) do
                        local size = v.legacy == expansion and v.legacySize or v.size
                        if lastSize and lastSize ~= size then
                            DDM:UIDropDownMenu_AddSeparator(level)
                        end
                        lastSize = size
                        ICT.DropdownOptions:addObjectOption(v, level)
                    end
                elseif (level or 1) == 1 then
                    ICT.DropdownOptions:addExpansionOptions(Instances.infos(), level)
                end
            end,
            tooltip = Tooltips:new(L["Instances"], L["Instances Tooltip"]),
            flip = flipObjects(Instances.infos()),
            isChecked = objectsSelected(Instances.infos()),
        },
        {
            name = L["Quests"],
            func = function(_, level, _)
                ICT.DropdownOptions:addOptions(Options.quests, "quests", level)
            end,
            tooltip = Tooltips:new(L["Quests"], L["Quests Tooltip"]),
            flip = flipOptions(ICT.db.options.quests),
            isChecked = optionsSelected(ICT.db.options.quests),
        },
        {
            name = L["Currency"],
            func = function(_, level, _)
                for _, v in ipairs(ICT.Currencies) do
                    ICT.DropdownOptions:addObjectOption(v, level)
                end
            end,
            filter = function() return ICT:size(ICT.Currencies) > 0 end,
            tooltip = Tooltips:new(L["Currency"], L["Cooldowns Tooltip"]),
            flip = flipObjects(ICT.Currencies),
            isChecked = objectsSelected(ICT.Currencies),
        },
        {
            name = L["Cooldowns"],
            func = function(_, level, menuList)
                if Expansion.isVanilla() or level == 2 then
                    local expansion = menuList and tonumber(menuList) or ICT.Vanilla
                    local lastSkill
                    for _, v in ICT:nspairsByValue(ICT.Cooldowns, ICT:fWith(ICT.Cooldown.fromExpansion, expansion)) do
                        if lastSkill and lastSkill ~= v:getSkillLine() then
                            DDM:UIDropDownMenu_AddSeparator(level)
                        end
                        lastSkill = v:getSkillLine()
                        ICT.DropdownOptions:addObjectOption(v, level)
                    end
                elseif (level or 1) == 1 then
                    ICT.DropdownOptions:addExpansionOptions(ICT.Cooldowns, level)
                end
            end,
            tooltip = Tooltips:new(L["Cooldowns"], L["Cooldowns Tooltip"]),
            flip = flipObjects(ICT.Cooldowns),
            isChecked = objectsSelected(ICT.Cooldowns),
        },
        {
            name = L["Pets"],
            func = function(_, level, menuList)
                if (level or 1) == 1 then
                    ICT.DropdownOptions:addPlayerOptions(Player.getPets, menuList, level)
                elseif level == 2 then
                    local fullName = menuList
                    for _, v in ICT:nspairsByValue(ICT.db.players[fullName]:getPets()) do
                        ICT.DropdownOptions:addObjectOption(v, level)
                    end
                end
            end,
            tooltip = Tooltips:new(L["Pets"], L["Pets Tooltip"])
        }
    }
    self:addDropdowns(self.frame)
end

function DisplayOptions:prePrint()
    self.linkList()
    self.sortList()
end

function DisplayOptions:hide()
    self.frame:Hide()
end

function DisplayOptions:show()
    self.frame:Show()
end