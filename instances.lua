local addOnName, ICT = ...

ICT.Instances = {}
local Instances = ICT.Instances

local numEncounters = function(instance)
    return ICT.InstanceInfo[instance.id].numEncounters
end

local sameEmblemsPerBoss = function(emblemsPerEncounter)
    return function(instance)
        return emblemsPerEncounter * (numEncounters(instance) - instance.encounterProgress)
    end
end

local sameEmblemsPerBossPerSize = function(emblems10, emblems25)
    return function(instance)
        return (instance.maxPlayers == 10 and emblems10 or emblems25) * (numEncounters(instance) - instance.encounterProgress)
    end
end

-- If we have an instance lock index then check if the boss is killed.
local isBossKilled = function(instance, bossIndex)
    return instance.instanceIndex > 0 and select(3, GetSavedInstanceEncounterInfo(instance.instanceIndex, bossIndex)) or false
end

-- Checks if the last boss in the instance is killed, using the number of encounters as the last boss index.
local isLastBossKilled = function(instance)
    return isBossKilled(instance, numEncounters(instance))
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
            if isBossKilled(instance, i) then
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
local voaEmblems = function(instance, tokenId)
    return isBossKilled(instance, voaIndex[tokenId]) and 0 or 2
end

local maxEmblemsPerSize = function(emblemsPer10, emblemsPer25)
    return function(instance)
        return (instance.maxPlayers == 10 and emblemsPer10 or emblemsPer25) * numEncounters(instance)
    end
end

local dungeonEmblems = ICT:set(ICT.DungeonEmblem, ICT.SiderealEssence)
local totcEmblems = ICT:set(ICT.DungeonEmblem, ICT.SiderealEssence, ICT.ChampionsSeal)
local availableDungeonEmblems = function(instance, tokenID)
    if tokenID == ICT.SiderealEssence then
        return isLastBossKilled(instance) and 0 or 1
    elseif tokenID == ICT.DungeonEmblem or tokenID == ICT.ChampionsSeal then
        return sameEmblemsPerBoss(1)(instance)
    end
end
local maxDungeonEmblems = function(instance, tokenID)
    if tokenID == ICT.SiderealEssence then
        return 1
    elseif tokenID == ICT.DungeonEmblem or tokenID == ICT.ChampionsSeal then
        return numEncounters(instance)
    end
end

local maxNumEncountersPlusOne = function(instance) return numEncounters(instance) + 1 end

-- Static information about each instance.
--
-- Notes on key names: There's no clear API on getting the canonical name, and later instances are divided by 10 and 25 lockouts.
-- We could overload the id and max player for some formula, such as concatenating the two.
-- For readability of tables we will use English names instead of ids.
ICT.InstanceInfo = {
    [574] = { name = "Utgarde Keep", expansion = 3, maxPlayers = {5}, numEncounters = 3, tokenIds = dungeonEmblems, emblems = availableDungeonEmblems, maxEmblems = maxDungeonEmblems },
    [575] = { name = "Utgarde Pinnacle", expansion = 3, maxPlayers = {5}, numEncounters = 4, tokenIds = dungeonEmblems, emblems = availableDungeonEmblems, maxEmblems = maxDungeonEmblems },
    [595] = { name = "The Culling of Stratholme", expansion = 3, maxPlayers = {5}, numEncounters = 5, tokenIds = dungeonEmblems, emblems = availableDungeonEmblems, maxEmblems = maxDungeonEmblems },
    [600] = { name = "Drak'Tharon Keep", expansion = 3, maxPlayers = {5}, numEncounters = 4, tokenIds = dungeonEmblems, emblems = availableDungeonEmblems, maxEmblems = maxDungeonEmblems },
    [604] = { name = "Gundrak", expansion = 3, maxPlayers = {5}, numEncounters = 5, tokenIds = dungeonEmblems, emblems = availableDungeonEmblems, maxEmblems = maxDungeonEmblems },
    [576] = { name = "The Nexus", expansion = 3, maxPlayers = {5}, numEncounters = 5, tokenIds = dungeonEmblems, emblems = availableDungeonEmblems, maxEmblems = maxDungeonEmblems },
    [578] = { name = "The Oculus", expansion = 3, maxPlayers = {5}, numEncounters = 4, tokenIds = dungeonEmblems, emblems = availableDungeonEmblems, maxEmblems = maxDungeonEmblems },
    [608] = { name = "Violet Hold", expansion = 3, maxPlayers = {5}, numEncounters = 3, tokenIds = dungeonEmblems, emblems = availableDungeonEmblems, maxEmblems = maxDungeonEmblems },
    [602] = { name = "Halls of Lightning", expansion = 3, maxPlayers = {5}, numEncounters = 4, tokenIds = dungeonEmblems, emblems = availableDungeonEmblems, maxEmblems = maxDungeonEmblems },
    [599] = { name = "Halls of Stone", expansion = 3, maxPlayers = {5}, numEncounters = 4, tokenIds = dungeonEmblems, emblems = availableDungeonEmblems, maxEmblems = maxDungeonEmblems },
    [601] = { name = "Azjol-Nerub", expansion = 3, maxPlayers = {5}, numEncounters = 3, tokenIds = dungeonEmblems, emblems = availableDungeonEmblems, maxEmblems = maxDungeonEmblems },
    [619] = { name = "Ahn'kahet: The Old Kingdom", expansion = 3, maxPlayers = {5}, numEncounters = 5, tokenIds = dungeonEmblems, emblems = availableDungeonEmblems, maxEmblems = maxDungeonEmblems },
    [650] = { name = "Trial of the Champion", expansion = 3, maxPlayers = {5}, numEncounters = 3, tokenIds = totcEmblems, emblems = availableDungeonEmblems, maxEmblems = maxDungeonEmblems },
    --["Pit of Saron"] = { id = ?, numEncounters = 3 },
    --["The Forge of Souls"] = { id = ?, numEncounters = 3 },
    --["Halls of Reflection"] = { id = ?, numEncounters = 3 }
    [624] = { name = "Vault of Archavon", expansion = 3, maxPlayers = {10, 25}, numEncounters = 3, tokenIds = ICT:set(ICT.Triumph, ICT.Conquest, ICT.Valor), emblems = voaEmblems, maxEmblems = ICT:ReturnX(2) },
    [533] = { name = "Naxxramas", expansion = 3, maxPlayers = {10, 25}, numEncounters = 15, tokenIds = ICT:set(ICT.Valor), emblems = onePerBossPlusOneLastBoss, maxEmblems = maxNumEncountersPlusOne },
    [615] = { name = "The Obsidian Sanctum", expansion = 3, maxPlayers = {10, 25}, numEncounters = 4, tokenIds = ICT:set(ICT.Valor), emblems = onePerBossPlusOneLastBoss, maxEmblems = maxNumEncountersPlusOne },
    [616] = { name = "The Eye of Eternity", expansion = 3, maxPlayers = {10, 25}, numEncounters = 1, tokenIds = ICT:set(ICT.Valor), emblems = onePerBossPlusOneLastBoss, maxEmblems = maxNumEncountersPlusOne },
    [603] = { name = "Ulduar", expansion = 3, numEncounters = 14, maxPlayers = {10, 25}, tokenIds = ICT:set(ICT.Conquest), emblems = ulduarEmblems, maxEmblems = ICT:ReturnX(Instances.MaxUlduarEmblems) },
    [249] = { name = "Onyxia's Lair", expansion = 3, numEncounters = 1, maxPlayers = {10, 25}, tokenIds = ICT:set(ICT.Triumph), emblems = sameEmblemsPerBossPerSize(4, 5), maxEmblems = maxEmblemsPerSize(4, 5) },
    [649] = { name = "Trial of the Crusader", expansion = 3, numEncounters = 5, maxPlayers = {10, 25}, tokenIds = ICT:set(ICT.Triumph), emblems = sameEmblemsPerBossPerSize(4, 5), maxEmblems = maxEmblemsPerSize(4, 5) },
    [532] = { name = "Karazhan", expansion = 2, maxPlayers = {10}, numEncounters = 11 },
    [565] = { name = "Gruul's Lair", expansion = 2, maxPlayers = {25}, numEncounters = 2 },
    [544] = { name = "Magtheridon's Lair", expansion = 2, maxPlayers = {25}, numEncounters = 1 },
    [548] = { name = "Serpentshrine Cavern", expansion = 2, maxPlayers = {25}, numEncounters = 6 },
    [550] = { name = "Tempest Keep", expansion = 2, maxPlayers = {25}, numEncounters = 4 },
    [564] = { name = "Black Temple", expansion = 2, maxPlayers = {25}, numEncounters = 9 },
    [534] = { name = "Hyjal Summit", expansion = 2, maxPlayers = {25}, numEncounters = 5 },
    [580] = { name = "Sunwell Plateau", expansion = 2, maxPlayers = {25}, numEncounters = 6 },
    [409] = { name = "Molten Core", expansion = 1, maxPlayers = {25}, numEncounters = 10 },
    [309] = { name = "Zul'Gurub", expansion = 1, maxPlayers = {25}, numEncounters = 10},
    [469] = { name = "Blackwing Lair", expansion = 1, maxPlayers = {25}, numEncounters = 8 },
    -- What is max size for aq20 and zg post classic?
    [509] = { name = "Ruins of Ahn'Qiraj", expansion = 1, maxPlayers = {25}, numEncounters = 6 },
    [531] = { name = "Temple of Ahn'Qiraj", expansion = 1, maxPlayers = {25}, numEncounters = 9 },
}
-- Redundant but hopefully simplifies filters and mappings.
for k, v in pairs(ICT.InstanceInfo) do
    v.id = k
end

-- How to order expansions, we sort from highest to lowest (reverse) so adding new currencies is easier.
ICT.WOTLK = "Wrath of the Lich King"
ICT.TBC = "The Burning Crusade"
ICT.VANILLA = "Vanilla"
ICT.Expansions = {
    [ICT.VANILLA] = 1,
    [ICT.TBC] = 2,
    [ICT.WOTLK] = 3
}

-- Force reset all saved instance information.
function Instances:ResetAll(instances)
    for _, instance in pairs(instances) do
        self:Reset(instance)
    end
end

-- Reset if the reset timer has elapsed.
function Instances:ResetIfNecessary(instances, timestamp)
    for _, instance in pairs(instances) do
        if instance.reset and instance.reset < timestamp then
            self:Reset(instance)
        end
    end
end

-- Reset saved instance information.
function Instances:Reset(instance)
    instance.locked = false
    instance.reset = nil
    instance.encounterProgress = 0
    instance.instanceIndex = 0
    instance.available = {}
end

-- Lock the specified instance with the provided information.
function Instances:Lock(instance, reset, encounterProgress, i)
    if instance then
        instance.locked = true
        instance.reset = reset
        instance.encounterProgress = encounterProgress
        instance.instanceIndex = i
    end
end

-- Get all saved instance information and lock the respective instance for the player.
function Instances:Update(player)
    local numSavedInstances = GetNumSavedInstances()
    for i=1, numSavedInstances do
        local _, _, reset, _, locked, _, _, _, maxPlayers, _, _, encounterProgress, _, instanceId = GetSavedInstanceInfo(i)

        if locked then
            local name = ICT.InstanceInfo[instanceId].name
            self:Lock(player.dungeons[name], reset, encounterProgress, i)
            local raidName = name and ICT:GetInstanceName(name, maxPlayers)
            self:Lock(player.raids[raidName], reset, encounterProgress, i)
            self:Lock(player.oldRaids[name], reset, encounterProgress, i)
        end
    end
end

function ICT.ExpansionSort(a, b)
    return ICT.Expansions[a] > ICT.Expansions[b]
end


function ICT.InstanceSort(a, b)
    return ICT.InstanceInfoSort(ICT.InstanceInfo[a.id], ICT.InstanceInfo[b.id], function() return a.name < b.name end)
end

function ICT.InstanceInfoSort(aInfo, bInfo, op)
    -- Later expansions appear earlier in our lists...
    if aInfo.expansion == bInfo.expansion then
        if aInfo.maxPlayers[1] == bInfo.maxPlayers[1] then
            op = op or function() return GetRealZoneText(aInfo.id) < GetRealZoneText(bInfo.id) end
            return op()
        end
        -- Dungeons appear before raids.
        return aInfo.maxPlayers[1] < bInfo.maxPlayers[1]
    end
    return aInfo.expansion > bInfo.expansion
end