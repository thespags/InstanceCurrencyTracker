local addOnName, ICT = ...

local LibInstances = LibStub("LibInstances")
local Instance = ICT.Instance
local Instances = {}
ICT.Instances = Instances

local sameEmblemsPerBoss = function(emblemsPerEncounter)
    return function(instance)
        return emblemsPerEncounter * instance:encountersLeft()
    end
end
local maxSameEmblemsPerBoss = function(emblemsPerEncounter)
    return function(instance)
        return emblemsPerEncounter * instance:numOfEncounters()
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

-- Old Phase 1 Raids.
-- local onePerBossPlusOneLastBoss = ICT:add(sameEmblemsPerBoss(1), addOneLastBossAlive)
-- local maxNumEncountersPlusOne = function(instance) return instance:numOfEncounters() + 1 end

-- Ulduar has different amounts per boss
-- FL(4)/Ignis(1)/Razorscale(1)/XT(2)/IC(2)/Kolo(1)/Auriaya(1)/Thorim(2)/Hodir(2)/Freya(5)/Mim(2)/Vezak(2)/Yogg(2)/Alg(2)
local ulduarEmblemsPerBoss = { 4, 1, 1, 2, 2, 1, 1, 2, 2, 5, 2, 2, 2, 2 }
-- Ulduar has a maximum number of emblems of 29
local maxUlduarEmblems = ICT:sum(ulduarEmblemsPerBoss)
local ulduarEmblems = function(instance)
    local emblems = maxUlduarEmblems
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
    [ICT.Frost] = 4,
}
local voaEmblems = function(instance, currency)
    return instance:isEncounterKilled(voaIndex[currency]) and 0 or 2
end

local maxEmblemsPerSize = function(emblemsPer10, emblemsPer25)
    return function(instance)
        return (instance.size == 10 and emblemsPer10 or instance.size == 25 and emblemsPer25 or 0) * instance:numOfEncounters()
    end
end

local dungeonEmblems = ICT:set(ICT.StoneKeepersShard, ICT.DungeonEmblem, ICT.SiderealEssence, ICT.DefilersScourgeStone)
local totcEmblems = ICT:set(ICT.StoneKeepersShard, ICT.DungeonEmblem, ICT.SiderealEssence, ICT.DefilersScourgeStone, ICT.ChampionsSeal)
local availableDungeonEmblems = function(instance, currency)
    if currency == ICT.SiderealEssence then
        return isLastBossKilled(instance) and 0 or 1
    elseif currency == ICT.DungeonEmblem or currency == ICT.ChampionsSeal then
        return sameEmblemsPerBoss(1)(instance)
    elseif currency == ICT.DefilersScourgeStone then
        local total = sameEmblemsPerBoss(1)(instance)
        if instance.id == 578 then
            total = total + (isLastBossKilled(instance) and 0 or 2)
        end
        return total
    end
end
local maxDungeonEmblems = function(instance, currency)
    if currency == ICT.SiderealEssence then
        return 1
    elseif currency == ICT.StoneKeepersShard then
        return instance:numOfEncounters() * 4
    elseif currency == ICT.ChampionsSeal or currency == ICT.DungeonEmblem then
        return instance:numOfEncounters()
    elseif currency == ICT.DefilersScourgeStone then
        local total = instance:numOfEncounters()
        if instance.id == 578 then
            total = total + 2
        end
        return total
    end
end

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
    -- The Forge of Souls
    [632] = { currencies = dungeonEmblems, availableCurrency = availableDungeonEmblems, maxCurrency = maxDungeonEmblems },
    -- Pit of Saron
    [658] = { currencies = dungeonEmblems, availableCurrency = availableDungeonEmblems, maxCurrency = maxDungeonEmblems },
    -- Halls of Reflection
    [668] = { currencies = dungeonEmblems, availableCurrency = availableDungeonEmblems, maxCurrency = maxDungeonEmblems },
    -- Vault of Archavon
    [624] = { currencies = ICT:set(ICT.Frost, ICT.Triumph, ICT.Conquest, ICT.Valor), availableCurrency = voaEmblems, maxCurrency = ICT:returnX(2) },
    -- Naxxramas
    -- [533] = { currencies = ICT:set(ICT.Valor), availableCurrency = onePerBossPlusOneLastBoss, maxCurrency = maxNumEncountersPlusOne },
    [533] = { currencies = ICT:set(ICT.Triumph), availableCurrency = sameEmblemsPerBoss(1), maxCurrency = maxSameEmblemsPerBoss(1) },
    -- The Obsidian Sanctum
    -- [615] = { currencies = ICT:set(ICT.Valor), availableCurrency = onePerBossPlusOneLastBoss, maxCurrency = maxNumEncountersPlusOne },
    [615] = { currencies = ICT:set(ICT.Triumph), availableCurrency = sameEmblemsPerBoss(1), maxCurrency = maxSameEmblemsPerBoss(1) },
    -- The Eye of Eternity
    -- [616] = { currencies = ICT:set(ICT.Valor), availableCurrency = onePerBossPlusOneLastBoss, maxCurrency = maxNumEncountersPlusOne },
    [616] = { currencies = ICT:set(ICT.Triumph), availableCurrency = sameEmblemsPerBoss(1), maxCurrency = maxSameEmblemsPerBoss(1) },
    -- Ulduar
    -- [603] = { currencies = ICT:set(ICT.Conquest), availableCurrency = ulduarEmblems, maxCurrency = ICT:returnX(maxUlduarEmblems) },
    [603] = { currencies = ICT:set(ICT.Triumph), availableCurrency = sameEmblemsPerBoss(1), maxCurrency = maxSameEmblemsPerBoss(1) },
    -- Onyxia's Lair
    -- [249] = { currencies = ICT:set(ICT.Triumph), availableCurrency = sameEmblemsPerBossPerSize(4, 5), maxCurrency = maxEmblemsPerSize(4, 5) },
    [249] = { currencies = ICT:set(ICT.Triumph), availableCurrency = sameEmblemsPerBossPerSize(3, 3), maxCurrency = maxEmblemsPerSize(3, 3) },
    -- Trial of the Crusader
    [649] = { currencies = ICT:set(ICT.Triumph), availableCurrency = sameEmblemsPerBossPerSize(8, 10), maxCurrency = maxEmblemsPerSize(8, 10) },
    -- Icecrown Citadel
    [631] = { currencies = ICT:set(ICT.Frost), availableCurrency = sameEmblemsPerBossPerSize(2, 2), maxCurrency = maxEmblemsPerSize(2, 2) },
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
            local info = Instance:new({}, instance.id, size)
            -- Drop size from name.
            info.name = GetRealZoneText(instance.id)
            tinsert(infos, info)

            local legacySize = instance:getLegacySize()
            if legacySize then
                info = Instance:new({}, instance.id, legacySize)
                info.name = GetRealZoneText(instance.id)
                tinsert(infos, info)
            end
        end
    end
    return infos
end