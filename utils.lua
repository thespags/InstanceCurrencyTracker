local addOn, ICT = ...

ICT.MaxLevel = 80
-- Currency Id's with name helpers.
ICT.Heroism = 101
ICT.Valor = 102
ICT.Conquest = 221
ICT.Triumph = 301
ICT.SiderealEssence = 2589
ICT.ChampionsSeal = 241
-- Phase 3 dungeons grant conquest.
ICT.DungeonEmblem = ICT.Conquest
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

function ICT:GetInstanceName(name, size)
    return string.format("%s (%s)", name, size)
end

function ICT:GetFullName()
    return string.format("[%s] %s", GetRealmName(), UnitName("Player"))
end

-- Returns the amount of currency the player has for the currency provided.
function ICT:GetCurrencyAmount(id)
    return select(2, GetCurrencyInfo(id))
end

-- Returns the localized name of the currency provided.
function ICT:GetCurrencyName(id)
    return select(1, GetCurrencyInfo(id))
end

function ICT:LocalizeInstanceName(v)
    local name = GetRealZoneText(v.id)
    v.name = v.maxPlayers and string.format("%s (%s)", name, v.maxPlayers) or name
end

-- Sorted pairs iterator determined by the table key.
function ICT:spairs(t, comparator, filter)
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
function ICT:spairsByValue(t, comparator, filter)
    return self:spairs(t, function(a, b) return comparator(t[a], t[b]) end, filter)
end

-- Filtered pairs iterator determined by the table key with the given function.
function ICT:fpairs(t, f)
    local k, v
    return function()
        repeat
            k, v = next(t, k)
        until not k or f(k)
        return k, v
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

function ICT:add(left, right)
    return function(v) return left(v) + right(v) end
end

function ICT:hex2rgb(hex)
    return tonumber("0x"..hex:sub(3,4)), tonumber("0x"..hex:sub(5,6)), tonumber("0x"..hex:sub(7,8))
end

-- Returns a function that simply returns the provided value.
function ICT:ReturnX(x)
    return function(...) return x end
end

-- Given a non table arguements will make a set, i.e. a table with values true.
function ICT:set(...)
    local t = {}
    for _, v in pairs({...}) do
        t[v] = true
    end
    return t
end

-- Returns true if all keys or mapped values in the table are true, otherwise false.
function ICT:containsAllKeys(t, op)
    for k, _ in pairs(t) do
        if op and not op(k) or not op and not k then
            return false
        end
    end
    return true
end

-- Returns true if all values or mapped values in the table are true, otherwise false.
function ICT:containsAllValues(t, op)
    return self:containsAllKeys(t, function(k) return op and op(t[k]) or not op and t[k] end)
end

-- Returns true if any key or mapped value in the table are true, otherwise false.
function ICT:containsAnyKey(t, op)
    for k, _ in pairs(t) do
        if op and op(k) or not op and k then
            return true
        end
    end
    return false
end

-- Returns true if any value or mapped value in the table are true, otherwise false.
function ICT:containsAnyValue(t, op)
    return self:containsAnyKey(t, function(k) return op and op(t[k]) or not op and t[k] end)
end

-- Convenience to add to a table if it's not already there. Ended up not using.
function ICT:putIfAbsent(t, key, value)
    if not t[key] then
        t[key] = value
    end
end

-- Helper function when debugging.
function ICT:printKeys(t)
    for k, _ in pairs(t) do
        print(k)
    end
end

function ICT:DisplayTime(time)
    if not time then
        return ""
    end
    local days = math.floor(time / 86400)
    local hours = math.floor(time % 86400 / 3600)
    local minutes = math.floor(time % 3600 / 60)
    local seconds = math.floor(time % 60)
    return string.format("%d:%02d:%02d:%02d", days, hours, minutes, seconds)
end