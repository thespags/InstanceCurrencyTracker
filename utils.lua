Utils = {}
-- Currency Id's with name helpers.
Utils.Heroism = 101
Utils.Valor = 102
Utils.Conquest = 221
Utils.Triumph = 301
Utils.SiderealEssence = 2589
Utils.ChampionsSeal = 241
-- Phase 3 dungeons grant conquest.
Utils.DungeonEmblem = Utils.Conquest
CLASS_ICONS = {
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

function Utils:GetInstanceName(name, size)
    return string.format("%s (%s)", name, size)
end

function Utils:GetFullName()
    return string.format("[%s] %s", GetRealmName(), UnitName("Player"))
end

-- Returns the amount of currency the player has for the currency provided.
function Utils:GetCurrencyAmount(id)
    return select(2, GetCurrencyInfo(id))
end

-- Returns the localized name of the currency provided.
function Utils:GetCurrencyName(id)
    return select(1, GetCurrencyInfo(id))
end

function Utils:LocalizeInstanceName(v)
    local name = GetRealZoneText(v.id)
    v.name = v.maxPlayers and string.format("%s (%s)", name, v.maxPlayers) or name
end

-- Sorted pairs iterator determined by the table key.
function Utils:spairs(t, comparator, filter)
    local keys = {}
    for k, v in pairs(t) do
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

-- Sorted pairs iterator determined by mapping the values.
function Utils:spairsByValue(t, comparator, filter)
    return self:spairs(t, function(a, b) return comparator(t[a], t[b]) end, filter)
end

-- Filtered pairs iterator determined by the table key with the given function.
function fpairs(t, f)
    local k, v
    return function()
        repeat
            k, v = next(t, k)
        until not k or f(k)
        return k, v
    end
end

-- Filtered pairs iterator determined by the table value with the given function.
function fpairsByValue(t, f)
    return fpairs(t, function(k) return f(t[k]) end)
end

-- Sums a list by the values or a function mapping the values to a number.
function Utils:sum(t, op, f)
    local total = 0
    for _, v in pairs(t) do
        if not f or f(v) then
            total = total + (op and op(v) or v)
        end
    end
    return total
end

function Utils:add(left, right)
    return function(v) return left(v) + right(v) end
end

function Utils:hex2rgb(hex)
    return tonumber("0x"..hex:sub(3,4)), tonumber("0x"..hex:sub(5,6)), tonumber("0x"..hex:sub(7,8))
end

-- Returns a function that simply returns the provided value.
function ReturnX(x)
    return function(...) return x end
end

-- Given a non table arguements will make a set, i.e. a table with values true.
function Utils:set(...)
    local t = {}
    for _, v in pairs({...}) do
        t[v] = true
    end
    return t
end

-- Returns true if all keys or mapped values in the table are true, otherwise false.
function Utils:containsAllKeys(t, op)
    for k, _ in pairs(t) do
        if op and not op(k) or not op and not k then
            return false
        end
    end
    return true
end

-- Returns true if all values or mapped values in the table are true, otherwise false.
function Utils:containsAllValues(t, op)
    return self:containsAllKeys(t, function(k) return op and op(t[k]) or not op and t[k] end)
end

-- Returns true if any key or mapped value in the table are true, otherwise false.
function Utils:containsAnyKey(t, op)
    for k, _ in pairs(t) do
        if op and op(k) or not op and k then
            return true
        end
    end
    return false
end

-- Returns true if any value or mapped value in the table are true, otherwise false.
function Utils:containsAnyValue(t, op)
    return self:containsAnyKey(t, function(k) return op and op(t[k]) or not op and t[k] end)
end

function Utils:putIfAbsent(t, key, value)
    if not t[key] then
        t[key] = value
    end
end

function Utils:printKeys(t)
    for k, _ in pairs(t) do
        print(k)
    end
end