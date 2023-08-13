local addOn, ICT = ...

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

function ICT:GetInstanceName(name, size)
    return string.format("%s (%s)", name, size)
end

function ICT:LocalizeInstanceName(v)
    local name = GetRealZoneText(v.id)
    v.name = v.maxPlayers and string.format("%s (%s)", name, v.maxPlayers) or name
end

function ICT.itemLinkSplit(itemLink)
    if not itemLink then
        return {}
    end
    local itemString = string.match(itemLink, "item:([%-?%d:]+)")
    local t = {}
    local i = 0
    for v in string.gmatch(itemString, "(%d*):?") do
        i = i + 1
        t[i] =  v ~= "" and v or nil
    end
    return t
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

-- Sorted pairs iterator determined by mapping the values.
function ICT:spairsByValue(t, comparator, filter)
    return self:spairs(t, function(a, b) return comparator(t[a], t[b]) end, filter and function(k) return filter(t[k]) end)
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

function ICT:sumNonNil(...)
    local count = 0
    for _, v in pairs({...}) do
        count = count + (v and 1 or 0)
    end
    return count
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

function ICT:add(left, right)
    return function(v) return left(v) + right(v) end
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

-- Returns true if all values or mapped values in the table are true, otherwise false.
function ICT:containsAllValues(t, op)
    for _, v in pairs(t) do
        if op and not op(v) or not op and not v then
            return false
        end
    end
    return true
end

-- Returns true if any value or mapped value in the table are true, otherwise false.
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
    for k, v in pairs(t) do
        print(string.format("%s %s", k, tostring(v)))
    end
end

function ICT.dprint(text)
    if false then
        print(text)
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

local throttle = true;
ICT.throttles = {};
function ICT:throttleFunction(source, time, f, callback)
    return function()
        -- Skip calling if the database/addon isn't initialized.
        -- We handle this via "onLoad".
        ICT.dprint(source)
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

function ICT.NaturalSort(a, b)
    return a < b
end