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

function Utils:GetInstanceName(name, size)
    return string.format("%s (%s)", name, size)
end

function Utils:GetFullName()
    return string.format("[%s] %s", UnitName("Player"), GetRealmName())
end

-- Returns the amount of currency the player has for the currency provided.
function Utils:GetCurrencyAmount(id)
    return select(2, GetCurrencyInfo(id))
end

-- Returns the localized name of the currency provided.
function Utils:GetCurrencyName(id)
    return select(1, GetCurrencyInfo(id))
end

function Utils:GetLocalizedInstanceName(v)
    local name = GetRealZoneText(v.id)
    return v.maxPlayers and string.format("%s (%s)", name, v.maxPlayers) or name
end

-- Sorted pairs iterator determined by the table key.
function Utils:spairs(t)
    -- collect the keys
    local keys = {}
    for k in pairs(t) do keys[#keys+1] = k end

    table.sort(keys)

    -- return the iterator function
    local i = 0
    return function()
        i = i + 1
        if keys[i] then
            return keys[i], t[keys[i]]
        end
    end
end

-- Filtered pairs iterator determined by the table value with the given function.
function Utils:fpairs(t, f)
    local k, v
    return function()
        repeat
            k, v = next(t, k)
        until not k or f(v)
        return k, v
    end
end

function Utils:True()
    return true 
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

function Utils:returnX(x)
    return function() return x end
end

function Utils:set(...)
    local t = {}
    for _, v in pairs({...}) do
        t[v] = true
    end
    return t
end