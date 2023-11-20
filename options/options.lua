local addOnName, ICT = ...

local DDM = LibStub("LibUIDropDownMenu-4.0")
local L = LibStub("AceLocale-3.0"):GetLocale("InstanceCurrencyTracker")
local LibTradeSkillRecipes = LibStub("LibTradeSkillRecipes-1")
ICT.Options = {}
local UI = ICT.UI
local Options = ICT.Options
local Instances = ICT.Instances
local Player = ICT.Player

Options.player = {
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

Options.gear = {
    { name = L["Show Specs"], key = "showSpecs", },
    { name = L["Show Gear Scores"], key = "showGearScores", tooltip = "If TacoTip is available, this will display gear scores for each spec respectively.", },
}

Options.professions = {
    { name = L["Sort By Difficulty"], key = "sortByDifficulty", defaultFalse=true, },
    { name = L["Show Unknown"], key = "showUnknown", defaultFalse=true, },
}
for i, name in ICT:rspairs(ICT.Expansions) do
    tinsert(Options.professions, { name = name, key = "showExpansion" .. i, defaultFalse = i ~= ICT.WOTLK, })
end
for i, profession in ICT:spairsByValue(LibTradeSkillRecipes:GetSkillLines(),
    -- For whatever reason in Spanish the list may be nil, it's not clear to me why so quick fix it to work but adding nil checks.
    function(a, b) if not a then return false end if not b then return true end return a.isSecondary == b.isSecondary and L[a.name] < L[b.name] or b.isSecondary end,
    function(v) return v.hasRecipes end) do
    tinsert(Options.professions, { name = L[profession.name], key = "showProfession" .. i, defaultFalse = profession.isSecondary })
end

Options.messages = {
    { name = L["Send Group Messages"], key = "group", tooltip = L["SendGroupMessagesTooltip"] },
}

Options.quests = {
    { name = L["Hide Unavailable Quests"], key = "hideUnavailable"},
    { name = L["Show Quests"], key = "show", },
    { name = L["Show Fishing Daily"], key = "Fishing Daily", }
}

function Options.minimap()
    ICT.db.minimap.hide = not ICT.db.options.frame.showMinimapIcon
    Options:FlipMinimapIcon()
end

Options.frame = {
    { name = L["Anchor to LFG"], key = "anchorLFG", tooltip = L["AnchorToLFGTooltip"], },
    { name = L["Show Minimap Icon"], key = "showMinimapIcon", tooltip = L["ShowMinimapIconTooltip"], func = Options.minimap },
    { name = L["Verbose Currency Tooltip"], key = "verboseCurrencyTooltip", tooltip = L["VerboseCurrencyTooltipTooltip"], },
    { name = L["Show Realm Name"], key = "verboseName", defaultFalse = true, tooltip = L["ShowRealmNameTooltip"], },
}

Options.sort = {
    { name = L["Custom Order"], key = "custom", tooltip = L["CustomOrderTooltip"], defaultFalse = true, skipped = true, },
    { name = L["Current Player First"], key = "currentFirst", tooltip = L["CurrentPlayerFirstTooltip"], defaultFalse = true, },
    { name = L["Order Lock Last"], key = "orderLockLast", tooltip = L["OrderLockLastTooltip"], defaultFalse = true, },
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
    setDefaults(self.player, "player")
    setDefaults(self.gear, "gear")
    setDefaults(self.professions, "professions")
    setDefaults(self.messages, "messages")
    setDefaults(self.frame, "frame")
    setDefaults(self.quests, "quests")
    setDefaults(self.sort, "sort")

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

function Options:PrintMessage(text)
    if IsInGroup() and ICT.db.options.messages.group then
        local type = IsInRaid() and "RAID" or "PARTY"
        SendChatMessage(text, type)
    else
        print(text)
    end
end
