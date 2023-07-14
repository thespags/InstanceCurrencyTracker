Utils = {}
-- Currency Id's with name helpers.
Utils.Heroism = 101
Utils.Valor = 102
Utils.Conquest = 221
Utils.Triumph = 301
Utils.SiderealEssence = 2589
Utils.ChampionsSeal = 241

function Utils:ToRaidName(name, size)
    return string.format("%s (%s)", name, size)
end

function Utils:GetFullName()
    return string.format("[%s] %s", UnitName("Player"), GetRealmName())
end

-- Returns the amount field of the currency provided.
function Utils:GetCurrency(id)
    return select(2, GetCurrencyInfo(id))
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

-- Filtered pairs iterator determined bythe table value with the given function.
function Utils:fpairs(t, f)
    -- collect the keys
    local keys = {}

    for k, v in pairs(t) do
        if f(v) then
            table.insert(keys, k)
        end
    end

    -- return the iterator function
    local i = 0
    return function()
        i = i + 1
        return keys[i], t[keys[i]]
    end
end

-- Sums a list by the values or a function mapping the values to a number.
function Utils:sum(t, f)
    local total = 0
    for k, v in pairs(t) do
        total = total + (f and f(v) or v)
    end
    return total
end
