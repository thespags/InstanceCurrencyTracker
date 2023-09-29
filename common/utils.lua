local addOn, ICT = ...

local L = LibStub("AceLocale-3.0"):GetLocale("InstanceCurrencyTracker");
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

function ICT:isValidSpec(spec)
    return not(spec.tab1 == 0 and spec.tab2 == 0 and spec.tab3 == 0)
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

-- Sorted pairs iterator determined by the table key.
function ICT:spairs(t, comparator, filter)
    local keys = {}
    for k, _ in pairs(t) do
        if not filter or filter(k) then
            table.insert(keys, k)
        end
    end

    table.sort(keys, comparator)

    local i = 0
    return function()
        i = i + 1
        if keys[i] then
            return keys[i], t[keys[i]]
        end
    end
end

-- Natural sorted pairs iterator.
function ICT:nspairs(t, filter)
    return self:spairs(t, function(a, b) return a < b end, filter)
end

-- Sorted pairs iterator determined by mapping the values.
function ICT:spairsByValue(t, comparator, filter)
    return self:spairs(t, function(a, b) return comparator(t[a], t[b]) end, filter and function(k) return filter(t[k]) end)
end

-- Natural sorted pairs iterator.
function ICT:nspairsByValue(t, filter)
    return self:spairsByValue(t, function(a, b) return a < b end, filter)
end

function ICT.reverseSort(a, b)
    return b < a
end

-- Filtered pairs iterator determined by the table key with the given function.
function ICT:fpairs(t, filter)
    local keys = {}
    for k, _ in pairs(t) do
        if not filter or filter(k) then
            table.insert(keys, k)
        end
    end

    local i = 0
    return function()
        i = i + 1
        if keys[i] then
            return keys[i], t[keys[i]]
        end
    end
end

-- Filtered pairs iterator determined by the table value with the given function.
function ICT:fpairsByValue(t, f)
    return self:fpairs(t, function(k) return f(t[k]) end)
end

-- Sums a list by the values or a function mapping the values to a number.
function ICT:sum(t, op, f)
    local total = 0
    for _, v in pairs(t) do
        if not f or f(v) then
            total = total + (op and op(v) or v)
        end
    end
    return total
end

function ICT:sumNonNilTable(t)
    local count = 0
    for _, v in pairs(t) do
        count = count + (v and 1 or 0)
    end
    return count
end

function ICT:sumNonNil(...)
    return self:sumNonNilTable({...})
end

function ICT:max(t, op, f)
    local max = 0
    for _, v in pairs(t) do
        if not f or f(v) then
            local value = (op and op(v) or v)
            max = value > max and value or max
        end
    end
    return max
end

--- Creates a function adding the result of two functions.
---@generic T : any
---@param left fun(self: T): number
---@param right fun(self: T): number
---@return fun(self: T): number
function ICT:add(left, right)
    return function(v) return left(v) + right(v) end
end

-- Returns a function that simply returns the provided value.
function ICT:ReturnX(x)
    return function(...) return x end
end

function ICT:toTable(pairs)
    local t = {}
    for k, v in pairs do
        t[k] = v
    end
    return t
end

-- Given a non table arguements will make a set, i.e. a table with values true.
function ICT:set(...)
    local t = {}
    for _, v in pairs({...}) do
        t[v] = true
    end
    return t
end

function ICT:size(t, f)
    if t == nil then
        return 0
    end
    local i = 0
    for _, v in pairs(t) do
        if not f or f(v) then
            i = i + 1
        end
    end
    return i
end

-- Returns true if all values or mapped values in the table are true, otherwise false.
---@generic V : any
---@param t table<any, V>
---@param op? fun(self: V): boolean
---@return boolean
function ICT:containsAllValues(t, op)
    for _, v in pairs(t) do
        if op and not op(v) or not op and not v then
            return false
        end
    end
    return true
end

function ICT:containsAnyKey(t, op)
    for k, _ in pairs(t) do
        if op and op(k) or not op and k then
            return true
        end
    end
    return false
end

--- Returns true if any value or mapped value in the table are true, otherwise false.
---@generic V : any
---@param t table<any, V>
---@param op? fun(self: V): boolean
---@return boolean
function ICT:containsAnyValue(t, op)
    for _, v in pairs(t) do
        if op and op(v) or not op and v then
            return true
        end
    end
    return false
end

function ICT:putIfAbsent(t, key, value)
    t[key] = t[key] == nil and value or t[key]
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

function ICT:dprint(text)
    if false then
        print(text)
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
ICT.throttles = {}
-- Aggregates calls, f, within a certain time span.
-- callback is called after f for any post processing, e.g. update the display.
-- source is simply a debug tool.
function ICT:throttleFunction(source, time, f, callback)
    return function()
        -- Skip calling if the database/addon isn't initialized.
        -- We set init in the addon initialization event.
        ICT:dprint(source)
        if ICT.db and ICT.init then
            local player = ICT.GetPlayer()
            if time > 0 and not ICT.throttles[f] then
                ICT.throttles[f] = true
                C_Timer.After(time, function()
                    f(player)
                    callback()
                    ICT.throttles[f] = false;
                end)
            elseif time <= 0 or not throttle then
                f(player)
                callback()
            end
        end
    end
end

function ICT:fWith(f, v1)
    return function(v) return f(v, v1) end
end

--- Creates a function that negates the provided function.
---@generic T : any
---@param f fun(self: T): boolean
---@return fun(self: T): boolean
function ICT:fNot(f)
    return function(v) return not f(v) end
end


--- Creates a function that and's two functions together with the same input.
---@generic T : any
---@param f fun(self: T): boolean
---@param g fun(self: T): boolean
---@return fun(self: T): boolean
function ICT:fAnd(f, g)
    return function(v) return f(v) and g(v) end
end