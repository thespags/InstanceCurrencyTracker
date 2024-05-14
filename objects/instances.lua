local _, ICT = ...

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
-- Checks if the last boss in the instance is killed, using the number of encounters as the last boss index.
local isLastBossKilled = function(instance)
    local index = instance.info:getLastBossIndex()
    return instance:isEncounterKilled(index)
end

local dungeonEmblems = ICT:set(ICT.JusticePoints, ICT.SiderealEssence, ICT.DefilersScourgeStone)
local totcEmblems = ICT:set(ICT.JusticePoints, ICT.SiderealEssence, ICT.DefilersScourgeStone, ICT.ChampionsSeal)
local availableDungeonEmblems = function(instance, currency)
    if currency == ICT.JusticePoints then
        return 16
    elseif currency == ICT.SiderealEssence then
        return isLastBossKilled(instance) and 0 or 1
    elseif currency == ICT.ChampionsSeal then
        return sameEmblemsPerBoss(1)(instance)
    elseif currency == ICT.DefilersScourgeStone then
        return sameEmblemsPerBoss(2)(instance)
    end
end
local maxDungeonEmblems = function(instance, currency)
    if currency == ICT.JusticePoints then
        return 16
    elseif currency == ICT.SiderealEssence then
        return 1
    elseif currency == ICT.ChampionsSeal then
        return instance:numOfEncounters()
    elseif currency == ICT.DefilersScourgeStone then
        return instance:numOfEncounters() * 2
    end
end

local CATA_DUNGEON =  { currencies = ICT:set(ICT.JusticePoints), availableCurrency = sameEmblemsPerBoss(70), maxCurrency = maxSameEmblemsPerBoss(70) }
local WOTLK_RAID = { currencies = ICT:set(ICT.JusticePoints), availableCurrency = sameEmblemsPerBoss(24), maxCurrency = maxSameEmblemsPerBoss(24) }
local WOTLK_DUNGEON = { currencies = dungeonEmblems, availableCurrency = availableDungeonEmblems, maxCurrency = maxDungeonEmblems }
local WOTLK_TOTC = { currencies = totcEmblems, availableCurrency = availableDungeonEmblems, maxCurrency = maxDungeonEmblems }

function Instances.getCurrencyInfo(instance)
    if instance.expansion == ICT.Cata then
        return CATA_DUNGEON
    elseif instance.expansion == ICT.WOTLK then
        if instance:isRaid() then
            return WOTLK_RAID
        elseif instance.id == 650 then
            return WOTLK_TOTC
        else
            return WOTLK_DUNGEON
        end
    end
    return nil
end

function Instances.inExpansion(info, size)
    return Expansion.active(info:getExpansion(size))
end

-- Attaches the localize name to info for sorting in the options menu.
local infos
function Instances.infos()
    if infos then
        return infos
    end
    infos = {}
    for _, info in pairs(LibInstances:GetInfos()) do
        local size = info:getSizes()[1]
        if size then
            if Instances.inExpansion(info, size) then
                local instance = Instance:new({}, info, size)
                -- Drop size from name.
                instance.name = GetRealZoneText(info.id)
                tinsert(infos, instance)
            end

            local legacySize = info:getLegacySize()
            if legacySize and Instances.inExpansion(info, legacySize) then
                local instance = Instance:new({}, info, legacySize)
                instance.name = GetRealZoneText(info.id)
                tinsert(infos, instance)
            end
        end
    end
    return infos
end