local addOnName, ICT = ...

local LDBIcon = LibStub("LibDBIcon-1.0")
local L = LibStub("AceLocale-3.0"):GetLocale("AltAnon")
local LibTradeSkillRecipes = LibStub("LibTradeSkillRecipes-1")
local Expansion = ICT.Expansion
local Instances = ICT.Instances
local Options = {}
ICT.Options = Options

Options.player = {
    { name = L["Show Level"], key = "showLevel", },
    { name = L["Show Guild"], key = "showGuild", },
    { name = L["Show Guild Rank"], key = "showGuildRank", },
    { name = L["Show Gold"], key = "showMoney", },
    { name = L["Show Durability"], key = "showDurability", },
    { name = L["Show XP"], key = "showXP", },
    { name = L["Show Rested XP"], key = "showRestedXP", },
    { name = L["Show Resting State"], key = "showRestedState", },
    { name = L["Show World Buffs"], key = "showWorldBuffs", predicate = Expansion.isVanilla, },
    { name = L["Show Bags"], key = "showBags", },
    { name = L["Show Bank Bags"], key = "showBankBags", },
    { name = L["Show Specs"], key = "showSpecs", },
    { name = L["Show Gear Scores"], key = "showGearScores", tooltip = L["ShowGearScoresTooltip"], },
    { name = L["Show Professions"], key = "showProfessions", },
    { name = L["Show Cooldowns"], key = "showCooldowns", },
}

Options.gear = {
    { name = L["Show Specs"], key = "showSpecs", },
    { name = L["Show Gear Scores"], key = "showGearScores", tooltip = L["ShowGearScoresTooltip"], },
}

Options.professions = {
    { name = L["Show Unknown"], key = "showUnknown", defaultFalse = true, },
}
for i, name in ICT:rspairs(ICT.Expansions) do
    -- Don't show expansions if there's only one.
    if ICT.Vanilla < Expansion.value and Expansion.active(i) then
        tinsert(Options.professions, { name = name, key = "showExpansion" .. i, defaultFalse = not Expansion.current(i), })
    end
end
for i, profession in ICT:spairsByValue(LibTradeSkillRecipes:GetSkillLines(),
    -- For whatever reason in Spanish the list may be nil, it's not clear to me why so quick fix it to work by adding nil checks.
    function(a, b)
        if a and b then
            return a.isSecondary == b.isSecondary and L[a.name] < L[b.name] or b.isSecondary
        end
        return not b
    end,
    function(v) return v.hasRecipes end) do
    tinsert(Options.professions, { name = L[profession.name], key = "showProfession" .. i, defaultFalse = profession.isSecondary })
end

Options.quests = {
    { name = L["Hide Unavailable Quests"], key = "hideUnavailable", },
    { name = L["Show Quests"], key = "show", },
}

for k, v in pairs(ICT.Quests) do
    if ICT:size(v.currencies) == 0 then
        tinsert(Options.quests, { name = L["Show " .. k], key = k})
    end
end

function Options.flipPlayerDropdown()
    if ICT.db.options.frame.multiPlayerView then
        ICT.frame.playerDropdown:Hide()
    else
        ICT.frame.playerDropdown:Show()
    end
end

function Options.minimap()
    ICT.db.minimap.hide = not ICT.db.options.frame.showMinimapIcon
    Options:FlipMinimapIcon()
end

Options.frame = {
    { name = L["Multi Character View"], key = "multiPlayerView", tooltip = L["MultiCharacterViewTooltip"], func = Options.flipPlayerDropdown },
    { name = L["Anchor to LFG"], key = "anchorLFG", tooltip = L["AnchorToLFGTooltip"], },
    { name = L["Show Minimap Icon"], key = "showMinimapIcon", tooltip = L["ShowMinimapIconTooltip"], func = Options.minimap },
    { name = L["Verbose Currency Tooltip"], key = "verboseCurrencyTooltip", tooltip = L["VerboseCurrencyTooltipTooltip"], },
    { name = L["Show Realm Name"], key = "verboseName", defaultFalse = true, tooltip = L["ShowRealmNameTooltip"], },
}

Options.sort = {
    { name = L["Custom Order"], key = "custom", tooltip = L["CustomOrderTooltip"], defaultFalse = true, skipped = true, },
    { name = L["Current Player First"], key = "currentFirst", tooltip = L["CurrentPlayerFirstTooltip"], defaultFalse = true, },
    { name = L["Order Lock Last"], key = "orderLockLast", tooltip = L["OrderLockLastTooltip"], defaultFalse = true, },
    { name = L["Order By Difficulty"], key = "orderByDifficulty", tooltip = L["OrderByDifficultyTooltip"], defaultFalse = true, },
}

Options.playerFilters = {
    { name = L["Same Account"], key = "sameBNet", defaultFalse = true, },
    { name = L["Same Realm"], key = "sameRealm", defaultFalse = true, },
    { name = L["Same Faction"], key = "sameFaction", defaultFalse = true },
    { name = L["Same Class"], key = "sameClass", defaultFalse = true, },
    { name = L["Same Guild"], key = "sameGuild", defaultFalse = true, },
}

function Options:setDefaultOptions(override)
    local options = ICT.db.options
    -- If override then always put, otherwise only put if the value is "nil" i.e. absent.
    -- We traverse each table because we may add new entries that should be defaulted on
    -- even though the table was created.
    local put = override and ICT.put or ICT.putIfAbsent
    put(options, "multiPlayerView", true)

    if not options.currency or override then
        options.currency = {}
    end

    put(options, "currency", {})
    for _, v in ipairs(ICT.Currencies) do
        put(options.currency, v.id, v <= ICT.HonorPoints)
    end

    -- Set all current expansion's instances on by default.
    put(options, "displayInstances", {})
    for k, _ in pairs(ICT.Expansions) do
        put(options["displayInstances"], k, {})
    end
    for _, v in pairs(Instances.infos()) do
        put(options.displayInstances[v.expansion], v.id, v:fromExpansion(Expansion.value))
    end

    -- Set all current expansion's cooldowns on by default
    put(options, "displayCooldowns", {})
    for k, v in pairs(ICT.Cooldowns) do
        put(options.displayCooldowns, k, v:fromExpansion(Expansion.value))
    end

    -- All resets on by default but we don't display unknown tickers.
    put(options, "reset", { [1] = true, [3] = true, [5] = true, [7] = true })

    put(options, "pets", {})
    for fullName, _ in pairs(ICT.db.players) do
        put(options.pets, fullName, {})
    end

    local function setDefaults(key)
        put(options, key, {})
        for _, v in pairs(self[key]) do
            -- Add the option if it always exists or predicated to exist, e.g. available for this wow version.
            -- Otherwise remove it.
            if not v.predicate or v.predicate() then
                put(options[key], v.key, not v.defaultFalse)
            else
                options[key][v.key] = nil
            end
        end
    end
    setDefaults("player")
    setDefaults("gear")
    setDefaults("professions")
    setDefaults("frame")
    setDefaults("quests")
    setDefaults("sort")
    setDefaults("playerFilters")

    put(options, "comms", {})
    put(options.comms, "players", {})
end

function Options:FlipMinimapIcon()
    if ICT.db.options.frame.showMinimapIcon then
        LDBIcon:Show(addOnName)
    else
        LDBIcon:Hide(addOnName)
    end
end
