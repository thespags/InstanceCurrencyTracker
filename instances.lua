Instances = {}

local numEncounters = function(instance)
    return InstanceInfo[instance.id].numEncounters
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

local onePerBossPlusOneLastBoss = Utils:add(sameEmblemsPerBoss(1), addOneLastBossAlive)

-- Ulduar has different amounts per boss
-- FL(4)/Ignis(1)/Razorscale(1)/XT(2)/IC(2)/Kolo(1)/Auriaya(1)/Thorim(2)/Hodir(2)/Freya(5)/Mim(2)/Vezak(2)/Yogg(2)/Alg(2)
local ulduarEmblemsPerBoss = { 4, 1, 1, 2, 2, 1, 1, 2, 2, 5, 2, 2, 2, 2 }
-- Ulduar has a maximum number of emblems of 29
Instances.MaxUlduarEmblems = Utils:sum(ulduarEmblemsPerBoss)
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
    [Utils.Valor] = 1,
    [Utils.Conquest] = 2,
    [Utils.Triumph] = 3,
}
local voaEmblems = function(instance, tokenId)
    return isBossKilled(instance, voaIndex[tokenId]) and 0 or 2
end

local maxEmblemsPerSize = function(emblemsPer10, emblemsPer25)
    return function(instance)
        return (instance.maxPlayers == 10 and emblemsPer10 or emblemsPer25) * numEncounters(instance)
    end
end

local dungeonEmblems = Utils:set(Utils.DungeonEmblem, Utils.SiderealEssence)
local totcEmblems = Utils:set(Utils.DungeonEmblem, Utils.SiderealEssence, Utils.ChampionsSeal)
local availableDungeonEmblems = function(instance, tokenID)
    if tokenID == Utils.SiderealEssence then
        return isLastBossKilled(instance) and 0 or 1
    elseif tokenID == Utils.DungeonEmblem or tokenID == Utils.ChampionsSeal then
        return sameEmblemsPerBoss(1)(instance)
    end
end
local maxDungeonEmblems = function(instance, tokenID)
    if tokenID == Utils.SiderealEssence then
        return 1
    elseif tokenID == Utils.DungeonEmblem or tokenID == Utils.ChampionsSeal then
        return numEncounters(instance)
    end
end

local maxNumEncountersPlusOne = function(instance) return numEncounters(instance) + 1 end

-- Static information about each instance.
--
-- Notes on key names: There's no clear API on getting the canonical name, and later instances are divided by 10 and 25 lockouts.
-- We could overload the id and max player for some formula, such as concatenating the two.
-- For readability of tables we will use English names instead of ids.
InstanceInfo = {
    [574] = { name = "Utgarde Keep", numEncounters = 3, tokenIds = dungeonEmblems, emblems = availableDungeonEmblems, maxEmblems = maxDungeonEmblems },
    [575] = { name = "Utgarde Pinnacle", numEncounters = 4, tokenIds = dungeonEmblems, emblems = availableDungeonEmblems, maxEmblems = maxDungeonEmblems },
    [595] = { name = "The Culling of Stratholme", numEncounters = 5, tokenIds = dungeonEmblems, emblems = availableDungeonEmblems, maxEmblems = maxDungeonEmblems },
    [600] = { name = "Drak'Tharon Keep", numEncounters = 4, tokenIds = dungeonEmblems, emblems = availableDungeonEmblems, maxEmblems = maxDungeonEmblems },
    [604] = { name = "Gundrak", numEncounters = 5, tokenIds = dungeonEmblems, emblems = availableDungeonEmblems, maxEmblems = maxDungeonEmblems },
    [576] = { name = "The Nexus", numEncounters = 5, tokenIds = dungeonEmblems, emblems = availableDungeonEmblems, maxEmblems = maxDungeonEmblems },
    [578] = { name = "The Oculus", numEncounters = 4, tokenIds = dungeonEmblems, emblems = availableDungeonEmblems, maxEmblems = maxDungeonEmblems },
    [608] = { name = "Violet Hold", numEncounters = 3, tokenIds = dungeonEmblems, emblems = availableDungeonEmblems, maxEmblems = maxDungeonEmblems },
    [602] = { name = "Halls of Lightning", numEncounters = 4, tokenIds = dungeonEmblems, emblems = availableDungeonEmblems, maxEmblems = maxDungeonEmblems },
    [599] = { name = "Halls of Stone", numEncounters = 4, tokenIds = dungeonEmblems, emblems = availableDungeonEmblems, maxEmblems = maxDungeonEmblems },
    [601] = { name = "Azjol-Nerub", numEncounters = 3, tokenIds = dungeonEmblems, emblems = availableDungeonEmblems, maxEmblems = maxDungeonEmblems },
    [619] = { name = "Ahn'kahet: The Old Kingdom", numEncounters = 5, tokenIds = dungeonEmblems, emblems = availableDungeonEmblems, maxEmblems = maxDungeonEmblems },
    [650] = { name = "Trial of the Champion", numEncounters = 3, tokenIds = totcEmblems, emblems = availableDungeonEmblems, maxEmblems = maxDungeonEmblems },
    [624] = { name = "Vault of Archavon", numEncounters = 3, tokenIds = Utils:set(Utils.Triumph, Utils.Conquest, Utils.Valor), emblems = voaEmblems, maxEmblems = ReturnX(2) },
    [533] = { name = "Naxxramas", numEncounters = 15, tokenIds = Utils:set(Utils.Valor), emblems = onePerBossPlusOneLastBoss, maxEmblems = maxNumEncountersPlusOne },
    [615] = { name = "The Obsidian Sanctum", numEncounters = 4, tokenIds = Utils:set(Utils.Valor), emblems = onePerBossPlusOneLastBoss, maxEmblems = maxNumEncountersPlusOne },
    [616] = { name = "The Eye of Eternity", numEncounters = 1, tokenIds = Utils:set(Utils.Valor), emblems = onePerBossPlusOneLastBoss, maxEmblems = maxNumEncountersPlusOne },
    [603] = { name = "Ulduar", numEncounters = 14, tokenIds = Utils:set(Utils.Conquest), emblems = ulduarEmblems, maxEmblems = ReturnX(Instances.MaxUlduarEmblems) },
    [249] = { name = "Onyxia's Lair", numEncounters = 1, tokenIds = Utils:set(Utils.Triumph), emblems = sameEmblemsPerBossPerSize(4, 5), maxEmblems = maxEmblemsPerSize(4, 5) },
    [649] = { name = "Trial of the Crusader", numEncounters = 5, tokenIds = Utils:set(Utils.Triumph), emblems = sameEmblemsPerBossPerSize(4, 5), maxEmblems = maxEmblemsPerSize(4, 5) },
    [409] = { name = "Molten Core", numEncounters = 10 },
    [309] = { name = "Zul'Gurub", numEncounters = 10},
    [469] = { name = "Blackwing Lair", numEncounters = 8 },
    [509] = { name = "Ruins of Ahn'Qiraj", numEncounters = 6 },
    [531] = { name = "Temple of Ahn'Qiraj", numEncounters = 9 },
    [532] = { name = "Karazhan", numEncounters = 11 },
    [565] = { name = "Gruul's Lair", numEncounters = 2 },
    [544] = { name = "Magtheridon's Lair", numEncounters = 1 },
    [548] = { name = "Serpentshrine Cavern", numEncounters = 6 },
    [550] = { name = "Tempest Keep", numEncounters = 4 },
    [564] = { name = "Black Temple", numEncounters = 9 },
    [534] = { name = "Hyjal Summit", numEncounters = 5 },
    [580] = { name = "Sunwell Plateau", numEncounters = 6 },
}
Instances.dungeons = {
    ["Utgarde Keep"] = { id = 574 },
    ["Utgarde Pinnacle"] = { id = 575 },
    ["The Culling of Stratholme"] = { id = 595 },
    ["Drak'Tharon Keep"] = { id = 600 },
    ["Gundrak"] = { id = 604 },
    ["The Nexus"] = { id = 576 },
    ["The Oculus"] = { id = 578 },
    ["Violet Hold"] = { id = 608 },
    ["Halls of Lightning"] = { id = 602 },
    ["Halls of Stone"] = { id = 599 },
    ["Azjol-Nerub"] = { id = 601 },
    ["Ahn'kahet: The Old Kingdom"] = { id = 619 },
    ["Trial of the Champion"] = { id = 650 },
    --["Pit of Saron"] = { id = ?, numEncounters = 3 },
    --["The Forge of Souls"] = { id = ?, numEncounters = 3 },
    --["Halls of Reflection"] = { id = ?, numEncounters = 3 }
}
Instances.raids = {
    ["Vault of Archavon (10)"] = { id = 624, maxPlayers = 10 },
    ["Vault of Archavon (25)"] = { id = 624, maxPlayers = 25 },
    ["Naxxramas (10)"] = { id = 533, maxPlayers = 10 },
    ["Naxxramas (25)"] = { id = 533, maxPlayers = 25 },
    ["The Obsidian Sanctum (10)"] = { id = 615, maxPlayers = 10 },
    ["The Obsidian Sanctum (25)"] = { id = 615, maxPlayers = 25 },
    ["The Eye of Eternity (10)"] = { id = 616, maxPlayers = 10 },
    ["The Eye of Eternity (25)"] = { id = 616, maxPlayers = 25 },
    ["Ulduar (10)"] = { id = 603, maxPlayers = 10 },
    ["Ulduar (25)"] = { id = 603, maxPlayers = 25 },
    ["Onyxia's Lair (10)"] = { id = 249, maxPlayers = 10 },
    ["Onyxia's Lair (25)"] = { id = 249, maxPlayers = 25 },
    ["Trial of the Crusader (10)"] = { id = 649, maxPlayers = 10 },
    ["Trial of the Crusader (25)"] = { id = 649, maxPlayers = 25 },
}
Instances.oldRaids = {
    ["Molten Core"] = { id = 409, expansion = "Vanilla" },
    ["Blackwing Lair"] = { id = 469, expansion = "Vanilla" },
    ["Zul'Gurub"] = { id = 309, expansion = "Vanilla" },
    ["Ruins of Ahn'Qiraj"] = { id = 509, expansion = "Vanilla" },
    ["Temple of Ahn'Qiraj"] = { id = 531, expansion = "Vanilla" },
    ["Karazhan"] = { id = 532, expansion = "Burning Crusade" },
    ["Gruul's Lair"] = { id = 565, expansion = "Burning Crusade"  },
    ["Magtheridon's Lair"] = { id = 544, expansion = "Burning Crusade" },
    ["Serpentshrine Cavern"] = { id = 548, expansion = "Burning Crusade" },
    ["Tempest Keep"] = { id = 550, expansion = "Burning Crusade" },
    ["Black Temple"] = { id = 564, expansion = "Burning Crusade" },
    ["Hyjal Summit"] = { id = 534, expansion = "Burning Crusade" },
    ["Sunwell Plateau"] = { id = 580, expansion = "Burning Crusade" },
}
-- How to order expansions, we sort from highest to lowest (reverse) so adding new currencies is easier.
Expansions = {
    ["Vanilla"] = 1,
    ["Burning Crusade"] = 2,
}
function ExpansionSort(a, b)
    return Expansions[a] > Expansions[b]
end

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
            local name = InstanceInfo[instanceId].name
            self:Lock(player.dungeons[name], reset, encounterProgress, i)
            local raidName = name and Utils:GetInstanceName(name, maxPlayers)
            self:Lock(player.raids[raidName], reset, encounterProgress, i)
            self:Lock(player.oldRaids[name], reset, encounterProgress, i)
        end
    end
end

function InstanceSort(a, b)
    return a.name < b.name
end