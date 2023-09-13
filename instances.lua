local addOnName, ICT = ...

local LibInstances = LibStub("LibInstances")
ICT.Instances = {}
local Instances = ICT.Instances

function Instances:new(instance, id, size)
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

function Instances:key(v, size)
    return string.format("%s (%s)", v, size)
end

function Instances:getName()
    return self.name
end

function Instances:localizeName()
    local name = GetRealZoneText(self.id)
    local sizes = ICT:size(self.info:getSizes())
    self.name = sizes > 1 and self:key(name, self.size) or name
end

-- Lock the specified instance with the provided information.
function Instances:lock(reset, encounterProgress, i)
    self.locked = true
    self.reset = reset + GetServerTime()
    self.encounterProgress = encounterProgress
    self.instanceIndex = i
    self.encounterKilled = self.info:getEncountersKilledByIndex(self.instanceIndex)
end

-- Reset if the reset timer has elapsed or no reset
function Instances:resetIfNecessary(timestamp)
    if not self.reset or (timestamp and self.reset < timestamp) then
        self.locked = false
        self.reset = nil
        self.encounterProgress = 0
        self.encounterKilled = {}
        self.instanceIndex = 0
        self.available = {}
    end
end

function Instances:resetInterval()
    return self.info:getResetInterval(self.size)
end

function Instances:activityId(difficulty)
    -- Use the provided difficulty or default to the highest. 
    difficulty = self:isDungeon() and (difficulty or #ICT.DifficultyInfo) or #ICT.RaidDifficulty
    -- Finds the type of activity, beta rune or raid 10 id, for an instance.
    return self.info:getActivityId(self.size, difficulty)
end

-- Is any difficulty of this instance queued?
function Instances:queued()
    local info = C_LFGList.GetActiveEntryInfo()
    local queuedIds = info and info.activityIDs or {}
    return #queuedIds > 0 and ICT:containsAnyValue(self:difficulties(), function(v) return tContains(queuedIds, self:activityId(v.id)) end)
end

function Instances:difficulties()
    return self:isDungeon() and ICT.DifficultyInfo or ICT.RaidDifficulty
end

function Instances:enqueue(queuedIds, includeLocked, shouldMessage)
    local queueCategory = queuedIds[1] and C_LFGList.GetActivityInfoTable(queuedIds[1]).categoryID
    local instanceCategory = C_LFGList.GetActivityInfoTable(self:activityId()).categoryID

    if queueCategory and queueCategory ~= instanceCategory then
        ICT:oprint("Ignoring %s, as Blizzard doesn't let you queue raids and dungeons together.", "lfg", self:getName())
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
                print("searching")
                LFGBrowseActivityDropDown_ValueSetSelected(LFGBrowseFrame.ActivityDropDown, activityId, not (remove or ignore));
            end
            f(queuedIds, activityId)
            -- Response back to the user to see what was queued/dequeued.
            if shouldMessage and not ignore then
                local message = remove and "Dequeuing %s" or "Enqueuing %s"
                local name = self:getName() .. (self:isDungeon() and ", " .. difficulty:getName() or "")
                ICT:oprint(message, "lfg", name)
            end
        end
    end
end

function Instances:numOfEncounters()
    return self.encounterSize
end

function Instances:encounters()
    return self.info:getEncounters()
end

function Instances:encountersLeft()
    return self:numOfEncounters() - self.encounterProgress
end

function Instances:isEncounterKilled(index)
    return self.encounterKilled and self.encounterKilled[index] or false
end

function Instances:hasCurrency(currency)
    local info = self.currency[self.id]
    return info and info.currencies[currency] or false
end

function Instances:currencies()
    local info = self.currency[self.id]
    return info and info.currencies or {}
end

function Instances:availableCurrency(currency)
    local info = self.currency[self.id]
    return info and info.availableCurrency(self, currency) or 0
end

function Instances:maxCurrency(currency)
    local info = self.currency[self.id]
    return info and info.maxCurrency(self, currency) or 0
end

function Instances:fromExpansion(expansion)
    return self.expansion == expansion
end

-- Is this instance a raid and if provided, a raid from the expansion?
function Instances:isRaid(expansion)
    return self.size > 5 and (not expansion or self:fromExpansion(expansion))
end

-- Is this instance a dungeon and if provided, a dungeon from the expansion?
function Instances:isDungeon(expansion)
    return self.size == 5 and (not expansion or self:fromExpansion(expansion))
end

function Instances:isVisible()
    return ICT.db.options.displayInstances[self.expansion][self.id]
end

function Instances:setVisible(v)
    ICT.db.options.displayInstances[self.expansion][self.id] = v
end

-- This comparison groups instances with the same name together across multiple sizes.
-- This is intended for sorting with respect to dungeons and raids separately.
function Instances:__lt(other)
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

-- Start currency helpers
local sameEmblemsPerBoss = function(emblemsPerEncounter)
    return function(instance)
        return emblemsPerEncounter * instance:encountersLeft()
    end
end

local sameEmblemsPerBossPerSize = function(emblems10, emblems25)
    return function(instance)
        return (instance.size == 10 and emblems10 or instance.size == 25 and emblems25 or 0) * instance:encountersLeft()
    end
end

-- Checks if the last boss in the instance is killed, using the number of encounters as the last boss index.
local isLastBossKilled = function(instance)
    local index = instance.info:getLastBossIndex()
    return instance:isEncounterKilled(index)
end

local addOneLastBossAlive = function(instance)
    return isLastBossKilled(instance) and 0 or 1
end

local onePerBossPlusOneLastBoss = ICT:add(sameEmblemsPerBoss(1), addOneLastBossAlive)

-- Ulduar has different amounts per boss
-- FL(4)/Ignis(1)/Razorscale(1)/XT(2)/IC(2)/Kolo(1)/Auriaya(1)/Thorim(2)/Hodir(2)/Freya(5)/Mim(2)/Vezak(2)/Yogg(2)/Alg(2)
local ulduarEmblemsPerBoss = { 4, 1, 1, 2, 2, 1, 1, 2, 2, 5, 2, 2, 2, 2 }
-- Ulduar has a maximum number of emblems of 29
Instances.MaxUlduarEmblems = ICT:sum(ulduarEmblemsPerBoss)
local ulduarEmblems = function(instance)
    local emblems = Instances.MaxUlduarEmblems
    if instance.instanceIndex > 0 then
        for i, ulduarEmblem in pairs(ulduarEmblemsPerBoss) do
            if instance:isEncounterKilled(i) then
                emblems = emblems - ulduarEmblem
            end
        end
    end
    return emblems
end

-- Vault of Archavon drops a different token per boss
local voaIndex = {
    [ICT.Valor] = 1,
    [ICT.Conquest] = 2,
    [ICT.Triumph] = 3,
}
local voaEmblems = function(instance, currency)
    return instance:isEncounterKilled(voaIndex[currency]) and 0 or 2
end

local maxEmblemsPerSize = function(emblemsPer10, emblemsPer25)
    return function(instance)
        return (instance.size == 10 and emblemsPer10 or instance.size == 25 and emblemsPer25 or 0) * instance:numOfEncounters()
    end
end

local dungeonEmblems = ICT:set(ICT.DungeonEmblem, ICT.SiderealEssence)
local totcEmblems = ICT:set(ICT.DungeonEmblem, ICT.SiderealEssence, ICT.ChampionsSeal)
local availableDungeonEmblems = function(instance, currency)
    if currency == ICT.SiderealEssence then
        return isLastBossKilled(instance) and 0 or 1
    elseif currency == ICT.DungeonEmblem or currency == ICT.ChampionsSeal then
        return sameEmblemsPerBoss(1)(instance)
    end
end
local maxDungeonEmblems = function(instance, currency)
    if currency == ICT.SiderealEssence then
        return 1
    elseif currency == ICT.DungeonEmblem or currency == ICT.ChampionsSeal then
        return instance:numOfEncounters()
    end
end

local maxNumEncountersPlusOne = function(instance) return instance:numOfEncounters() + 1 end

Instances.currency = {
    -- Utgarde Keep
    [574] = { currencies = dungeonEmblems, availableCurrency = availableDungeonEmblems, maxCurrency = maxDungeonEmblems },
    -- Utgarde Pinnacle
    [575] = { currencies = dungeonEmblems, availableCurrency = availableDungeonEmblems, maxCurrency = maxDungeonEmblems },
    -- The Culling of Stratholme
    [595] = { currencies = dungeonEmblems, availableCurrency = availableDungeonEmblems, maxCurrency = maxDungeonEmblems },
    -- Drak'Tharon Keep
    [600] = { currencies = dungeonEmblems, availableCurrency = availableDungeonEmblems, maxCurrency = maxDungeonEmblems },
    -- Gundrak
    [604] = { currencies = dungeonEmblems, availableCurrency = availableDungeonEmblems, maxCurrency = maxDungeonEmblems },
    -- The Nexus
    [576] = { currencies = dungeonEmblems, availableCurrency = availableDungeonEmblems, maxCurrency = maxDungeonEmblems },
    -- The Oculus
    [578] = { currencies = dungeonEmblems, availableCurrency = availableDungeonEmblems, maxCurrency = maxDungeonEmblems },
    -- Violet Hold
    [608] = { currencies = dungeonEmblems, availableCurrency = availableDungeonEmblems, maxCurrency = maxDungeonEmblems },
    -- Halls of Lightning
    [602] = { currencies = dungeonEmblems, availableCurrency = availableDungeonEmblems, maxCurrency = maxDungeonEmblems },
    -- Halls of Stone
    [599] = { currencies = dungeonEmblems, availableCurrency = availableDungeonEmblems, maxCurrency = maxDungeonEmblems },
    -- "Azjol-Nerub
    [601] = { currencies = dungeonEmblems, availableCurrency = availableDungeonEmblems, maxCurrency = maxDungeonEmblems },
    -- Ahn'kahet: The Old Kingdom
    [619] = { currencies = dungeonEmblems, availableCurrency = availableDungeonEmblems, maxCurrency = maxDungeonEmblems },
    -- Trial of the Champion"
    [650] = { currencies = totcEmblems, availableCurrency = availableDungeonEmblems, maxCurrency = maxDungeonEmblems },
    -- Vault of Archavon
    [624] = { currencies = ICT:set(ICT.Triumph, ICT.Conquest, ICT.Valor), availableCurrency = voaEmblems, maxCurrency = ICT:ReturnX(2) },
    -- Naxxramas
    [533] = { currencies = ICT:set(ICT.Valor), availableCurrency = onePerBossPlusOneLastBoss, maxCurrency = maxNumEncountersPlusOne },
    -- The Obsidian Sanctum
    [615] = { currencies = ICT:set(ICT.Valor), availableCurrency = onePerBossPlusOneLastBoss, maxCurrency = maxNumEncountersPlusOne },
    -- The Eye of Eternity
    [616] = { currencies = ICT:set(ICT.Valor), availableCurrency = onePerBossPlusOneLastBoss, maxCurrency = maxNumEncountersPlusOne },
    -- Ulduar
    [603] = { currencies = ICT:set(ICT.Conquest), availableCurrency = ulduarEmblems, maxCurrency = ICT:ReturnX(Instances.MaxUlduarEmblems) },
    -- Onyxia's Lair
    [249] = { currencies = ICT:set(ICT.Triumph), availableCurrency = sameEmblemsPerBossPerSize(4, 5), maxCurrency = maxEmblemsPerSize(4, 5) },
    -- Trial of the Crusader
    [649] = { currencies = ICT:set(ICT.Triumph), availableCurrency = sameEmblemsPerBossPerSize(4, 5), maxCurrency = maxEmblemsPerSize(4, 5) },
}
-- End Currency Helpers

ICT.WOTLK = 2
ICT.TBC = 1
ICT.VANILLA = 0
ICT.Expansions = {
    [ICT.WOTLK] = "Wrath of the Lich King",
    [ICT.TBC] = "The Burning Crusade",
    [ICT.VANILLA] = "Vanilla"
}

-- Attaches the localize name to info for sorting in the options menu.
local infos
function Instances.infos()
    if infos then
        return infos
    end
    infos = {}
    for _, instance in pairs(LibInstances:GetInfos()) do
        local size = instance:getSizes()[1]
        if size then
            local info = Instances:new({}, instance.id, size)
            -- Drop size from name.
            info.name = GetRealZoneText(instance.id)
            tinsert(infos, info)

            local legacySize = instance:getLegacySize()
            if legacySize then
                info = Instances:new({}, instance.id, legacySize)
                info.name = GetRealZoneText(instance.id)
                tinsert(infos, info)
            end
        end
    end
    return infos
end