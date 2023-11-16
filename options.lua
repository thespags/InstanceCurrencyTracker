local addOnName, ICT = ...

local DDM = LibStub("LibUIDropDownMenu-4.0")
local L = LibStub("AceLocale-3.0"):GetLocale("InstanceCurrencyTracker");
local LibTradeSkillRecipes = LibStub("LibTradeSkillRecipes-1")
ICT.Options = {}
local UI = ICT.UI
local Options = ICT.Options
local Instances = ICT.Instances
local Player = ICT.Player

local playerOptions = {
    { name = L["Show Level"], key = "showLevel", },
    { name = L["Show Guild"], key = "showGuild", },
    { name = L["Show Guild Rank"], key = "showGuildRank", },
    { name = L["Show Gold"], key = "showMoney", },
    { name = L["Show Durability"], key = "showDurability", },
    { name = L["Show XP"], key = "showXP", },
    { name = L["Show Rested XP"], key = "showRestedXP", },
    { name = L["Show Resting State"], key = "showRestedState", },
    { name = L["Show Bags"], key = "showBags", },
    { name = L["Show Bank Bags"], key = "showBankBags", },
    { name = L["Show Specs"], key = "showSpecs", },
    { name = L["Show Gear Scores"], key = "showGearScores", tooltip = "If TacoTip is available, this will display gear scores for each spec respectively.", },
    { name = L["Show Professions"], key = "showProfessions", },
    { name = L["Show Cooldowns"], key = "showCooldowns", },
}

local gearOptions = {
    { name = L["Show Specs"], key = "showSpecs", },
    { name = L["Show Gear Scores"], key = "showGearScores", tooltip = "If TacoTip is available, this will display gear scores for each spec respectively.", },
}

local professionOptions = {
    { name = L["Sort By Difficulty"], key = "sortByDifficulty", defaultFalse=true, },
    { name = L["Show Unknown"], key = "showUnknown", defaultFalse=true, },
}
for i, name in ICT:rspairs(ICT.Expansions) do
    tinsert(professionOptions, { name = name, key = "showExpansion" .. i, defaultFalse = i ~= ICT.WOTLK, })
end
for i, profession in ICT:spairsByValue(LibTradeSkillRecipes:GetSkillLines(),
    -- For whatever reason in Spanish the list may be nil, it's not clear to me why so quick fix it to work but adding nil checks.
    function(a, b) if not a then return false end if not b then return true end return a.isSecondary == b.isSecondary and L[a.name] < L[b.name] or b.isSecondary end,
    function(v) return v.hasRecipes end) do
    tinsert(professionOptions, { name = L[profession.name], key = "showProfession" .. i, defaultFalse = profession.isSecondary })
end

local messageOptions = {
    { name = L["Send Group Messages"], key = "group", tooltip = L["SendGroupMessagesTooltip"] },
    { name = L["Send LFG Messages"], key = "lfg", tooltip = L["SendLFGMessagesTooltip"] },
}

local questOptions = {
    { name = L["Hide Unavailable Quests"], key = "hideUnavailable"},
    { name = L["Show Quests"], key = "show", },
    { name = L["Show Fishing Daily"], key = "Fishing Daily", }
}

function Options.minimap()
    ICT.db.minimap.hide = not ICT.db.options.frame.showMinimapIcon
    Options:FlipMinimapIcon()
end

local frameOptions = {
    { name = L["Anchor to LFG"], key = "anchorLFG", tooltip = L["AnchorToLFGTooltip"], },
    { name = L["Show Minimap Icon"], key = "showMinimapIcon", func = Options.minimap },
    { name = L["Order Lock Last"], key = "orderLockLast", defaultFalse = true, tooltip = L["OrderLockLastTooltip"], },
    { name = L["Verbose Currency Tooltip"], key = "verboseCurrencyTooltip", tooltip = L["VerboseCurrencyTooltipTooltip"], },
    { name = L["Show Realm Name"], key = "verboseName", defaultFalse = true, tooltip = L["ShowRealmNameTooltip"], },
}

function Options:setDefaultOptions(override)
    local options = ICT.db.options
    -- If override then always put, otherwise only put if the value is "nil" i.e. absent.
    -- We traverse each table because we may add new entries that should be defaulted on
    -- even though the table was created.
    local put = override and ICT.put or ICT.putIfAbsent
    put(options, "multiPlayerView", true)

    -- Display heroism and lower by default. (i.e. recent currency as new ones are added to the front of the table).
    if not options.currency or override then
        options.currency = {}
    end

    put(options, "currency", {})
    for _, v in ipairs(ICT.Currencies) do
        put(options.currency, v.id, v <= ICT.Heroism)
    end

    -- Set all WOTLK instances on by default.
    put(options, "displayInstances", {})
    for k, _ in pairs(ICT.Expansions) do
        put(options["displayInstances"], k, {})
    end
    for _, v in pairs(Instances.infos()) do
        put(options.displayInstances[v.expansion], v.id, v:fromExpansion(ICT.WOTLK))
    end

    -- Set all WOTLK cooldowns on by default
    put(options, "displayCooldowns", {})
    for k, v in pairs(ICT.Cooldowns) do
        put(options.displayCooldowns, k, v:fromExpansion(ICT.WOTLK))
    end

    -- Set daily and weekly resets on by default.
    put(options, "rest", { [1] = true, [3] = false, [5] = false, [7] = true })

    put(options, "pets", {})
    for fullName, _ in pairs(ICT.db.players) do
        put(options.pets, fullName, {})
    end

    local function setDefaults(t, key)
        put(options, key, {})
        for _, v in pairs(t) do
            put(options[key], v.key, not v.defaultFalse)
        end
    end
    setDefaults(playerOptions, "player")
    setDefaults(gearOptions, "gear")
    setDefaults(professionOptions, "professions")
    setDefaults(messageOptions, "messages")
    setDefaults(frameOptions, "frame")
    setDefaults(questOptions, "quests")

    put(options, "comms", {})
    put(options.comms, "players", {})
end

function Options:FlipMinimapIcon()
    if ICT.db.options.frame.showMinimapIcon then
        ICT.LDBIcon:Show(addOnName)
    else
        ICT.LDBIcon:Hide(addOnName)
    end
end

function Options:FlipOptionsMenu()
    if ICT.db.options.multiPlayerView then
        ICT.frame.playerDropdown:Hide()
    else
        ICT.frame.playerDropdown:Show()
    end
end

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

local function addObjectsOption(name, objects, level, filter)
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

function Options:CreateOptionDropdown()
    local dropdown = DDM:Create_UIDropDownMenu("ICTOptions", ICT.frame)
    ICT.frame.options = dropdown
    dropdown:SetPoint("TOPRIGHT", ICT.frame, "BOTTOMRIGHT", 0, 2)
    dropdown:SetAlpha(1)
    dropdown:SetIgnoreParentAlpha(true)

    -- Width set to slightly smaller than parent frame.
    DDM:UIDropDownMenu_SetWidth(dropdown, 80)
    DDM:UIDropDownMenu_SetText(dropdown, L["Options"])
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
                multiPlayerView.tooltipText = L["Multi Character View Tooltip"]
                multiPlayerView.func = function(self)
                    options.multiPlayerView = not options.multiPlayerView
                    Options:FlipOptionsMenu()
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
                addMenuOption(L["Quests"], ICT.db.options.quests, level)
                addObjectsOption(L["Currency"], ICT.Currencies, level)
                addObjectsOption(L["Cooldowns"], ICT.Cooldowns, level)
                addAllPlayerOptions(L["Pets"], Player.getPets, level)

                DDM:UIDropDownMenu_AddSeparator()
                addMenuOption("      " .. L["Frame"], ICT.db.options.frame, level)
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
                    addOptions(questOptions, "quests", level)
                elseif menuList == L["Currency"] then
                    for _, v in ipairs(ICT.Currencies) do
                        addObjectOption(v, level)
                    end
                elseif menuList == L["Cooldowns"] then
                    addExpansionOptions(ICT.Cooldowns, menuList, level)
                elseif menuList == L["Pets"] then
                    addPlayerOptions(Player.getPets, menuList, level)
                elseif menuList == "      " .. L["Frame"] then
                    addOptions(frameOptions, "frame", level)
                elseif menuList == L["Character Info"] then
                    addOptions(playerOptions, "player", level)
                elseif menuList == L["Gear Info"] then
                    addOptions(gearOptions, "gear", level)
                elseif menuList == L["Professions"] then
                    addOptions(professionOptions, "professions", level)
                elseif menuList == L["Messages"] then
                    addOptions(messageOptions, "messages", level)
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

function Options:PrintMessage(text)
    if IsInGroup() and ICT.db.options.messages.group then
        local type = IsInRaid() and "RAID" or "PARTY"
        SendChatMessage(text, type)
    else
        print(text)
    end
end

function Options:SetPlayerDropDown(player)
    DDM:UIDropDownMenu_SetText(ICT.frame.playerDropdown, player:getName())
end

function Options:CreatePlayerDropdown()
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
    Options:FlipOptionsMenu()
end