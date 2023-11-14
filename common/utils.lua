local addOn, ICT = ...

local L = LibStub("AceLocale-3.0"):GetLocale("InstanceCurrencyTracker");
local log = ICT.log
ICT.MaxLevel = 80
ICT.ClassIcons = {
    ["WARRIOR"] = 626008,
    ["PALADIN"] = 626003,
    ["HUNTER"] = 626000,
    ["ROGUE"] = 626005,
    ["PRIEST"] = 626004,
    ["DEATHKNIGHT"] = 135771,
    ["SHAMAN"] = 626006,
    ["MAGE"] = 626001,
    ["WARLOCK"] = 626007,
    ["DRUID"] = 625999
}

function ICT:linkSplit(link, name)
    if not link then
        return {}
    end
    local subLink = string.match(link, name .. ":([%-%w:]+)")
    local t = {}
    local i = 0
    for v in string.gmatch(subLink, "([%-%w]*):?") do
        i = i + 1
        t[i] =  v ~= "" and v or nil
    end
    return t
end

function ICT:itemLinkSplit(link)
    return ICT:linkSplit(link, "item")
end

function ICT:tradeLinkSplit(link)
    return ICT:linkSplit(link, "trade")
end

function ICT:enchantLinkSplit(link)
    return ICT:linkSplit(link, "enchant")
end

function ICT:getColoredSpellLink(spellId, color)
    local name = select(1, GetSpellInfo(spellId))
    return name and string.format("|c%s|Henchant:%s|h[%s]|h|r", color, spellId, name)
end

function ICT:getSpellLink(spellId)
    -- Remap glyph of vampiric blood because Blizard has the worng one.
    if spellId == 58676 then
        spellId = 58726
    end
    local link = select(1, GetSpellLink(spellId))
    if not link then
        local name = select(1, GetSpellInfo(spellId))
        link = name and string.format("|c%s|Henchant:%s|h[%s]|h|r", "FF71d5FF", spellId, name)
    end
    return link
end

function ICT:castTradeSkill(player, skillLine, expectedName)
    for _, p in pairs(player.professions or {}) do
        if p.skillLine == skillLine and p.spellId then
            CastSpellByID(p.spellId)
            for i = 1, GetNumTradeSkills() do
                local name, difficulty = GetTradeSkillInfo(i)
                if name == expectedName then
                    DoTradeSkill(i)
                    CloseTradeSkill()
                    return
                elseif difficulty == "header" then
                    -- Forces expands so we can find all trades.
                    ExpandTradeSkillSubClass(i)
                end
            end
            CloseTradeSkill()
        end
    end
    ICT:print(L["No skill found: %s"], expectedName)
end

-- Helper function when debugging.
function ICT:printValues(t)
    if not t then
        print("nil")
        return
    end
    for k, v in pairs(t) do
        print(string.format("%s %s", k, tostring(v)))
    end
end

--- Prints the string with our prefix and color.
---@param text string
---@param ... string
function ICT:print(text, ...)
    text = string.format(text, ...)
    print(string.format("|c%s[ICT] %s|r", ICT.textColor, text))
end

--- Prints the string if the option is set to print.
---@param text string
---@param key string
---@param ... string
function ICT:oprint(text, key, ...)
    if ICT.db.options.messages[key] then
        self:print(text, ...)
    end
end

local throttle = true
local throttles = {}
-- Aggregates calls, f, within a certain time span.
-- callback is called after f for any post processing, e.g. update the display.
-- source is simply a debug tool.
function ICT:throttleFunction(source, time, f, callback)
    return function()
        -- Skip calling if the database/addon isn't initialized.
        -- We set init in the addon initialization event.
        log.debug(source)
        if ICT.db and ICT.init then
            local player = ICT.Players:get()
            if time > 0 and not throttles[f] then
                throttles[f] = true
                C_Timer.After(time, function()
                    f(player)
                    callback()
                    throttles[f] = false;
                end)
            elseif time <= 0 or not throttle then
                f(player)
                callback()
            end
        end
    end
end