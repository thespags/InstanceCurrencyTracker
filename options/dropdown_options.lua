local addOnName, ICT = ...

local DDM = LibStub("LibUIDropDownMenu-4.0")
local L = LibStub("AceLocale-3.0"):GetLocale("InstanceCurrencyTracker")
local Instances = ICT.Instances
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

local function addPlayerOptions(func, menuList, level)
    for _, player in ICT:nspairsByValue(ICT.db.players, Player.isVisible) do
        if ICT:size(func(player)) > 0 then
            local info = createInfo(player:getName())
            info.checked = ICT:containsAllValues(func(player), isVisible)
            info.menuList = menuList .. ":" .. player:getFullName()
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

local function addObjectOption(o, level)
    local info = createInfo(o:getName())
    info.checked = o:isVisible()
    info.value = o.getFullName and o:getFullName() or o:getName()
    info.func = function(self)
        o:setVisible(not o:isVisible())
        UI:PrintPlayers()
    end
    DDM:UIDropDownMenu_AddButton(info, level)
end

local function addExpansionOptions(objects, menuList, level)
    for expansion, name in ICT:rspairs(ICT.Expansions) do
        if expansion <= ICT.Expansion then
            local info = createInfo(name)
            local contains = function(v)
                -- v is visible or it's not from that expansion.
                return v:isVisible() or not v:fromExpansion(expansion)
            end
            info.checked = ICT:containsAllValues(objects, contains)
            info.menuList = menuList .. ":" .. expansion
            info.hasArrow = true

            info.func = function(self)
                local wasChecked = ICT:containsAllValues(objects, contains)
                for _, o in ICT:fpairsByValue(objects, function(v) return v:fromExpansion(expansion) end ) do
                    o:setVisible(not wasChecked)
                end
                UI:PrintPlayers()
            end
            DDM:UIDropDownMenu_AddButton(info, level)
        end
    end
end

local function addObjectsOption(name, objects, level, filter)
    -- Adding in expansion filters the options may be empty so don't add an empty list.
    if ICT:size(objects) == 0 then
        return
    end
    local info = createInfo(name)
    filter = filter or ICT:returnX(true)
    local contains = function(v) return filter(v) and v:isVisible() end
    info.checked = ICT:containsAllValues(objects, contains)
    info.menuList = info.text
    info.hasArrow = true

    info.func = function(self)
        local wasChecked =  ICT:containsAllValues(objects, contains)
        for _, o in ICT:fpairsByValue(objects, filter) do
            o:setVisible(not wasChecked)
        end
        UI:PrintPlayers()
    end
    DDM:UIDropDownMenu_AddButton(info, level)
end

local function addMenuOption(name, options, level, tooltip)
    -- Adding in expansion filters the options may be empty so don't add an empty list.
    if ICT:size(options) == 0 then
        return
    end
    local info = createInfo(name)
    info.menuList = info.text
    info.checked = ICT:containsAllValues(options)
    info.hasArrow = true
    info.func = function(self)
        local wasChecked = ICT:containsAllValues(options)
        for k, _ in pairs(options) do
            options[k] = not wasChecked
        end
        UI:PrintPlayers()
    end
    if tooltip then
        info.tooltipTitle = info.text
        info.tooltipOnButton = true
        info.tooltipText = tooltip
    end
    DDM:UIDropDownMenu_AddButton(info, level)
end

local function addOptions(options, group, level)
    for _, v in pairs(options) do
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

function DropdownOptions:logLevels(frame)
    local dropdown = DDM:Create_UIDropDownMenu("foobar", frame)
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

function DropdownOptions:create(frame)
    local dropdown = DDM:Create_UIDropDownMenu("ICTOptions", frame)
    dropdown:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 4)

    DDM:UIDropDownMenu_SetWidth(dropdown, 90)
    DDM:UIDropDownMenu_SetText(dropdown, L["Shown Info"])
    local options = ICT.db.options

    DDM:UIDropDownMenu_Initialize(
        dropdown,
        function(self, level, menuList)
            if (level or 1) == 1 then

                -- Switches between a single character and multiple characters to view.
                local multiPlayerView = createInfo(L["Multi Character View"])
                multiPlayerView.checked = options.multiPlayerView
                multiPlayerView.tooltipTitle = multiPlayerView.text
                multiPlayerView.tooltipOnButton = true
                multiPlayerView.tooltipText = L["MultiCharacterViewTooltip"]
                multiPlayerView.func = function(self)
                    options.multiPlayerView = not options.multiPlayerView
                    DropdownOptions:flipPlayerDropdown()
                    UI:PrintPlayers()
                end
                DDM:UIDropDownMenu_AddButton(multiPlayerView)

                addMenuOption(L["Messages"], ICT.db.options.messages, level)
                addMenuOption(L["Character Info"], ICT.db.options.player, level, L["Character Info Toolip"])
                addMenuOption(L["Gear Info"], ICT.db.options.gear, level, L["Gear Info Toolip"])
                addMenuOption(L["Professions"], ICT.db.options.professions, level, L["Professions Toolip"])
                addObjectsOption(L["Characters"], ICT.db.players, level, Player.isLevelVisible)
                addObjectsOption(L["Reset Timers"], ICT.Resets, level)
                addObjectsOption(L["Instances"], Instances.infos(), level)
                if ICT:size(ICT.Quests) > 0 then
                    addMenuOption(L["Quests"], ICT.db.options.quests, level)
                end
                addObjectsOption(L["Currency"], ICT.Currencies, level)
                addObjectsOption(L["Cooldowns"], ICT.Cooldowns, level)
                addAllPlayerOptions(L["Pets"], Player.getPets, level)
            elseif level == 2 then
                if menuList == L["Characters"] then
                    for _, player in ICT:nspairsByValue(ICT.db.players, Player.isLevelVisible) do
                        addObjectOption(player, level)
                    end
                elseif menuList == L["Reset Timers"] then
                    for _, v in ICT:spairs(ICT.Resets) do
                        addObjectOption(v, level)
                    end
                elseif menuList == L["Instances"] then
                    addExpansionOptions(Instances.infos(), menuList, level)
                elseif menuList == L["Quests"] then
                    addOptions(Options.quests, "quests", level)
                elseif menuList == L["Currency"] then
                    for _, v in ipairs(ICT.Currencies) do
                        addObjectOption(v, level)
                    end
                elseif menuList == L["Cooldowns"] then
                    addExpansionOptions(ICT.Cooldowns, menuList, level)
                elseif menuList == L["Pets"] then
                    addPlayerOptions(Player.getPets, menuList, level)
                elseif menuList == L["Character Info"] then
                    addOptions(Options.player, "player", level)
                elseif menuList == L["Gear Info"] then
                    addOptions(Options.gear, "gear", level)
                elseif menuList == L["Professions"] then
                    addOptions(Options.professions, "professions", level)
                elseif menuList == L["Messages"] then
                    addOptions(Options.messages, "messages", level)
                end
            elseif level == 3 then
                -- If we had another 3rd layer thing we need to check if menuList is an expansion.
                -- Now create a level for all the instances of that expansion.
                local subList, filter = menuList:match("([%w%s]+):([%[%]%w%s]+)")
                if subList == L["Instances"] then
                    local expansion = tonumber(filter)
                    local lastSize
                    for _, v in ICT:spairsByValue(Instances.infos(), ICT.InstanceOptionSort, ICT:fWith(ICT.Instance.fromExpansion, expansion)) do
                        local size = v.legacy == expansion and v.legacySize or v.size
                        if lastSize and lastSize ~= size then
                            DDM:UIDropDownMenu_AddSeparator(level)
                        end
                        lastSize = size
                        addObjectOption(v, level)
                    end
                elseif subList == L["Cooldowns"] then
                    local expansion = tonumber(filter)
                    -- Now create a level for all the cooldowns of that expansion.
                    local lastSkill
                    for _, v in ICT:nspairsByValue(ICT.Cooldowns, ICT:fWith(ICT.Cooldown.fromExpansion, expansion)) do
                        if lastSkill and lastSkill ~= v:getSkillLine() then
                            DDM:UIDropDownMenu_AddSeparator(level)
                        end
                        lastSkill = v:getSkillLine()
                        addObjectOption(v, level)
                    end
                elseif subList == L["Pets"] then
                    local fullName = filter
                    for _, v in ICT:nspairsByValue(ICT.db.players[fullName]:getPets()) do
                        addObjectOption(v, level)
                    end
                end
            end
        end
    )
end

function DropdownOptions:flipPlayerDropdown()
    if ICT.db.options.multiPlayerView then
        ICT.frame.playerDropdown:Hide()
    else
        ICT.frame.playerDropdown:Show()
    end
end

function DropdownOptions:setPlayer(player)
    DDM:UIDropDownMenu_SetText(ICT.frame.playerDropdown, player:getName())
end

function DropdownOptions:createPlayer()
    local playerDropdown = DDM:Create_UIDropDownMenu("PlayerSelection", ICT.frame)
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
    self:flipPlayerDropdown()
end