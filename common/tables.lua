local addOn, ICT = ...

local noop = function() end

-- Sorted pairs iterator determined by the table key.
function ICT:spairs(t, comparator, filter)
    if t == nil then
        return noop
    end
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
    -- If comparator is nil use nspairsByValue but be safe
    comparator = comparator or function(a, b) return a < b end
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
    if t == nil then
        return noop
    end
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
    return self:fpairs(t, function(k) return not f or f(t[k]) end)
end

-- Returns true if all values or mapped values in the table are true, otherwise false.
---@generic V : any
---@param t table<any, V>
---@param op? fun(self: V): boolean
---@return boolean
function ICT:containsAllValues(t, op)
    for _, v in pairs(t or {}) do
        if op and not op(v) or not op and not v then
            return false
        end
    end
    return true
end

--- Returns true if any value or mapped value in the table are true, otherwise false.
---@generic V : any
---@param t table<any, V>
---@param op? fun(self: V): boolean
---@return boolean
function ICT:containsAnyValue(t, op)
    for _, v in pairs(t or {}) do
        if op and op(v) or not op and v then
            return true
        end
    end
    return false
end

-- Sums a list by the values or a function mapping the values to a number.
function ICT:sum(t, op, filter)
    local total = 0
    for _, v in pairs(t or {}) do
        if not filter or filter(v) then
            total = total + (op and op(v) or v)
        end
    end
    return total
end

function ICT:sumNonNil(t)
    return self:sum(t, function(v) return v and 1 or 0 end)
end

function ICT:size(t, filter)
    return self:sum(t, function(_) return 1 end, filter)
end

function ICT:max(t, op, filter)
    local max = nil
    for _, v in pairs(t or {}) do
        if not filter or filter(v) then
            local value = (op and op(v) or v)
            max = (not max or value > max) and value or max
        end
    end
    return max
end

function ICT:putIfAbsent(t, key, value)
    t[key] = t[key] == nil and value or t[key]
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
