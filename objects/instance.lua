local addOnName, ICT = ...

local LibInstances = LibStub("LibInstances")
local L = LibStub("AceLocale-3.0"):GetLocale("InstanceCurrencyTracker");
local Instance = {}
ICT.Instance = Instance

function Instance:new(instance, id, size)
    instance = instance or {}
    setmetatable(instance, self)
    self.__index = self
    instance.info = LibInstances:GetInfo(id)
    instance.id = id
    instance.size = size
    instance.expansion = instance.info:getExpansion(size)
    instance:localizeName()
    instance:resetIfNecessary()
    instance.encounterSize = #instance:encounters()
    return instance
end

function Instance:key(v, size)
    return string.format("%s (%s)", v, size)
end

function Instance:getName()
    return self.name
end

function Instance:localizeName()
    local name = GetRealZoneText(self.id)
    local sizes = ICT:size(self.info:getSizes())
    self.name = sizes > 1 and self:key(name, self.size) or name
end

-- Lock the specified instance with the provided information.
function Instance:lock(reset, encounterProgress, i)
    self.locked = true
    self.reset = reset + GetServerTime()
    self.encounterProgress = encounterProgress
    self.instanceIndex = i
    self.encounterKilled = self.info:getEncountersKilledByIndex(self.instanceIndex)
end

-- Reset if the reset timer has elapsed or no reset
function Instance:resetIfNecessary(timestamp)
    if not self.reset or (timestamp and self.reset < timestamp) then
        self.locked = false
        self.reset = nil
        self.encounterProgress = 0
        self.encounterKilled = {}
        self.instanceIndex = 0
        self.available = {}
    end
end

function Instance:resetInterval()
    return self.info:getResetInterval(self.size)
end

function Instance:activityId(difficulty)
    -- Use the provided difficulty or default to the highest. 
    difficulty = self:isDungeon() and (difficulty or #ICT.DifficultyInfo) or #ICT.RaidDifficulty
    -- Finds the type of activity, beta rune or raid 10 id, for an instance.
    return self.info:getActivityId(self.size, difficulty)
end

-- Is any difficulty of this instance queued?
function Instance:queued()
    local info = C_LFGList.GetActiveEntryInfo()
    local queuedIds = info and info.activityIDs or {}
    return #queuedIds > 0 and ICT:containsAnyValue(self:difficulties(), function(v) return tContains(queuedIds, self:activityId(v.id)) end)
end

function Instance:difficulties()
    return self:isDungeon() and ICT.DifficultyInfo or ICT.RaidDifficulty
end

function Instance:enqueue(queuedIds, includeLocked, shouldMessage)
    local queueCategory = queuedIds[1] and C_LFGList.GetActivityInfoTable(queuedIds[1]).categoryID
    local instanceCategory = C_LFGList.GetActivityInfoTable(self:activityId()).categoryID

    if queueCategory and queueCategory ~= instanceCategory then
        ICT:oprint(L["Ignoring %s, as Blizzard doesn't let you queue raids and dungeons together."], "lfg", self:getName())
        return
    end

    if not includeLocked and self.locked then
        return
    end

    for _, difficulty in pairs(self:difficulties()) do
        local activityId = self:activityId(difficulty.id)
        if activityId then
            local remove = tContains(queuedIds, activityId)
            local ignore = not difficulty:isVisible()
            local f = (remove or ignore) and tDeleteItem or table.insert
            -- Don't initiate a search if we weren't already searching. This seems to work but sometimes doesn't and I'm not sure why yet.
            if ICT.searching then
                LFGBrowseActivityDropDown_ValueSetSelected(LFGBrowseFrame.ActivityDropDown, activityId, not (remove or ignore));
            end
            f(queuedIds, activityId)
            -- Response back to the user to see what was queued/dequeued.
            if shouldMessage and not ignore then
                local message = remove and L["Dequeuing %s"] or L["Enqueuing %s"]
                local name = self:getName() .. (self:isDungeon() and ", " .. difficulty:getName() or "")
                ICT:oprint(message, "lfg", name)
            end
        end
    end
end

function Instance:numOfEncounters()
    return self.encounterSize
end

function Instance:encounters()
    return self.info:getEncounters()
end

function Instance:encountersLeft()
    return self:numOfEncounters() - self.encounterProgress
end

function Instance:isEncounterKilled(index)
    return self.encounterKilled and self.encounterKilled[index] or false
end

function Instance:hasCurrency(currency)
    local info = ICT.Instances.currency[self.id]
    return info and info.currencies[currency] or false
end

function Instance:currencies()
    local info = ICT.Instances.currency[self.id]
    return info and info.currencies or {}
end

function Instance:availableCurrency(currency)
    local info = ICT.Instances.currency[self.id]
    return info and info.availableCurrency(self, currency) or 0
end

function Instance:maxCurrency(currency)
    local info = ICT.Instances.currency[self.id]
    return info and info.maxCurrency(self, currency) or 0
end

function Instance:fromExpansion(expansion)
    return self.expansion == expansion
end

-- Is this instance a raid and if provided, a raid from the expansion?
function Instance:isRaid(expansion)
    return self.size > 5 and (not expansion or self:fromExpansion(expansion))
end

-- Is this instance a dungeon and if provided, a dungeon from the expansion?
function Instance:isDungeon(expansion)
    return self.size == 5 and (not expansion or self:fromExpansion(expansion))
end

function Instance:isVisible()
    return ICT.db.options.displayInstances[self.expansion][self.id]
end

function Instance:setVisible(v)
    ICT.db.options.displayInstances[self.expansion][self.id] = v
end

-- This comparison groups instances with the same name together across multiple sizes.
-- This is intended for sorting with respect to dungeons and raids separately.
function Instance:__lt(other)
    if ICT.db.options.frame.orderLockLast then
        if self.locked and not other.locked then
            return false
        end
        if not self.locked and other.locked then
            return true
        end
    end

    -- Later expansions appear earlier in our lists...
    if self.expansion == other.expansion then
        if self.name == other.name then
            return self.size < other.size
        end
        return self.name < other.name
    end
    return self.expansion > other.expansion
end

local function compare(a, b, aSize, bSize)
    aSize = aSize or a.size
    bSize = bSize or b.size

    if aSize == bSize then
        return a.name < b.name
    end
    return aSize < bSize
end

-- This comparison sorts by size before name.
-- This is intended for sorting with dungeons and raids togther.
function ICT.InstanceOptionSort(a, b)
    -- Later expansions appear earlier in our lists...
    if a.expansion == b.expansion then
        return compare(a, b)
    end
    return a.expansion > b.expansion
end